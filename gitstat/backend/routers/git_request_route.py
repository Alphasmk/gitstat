from fastapi import APIRouter, HTTPException, status, Request, Depends
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from urllib.parse import urlparse
import requests
import re
from tools.db_helper import DBHelper
from tools.http_helper import HTTPHelper
from .login_route import get_current_user

router = APIRouter()

class UserInput(BaseModel):
    type: str
    username: str | None
    repository: str | None
    class Config:
        from_attributes = True

class RequestType(UserInput):
    pass

def isint(stroke: str) -> bool:
    try:
        int(stroke)
        return True
    except:
        return False

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

async def get_github_response(result):
    if result.type == "profile":
        response = await HTTPHelper.async_http_get(f"https://api.github.com/users/{result.username}")
    elif result.type == "repository":
        response = await HTTPHelper.async_http_get(f"https://api.github.com/repos/{result.username}/{result.repository}")
    return response

def get_count_of_rows(proc: str, id: int):
    return DBHelper.is_was_request(proc, id)

@router.get('/git_info')
async def get_git_info(findby: str):
    try:
        if isint(findby):
            git_info = DBHelper.get_repository_by_id(int(findby))
            if git_info:
                git_info['response_type'] = 'Repository'
        else:
            git_info = DBHelper.execute_get("get_profile_by_name", findby)
            if git_info:
                git_info['response_type'] = 'Profile'
        return git_info
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post('/new_git_info', response_class=RedirectResponse)
async def renew_git_info(stroke: str, current_user = Depends(get_current_user)):
    try:
        result = RequestType.model_validate(parse_user_input(stroke))
        response = await get_github_response(result)
        if result.type == "profile":
            count = get_count_of_rows("is_was_profile_request", response['id'])
            if count == 0:
                DBHelper.add_profile_to_history(response)
            else:
                DBHelper.update_profile_history(response)
            with DBHelper.get_cursor() as cursor:
                    cursor.callproc("add_request_to_general_history", [
                        current_user.id,
                        None,
                        response.get('id'),
                        'PROFILE'
                    ])
            return RedirectResponse(url=f'/git_info?findby={result.username}', status_code=303)
        else:
            count = get_count_of_rows("is_was_repository_request", response['id'])
            print(count)
            if count == 0:
                await DBHelper.add_repository_to_history(response)
            else:
                await DBHelper.update_repository_history(response)
            with DBHelper.get_cursor() as cursor:
               cursor.callproc("add_request_to_general_history", [
               current_user.id,
               response.get('id'),
               None,
               'REPOSITORY' 
            ])
            return RedirectResponse(url=f'/git_info?findby={response.get('id')}', status_code=303)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))