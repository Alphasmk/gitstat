from datetime import datetime, timedelta, timezone
from typing import Optional
import jwt
import logging
from fastapi import APIRouter, Depends, HTTPException, status, Cookie, Response
from pydantic import BaseModel
from tools.db_helper import DBHelper
from tools.password_hasher import Hasher
from models.user import User as DBUser

SECRET_KEY = "83b311ce53301c5c526212ae6420383d1375cc48941df43fc7200de7c729d15c"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

router = APIRouter()

class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    id: Optional[int] = None


class User(BaseModel):
    id: int
    username: str
    email: str
    password_hash: str
    role: str
    is_blocked: bool
    created_at: datetime

    class Config:
        from_attributes = True


class LoginUser(BaseModel):
    input: str
    password: str


def get_user_by_id(user_id: Optional[int]) -> Optional[User]:
    if not user_id:
        return None
    user_db = DBHelper.execute_get_user("get_user_by_id", user_id)
    if user_db:
        return User.model_validate(user_db)
    return None


def get_user_by_input(user_input: Optional[str]) -> Optional[User]:
    if not user_input:
        return None
    user_db = DBHelper.execute_get_user("get_user_by_email_or_login", user_input)
    if user_db:
        return User.model_validate(user_db)
    return None


def authenticate_user(user_input: str, password: str) -> Optional[User]:
    """Проверка логина и пароля пользователя."""
    user = get_user_by_input(user_input)
    if not user:
        return None
    if not Hasher.verify_password(password, user.password_hash):
        return None
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Создать JWT токен."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return token

async def get_current_user(access_token: Optional[str] = Cookie(default=None)) -> User:
    """Получить текущего пользователя по токену из cookies."""
    if not access_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Необходима авторизация"
        )

    try:
        payload = jwt.decode(access_token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Недействительный токен"
        )

    user = get_user_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Пользователь не найден"
        )

    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    if current_user.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Пользователь заблокирован"
        )
    return current_user

@router.get("/users/me/", response_model=User)
async def read_users_me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.post("/login", response_model=Token)
async def login_for_access_token(response: Response, form_data: LoginUser) -> Token:
    user = authenticate_user(form_data.input.lower(), form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный логин или пароль",
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)},
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
async def test(current_user: User = Depends(get_current_active_user)):
    return {"message": f"Привет, {current_user.username}! ID: {current_user.id}"}


@router.post("/logout")
async def logout(response: Response):
    response.delete_cookie(key="access_token")
    return {"message": "Вы успешно вышли из системы"}
