from tools.encrypt_helper import EncryptHelper
from typing import Optional
from fastapi import Cookie, HTTPException, status
from pydantic import BaseModel
from datetime import datetime, timedelta, timezone
from tools.db_helper import DBHelper
import jwt


SECRET_KEY = "83b311ce53301c5c526212ae6420383d1375cc48941df43fc7200de7c729d15c"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 90


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


class AuthHelper:
    @staticmethod
    async def authenticate_user(user_input: str, password: str) -> Optional[User]:
        encrypted_input = EncryptHelper.encrypt_data(user_input)
        user = await AuthHelper.get_user_by_input(encrypted_input)
        if not user:
            return None
        if not EncryptHelper.verify_password(password, user.password_hash):
            return None
        return user

    @staticmethod
    async def get_current_user(access_token: Optional[str] = Cookie(default=None)) -> User:
        if not access_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Необходима авторизация"
            )

        try:
            payload = jwt.decode(access_token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id = int(payload.get("sub"))
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Недействительный токен"
            )

        user = await AuthHelper.get_user_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Пользователь не найден"
            )

        return user

    @staticmethod
    async def get_current_active_user(access_token = Cookie(default=None)) -> User:
        user = await AuthHelper.get_current_user(access_token)
        if user.is_blocked:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Пользователь заблокирован"
            )
        return user
    
    @staticmethod
    async def get_user_by_input(encrypted_input: Optional[str]) -> Optional[User]:
        if not encrypted_input:
            return None
        print(encrypted_input)
        user_db = await DBHelper.execute_get("get_user_by_email_or_login", encrypted_input)
        if user_db:
            decrypted_user = {
                "id": user_db["id"],
                "username": EncryptHelper.decrypt_data(user_db["username"]),
                "email": EncryptHelper.decrypt_data(user_db["email"]),
                "password_hash": user_db["password_hash"],
                "role": EncryptHelper.decrypt_data(user_db["role"]),
                "is_blocked": user_db["is_blocked"],
                "created_at": user_db["created_at"]
            }
            return User.model_validate(decrypted_user)
        return None
    
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
        to_encode = data.copy()
        expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
        to_encode.update({"exp": expire})
        token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return token
    
    @staticmethod
    async def get_user_by_id(user_id: Optional[int]) -> Optional[User]:
        if not user_id:
            return None
        user_db = await DBHelper.execute_get("get_user_by_id", user_id)
        if user_db:
            decrypted_user = {
                "id": user_db["id"],
                "username": EncryptHelper.decrypt_data(user_db["username"]),
                "email": EncryptHelper.decrypt_data(user_db["email"]),
                "password_hash": user_db["password_hash"],
                "role": EncryptHelper.decrypt_data(user_db["role"]),
                "is_blocked": user_db["is_blocked"],
                "created_at": user_db["created_at"]
            }
            return User.model_validate(decrypted_user)
        return None