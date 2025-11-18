from fastapi import APIRouter, HTTPException, status, Request, Depends
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from urllib.parse import urlparse
from asyncio import create_task, run
from aiohttp import ClientSession
import requests
import re
from сonfig import GITHUB_ACCESS_TOKEN as token
from tools.db_helper import DBHelper
from datetime import datetime
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

async def get_github_response(result):
    if result.type == "profile":
        response = await async_http_get(f"https://api.github.com/users/{result.username}")
    elif result.type == "repository":
        response = await async_http_get(f"https://api.github.com/repos/{result.username}/{result.repository}")
    return response

def get_count_of_rows(proc: str, id: int):
    return DBHelper.is_was_request(proc, id)

def add_profile_to_history(response, result):
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

def update_profile_history(response, result):
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

@router.get('/git_info')
async def get_git_info(username: str, current_user = Depends(get_current_user)):
    try:
        git_info = DBHelper.execute_get_user("get_user_profile_by_name", username)
        return git_info
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get('/new_git_info', response_class=RedirectResponse)
async def renew_git_info(stroke: str, current_user = Depends(get_current_user)):
    try:
        result = RequestType.model_validate(parse_user_input(stroke))
        response = await get_github_response(result)
        if result.type == "profile":
            count = get_count_of_rows("is_was_profile_request", response['id'])
        else:
            count = get_count_of_rows("is_was_repository_request", response['id'])
        if count == 0:
            add_profile_to_history(response, result)
        else:
            update_profile_history(response, result)

        with DBHelper.get_cursor() as cursor:
            if result.type == "profile":
                cursor.callproc("add_request_to_general_history", [
                    current_user.id,
                    None,
                    response.get('id'),
                    'PROFILE'
                ])
            else:
                cursor.callproc("add_request_to_general_history", [
                    current_user.id,
                    response.get('id'),
                    None,
                    'REPOSITORY'
                ])
        return RedirectResponse(f'/git_info?username={result.username}', status_code=301)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))