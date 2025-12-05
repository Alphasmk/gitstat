from fastapi import APIRouter, HTTPException, status, Request, Depends
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from urllib.parse import urlparse
import re
from tools.db_helper import DBHelper
from tools.http_helper import HTTPHelper
from tools.auth_helper import AuthHelper

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
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Не ссылка на github")
        
        parts = [p for p in parsed.path.split("/") if p]

        if len(parts) == 1:
            return UserInput(type="profile", username=parts[0], repository=None)
        elif len(parts) >= 2:
            return UserInput(type="repository", username=parts[0], repository=parts[1])
        else: 
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Некорректная ссылка на github")
    else:
        if re.match(r"^[A-Za-z0-9-]+$", stroke):
            return UserInput(type="profile", username=stroke, repository=None)
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Некорректное имя пользователя")

async def get_github_response(result):
    if not HTTPHelper.check_internet():
        raise HTTPException(status_code=502, detail="Проверьте ваше интернет-соединение")
    if result.type == "profile":
        response = await HTTPHelper.async_http_get(f"https://api.github.com/users/{result.username}")
    elif result.type == "repository":
        response = await HTTPHelper.async_http_get(f"https://api.github.com/repos/{result.username}/{result.repository}")
    return response

async def get_count_of_rows(proc: str, value: int | str):
    return await DBHelper.is_was_request(proc, value)

@router.post('/check_git_info', response_class=RedirectResponse)
async def check_git_info(stroke: str, current_user = Depends(AuthHelper.get_current_user)):
    try:
        user_input = parse_user_input(stroke)
        result = RequestType.model_validate(user_input)
        if result.type == "profile":
            if user_input.username:
                count = await get_count_of_rows("is_was_profile_request_by_login", user_input.username)
            else:
                count = 0
            if count > 0:
                return RedirectResponse(url=f'/git_info?findby={result.username}', status_code=303)
            else:
                return RedirectResponse(url=f'/new_git_info?stroke={stroke}', status_code=303)
        else:
            if user_input.username and user_input.repository:
                count = await DBHelper.is_repository_exists(
                    user_input.username,
                    user_input.repository
                )
            else:
                count = 0
            if count > 0:
                return RedirectResponse(
                    url=f'/git_info?owner={result.username}&repo={result.repository}', 
                    status_code=303
                )
            else:
                return RedirectResponse(url=f'/new_git_info?stroke={stroke}', status_code=303)
    except HTTPException:
        raise
    except Exception as e:
        status_code = getattr(e, 'status_code', 500)
        detail = getattr(e, 'detail', "Ошибка при отправке запроса")
        raise HTTPException(status_code=status_code, detail=str(e))

@router.get('/git_info')
async def get_git_info(findby: str | None = None, owner: str | None = None, repo: str | None = None, current_user = Depends(AuthHelper.get_current_user)):
    try:
        if owner and repo:
            git_info = await DBHelper.get_repository_by_owner_and_name(owner, repo)
            if git_info:
                async with DBHelper.get_cursor() as cursor:
                    await cursor.callproc("SYSTEM." + "add_request_to_general_history", [
                        current_user.id,
                        git_info.get('git_id'),
                        None,
                        'REPOSITORY'
                    ])
                git_info['response_type'] = 'Repository'
                repo_id = git_info.get('git_id')
                git_info['languages'] = await DBHelper.execute_get_all("get_repository_languages", str(repo_id))
                git_info['topics'] = await DBHelper.execute_get_all("get_repository_topics", str(repo_id))
                git_info['license'] = await DBHelper.execute_get_all("get_repository_license", str(repo_id))
                git_info['commits'] = await DBHelper.execute_get_all("get_repository_commits", str(repo_id))
                
        elif findby and isint(findby):
            git_info = await DBHelper.get_repository_by_id(int(findby))
            if git_info:
                git_info['response_type'] = 'Repository'
                async with DBHelper.get_cursor() as cursor:
                    await cursor.callproc("SYSTEM." + "add_request_to_general_history", [
                        current_user.id,
                        git_info.get('git_id'),
                        None,
                        'REPOSITORY'
                    ])
        elif findby:
            git_info = await DBHelper.execute_get("get_profile_by_name", findby)
            if git_info:
                repos = await DBHelper.get_user_repos_from_db(findby)
                for repo_item in repos:
                    repo_id = repo_item.get('git_id')
                    languages = await DBHelper.execute_get_all("get_repository_languages", str(repo_id))
                    repo_item['languages'] = languages if languages else []
                git_info['response_type'] = 'Profile'
                git_info['repositories'] = repos
                async with DBHelper.get_cursor() as cursor:
                    await cursor.callproc("SYSTEM." + "add_request_to_general_history", [
                        current_user.id,
                        None,
                        git_info.get('git_id'),
                        'PROFILE'
                    ])
        return git_info
    except HTTPException:
        raise
    except Exception as e:
        status_code = getattr(e, 'status_code', 500)
        detail = getattr(e, 'detail', "Ошибка при отправке запроса")
        raise HTTPException(status_code=status_code, detail=str(e))

@router.get('/new_git_info', response_class=RedirectResponse)
async def renew_git_info(stroke: str, current_user = Depends(AuthHelper.get_current_user)):
    try:
        user_input = parse_user_input(stroke)
        result = RequestType.model_validate(user_input)
        response = await get_github_response(result)
        if not response:
            raise HTTPException(status_code=502, detail="Проверьте ваше интернет-соединение")
        if response.get('status'):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Не найдено")
        
        if result.type == "profile":
            count = await get_count_of_rows("is_was_profile_request", response['id'])
            if count == 0:
                await DBHelper.add_profile_to_history(response)
            else:
                await DBHelper.update_profile_history(response)
            
            await DBHelper.get_user_repos_from_git(
                response.get("login"), 
                current_user, 
                response
            )
            
            return RedirectResponse(url=f'/git_info?findby={result.username}', status_code=303)
        else:
            await DBHelper.process_repository(response, current_user)
            return RedirectResponse(url=f'/git_info?findby={response.get('id')}', status_code=303)
    except HTTPException as e:
        raise
    except Exception as e:
        status_code = getattr(e, 'status_code', 500)
        detail = getattr(e, 'detail', "Ошибка при отправке запроса")
        raise HTTPException(status_code=status_code, detail=str(e))