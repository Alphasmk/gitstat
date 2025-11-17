from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from urllib.parse import urlparse
from asyncio import create_task, run
from aiohttp import ClientSession
import requests
import re
from сonfig import GITHUB_ACCESS_TOKEN as token

router = APIRouter()

class UserInput(BaseModel):
    type: str
    username: str | None
    repository: str | None
    class Config:
        from_attributes = True

class RequestType(UserInput):
    pass

async def async_http_get(path: str):
    async with ClientSession() as session:
        response = await session.get(url=path, headers={"Authorization": f"Bearer {token}"})
        return await response.json()

def parse_user_input(stroke: str) -> UserInput:
    stroke = stroke.strip()
    if stroke.startswith("http://") or stroke.startswith("https://"):
        parsed = urlparse(stroke)

        if "github.com" not in parsed.netloc.lower():
            raise ValueError("Не ссылка на github")
        
        parts = [p for p in parsed.path.split("/") if p]

        if len(parts) == 1:
            return UserInput(type="profile", username=parts[0], repository=None)
        elif len(parts) >= 2:
            return UserInput(type="repository", username=parts[0], repository=parts[1])
        else: 
            raise ValueError("Некорректная ссылка на github")
    else:
        if re.match(r"^[A-Za-z0-9-]+$", stroke):
            return UserInput(type="profile", username=stroke, repository=None)
        else:
            raise ValueError("Некорректное имя пользователя")

@router.get('/git_info')
async def get_type_of_request(stroke: str):
    try:
        result = RequestType.model_validate(parse_user_input(stroke))
        if result.type == "profile":
            response = await async_http_get(f"https://api.github.com/users/{result.username}")
            return response
        elif result.type == "repository":
            response = await async_http_get(f"https://api.github.com/repos/{result.username}/{result.repository}")
            return response
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))