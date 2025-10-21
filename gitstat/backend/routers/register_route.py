from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from typing import Annotated
from fastapi.security import OAuth2PasswordRequestForm
from tools.db_helper import get_db, get_cursor
from tools.password_hasher import Hasher
from models.user import User as DBUser
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

router = APIRouter()

class RegisterUser(BaseModel):
    username: str
    email: EmailStr
    password: str

@router.post("/register")
async def register_user(
    form_data: RegisterUser,
    db: Session = Depends(get_db)
):
    user_in_db = db.query(DBUser).filter(or_(DBUser.username == form_data.username, DBUser.email == form_data.email)).first()
    if user_in_db:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='User already exists'
        )

    row_count = db.query(func.count(DBUser.id)).scalar()

    with get_cursor() as cursor:
        cursor.callproc("add_user", [
            form_data.username,
            form_data.email,
            Hasher.get_password_hash(form_data.password),
            "admin" if row_count == 0 else "user",
            "N"
        ])

    # new_user = DBUser(
    #     username = form_data.username,
    #     email = form_data.email,
    #     password_hash = Hasher.get_password_hash(form_data.password),
    #     role = "admin" if row_count == 0 else "user",
    #     is_blocked = "N"
    # )



    # db.add(new_user)
    # db.commit()
    # db.refresh(new_user)
    return {"msg": "good"}