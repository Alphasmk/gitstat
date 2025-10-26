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
async def register_user(form_data: RegisterUser, db: Session = Depends(DBHelper.get_db)):
    existing_user = DBHelper.execute_get_user("get_user_by_email_or_login", form_data.username)
    if not existing_user:
        DBHelper.execute_get_user("get_user_by_email_or_login", form_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        )

    total_users = db.query(func.count(DBUser.id)).scalar()
    role = "admin" if total_users == 0 else "user"

    hashed_password = Hasher.get_password_hash(form_data.password)
    try:
        with DBHelper.get_cursor() as cursor:
            cursor.callproc(
                "add_user",
                [form_data.username.lower(), form_data.email.lower(), hashed_password, role, "N"],
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create user: {str(e)}",
        )

    return JSONResponse(
        content={"message": "User successfully created"},
        status_code=status.HTTP_201_CREATED,
    )