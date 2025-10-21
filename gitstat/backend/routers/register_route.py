from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from tools.db_helper import get_db, get_cursor
from tools.password_hasher import Hasher
from models.user import User as DBUser

router = APIRouter()

class RegisterUser(BaseModel):
    username: str
    email: EmailStr
    password: str

@router.post("/register", response_class=JSONResponse)
async def register_user(form_data: RegisterUser, db: Session = Depends(get_db)):
    existing_user = (
        db.query(DBUser)
        .filter(or_(DBUser.username == form_data.username, DBUser.email == form_data.email))
        .first()
    )
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        )

    total_users = db.query(func.count(DBUser.id)).scalar()
    role = "admin" if total_users == 0 else "user"

    hashed_password = Hasher.get_password_hash(form_data.password)
    try:
        with get_cursor() as cursor:
            cursor.callproc(
                "add_user",
                [form_data.username, form_data.email, hashed_password, role, "N"],
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