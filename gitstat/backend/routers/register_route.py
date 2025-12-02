from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from tools.db_helper import DBHelper
from tools.password_hasher import Hasher
from models.user import User as DBUser

router = APIRouter()

class RegisterUser(BaseModel):
    username: str
    email: EmailStr
    password: str

@router.post("/register", response_class=JSONResponse)
async def register_user(form_data: RegisterUser):
    existing_user = await DBHelper.execute_get(
        "get_user_by_email_or_login", 
        form_data.username.lower()
    )
    
    if not existing_user:
        existing_user = await DBHelper.execute_get(
            "get_user_by_email_or_login", 
            form_data.email.lower()
        )
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь с таким логином или email уже существует",
        )

    total_users = await DBHelper.get_total_users_count()
    role = "admin" if total_users == 0 else "user"

    hashed_password = Hasher.get_password_hash(form_data.password)
    
    try:
        async with DBHelper.get_cursor() as cursor:
            await cursor.callproc("SYSTEM.add_user", [
                form_data.username.lower(), 
                form_data.email.lower(), 
                hashed_password, 
                role, 
                "N"
            ])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Не удалось создать пользователя: {str(e)}",
        )

    return JSONResponse(
        content={"message": "Пользователь успешно создан"},
        status_code=status.HTTP_201_CREATED,
    )