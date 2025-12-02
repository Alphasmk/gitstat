from datetime import datetime, timedelta, timezone
from typing import Optional
import logging
from fastapi import APIRouter, Depends, HTTPException, status, Cookie, Response
from pydantic import BaseModel
from tools.db_helper import DBHelper
from tools.password_hasher import Hasher
from tools.auth_helper import AuthHelper, SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES, User
from models.user import User as DBUser

router = APIRouter()

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    id: Optional[int] = None

class LoginUser(BaseModel):
    input: str
    password: str

@router.get("/users/me/", response_model=User)
async def read_users_me(current_user: User = Depends(AuthHelper.get_current_user)) -> User:
    return current_user


@router.post("/login", response_model=Token)
async def login_for_access_token(response: Response, form_data: LoginUser) -> Token:
    user = await AuthHelper.authenticate_user(form_data.input.lower(), form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный логин или пароль",
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    print(f"User role: {user.role}")
    access_token = AuthHelper.create_access_token(
        data={
        "sub": str(user.id),
        "role": user.role
        },
        expires_delta=access_token_expires
    )

    response.set_cookie(
        key="access_token",
        value=access_token,
        httponly=True,
        secure=False,
        samesite="lax"
    )

    return Token(access_token=access_token, token_type="bearer")


@router.get("/get/hash")
async def get_hash() -> str:
    return Hasher.get_password_hash("secret")


@router.get("/test")
async def test(current_user: User = Depends(AuthHelper.get_current_active_user)):
    return {"message": f"Привет, {current_user.username}! ID: {current_user.id}"}

@router.post("/logout")
async def logout(response: Response):
    response.delete_cookie(key="access_token")
    return {"message": "Вы успешно вышли из системы"}