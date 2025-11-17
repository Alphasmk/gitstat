from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from urllib.parse import urlparse
from asyncio import create_task, run
from aiohttp import ClientSession
import requests
import re
from сonfig import GITHUB_ACCESS_TOKEN as token
from tools.db_helper import DBHelper
from datetime import datetime

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

def convert_date(date: str) -> datetime:
    return datetime.fromisoformat(date.replace('Z', '+00:00'))

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
        count = 0
        if result.type == "profile":
            response = await async_http_get(f"https://api.github.com/users/{result.username}")
            count = DBHelper.is_was_request("is_was_profile_request", response['id'])
            print(response['id'])
        elif result.type == "repository":
            response = await async_http_get(f"https://api.github.com/repos/{result.username}/{result.repository}")
            count = DBHelper.is_was_request("is_was_repository_request", response['id'])
            print(response['id'])
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST)
        print(count)
        if count == 0:
            created_at = None
            updated_at = None
            
            if response.get('created_at'):
                created_at = convert_date(response['created_at'])
            if response.get('updated_at'):
                updated_at = convert_date(response['updated_at'])

            if result.type == "profile":
                with DBHelper.get_cursor() as cursor:
                    cursor.callproc("add_profile_to_history", [
                    response.get('id'),
                    response.get('login'),
                    response.get('avatar_url'),
                    response.get('html_url'),
                    response.get('type'),
                    response.get('name'),
                    response.get('company'),
                    response.get('location'),
                    response.get('email'),
                    response.get('blog'),
                    response.get('bio'),
                    response.get('twitter_username'),
                    response.get('followers'),
                    response.get('following'),
                    response.get('public_repos'),
                    created_at,
                    updated_at])
        else:
            updated_at = None
            if response.get('updated_at'):
                updated_at = convert_date(response['updated_at'])
            with DBHelper.get_cursor() as cursor:
                cursor.callproc("update_profile_history", [
                    response.get('id'),
                    response.get('login'),
                    response.get('avatar_url'),
                    response.get('html_url'),
                    response.get('type'),
                    response.get('name'),
                    response.get('company'),
                    response.get('location'),
                    response.get('email'),
                    response.get('blog'),
                    response.get('bio'),
                    response.get('twitter_username'),
                    response.get('followers'),
                    response.get('following'),
                    response.get('public_repos'),
                    updated_at])
        return response
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))