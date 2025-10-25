from datetime import datetime, timedelta, timezone
from typing import Optional
import jwt
from fastapi import APIRouter, Depends, HTTPException, status, Cookie, Response
# from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.orm import Session
from tools.db_helper import get_db
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

def get_user_by_id(id: Optional[int], db: Session) -> Optional[User]:
    if not id:
        return None
    user_db = db.query(DBUser).filter(DBUser.id == id).first()
    if user_db:
        return User.model_validate(user_db)
    return None

def get_user_by_input(input: Optional[str], db: Session) -> Optional[User]:
    if not input:
        return None
    user_db = db.query(DBUser).filter(DBUser.username == input).first()
    if not user_db:
        user_db = db.query(DBUser).filter(DBUser.email == input).first()
    if user_db:
        return User.model_validate(user_db)
    return None


def authenticate_user(input: str, password: str, db: Session) -> Optional[User]:
    user = get_user_by_input(input, db)
    if not user or not Hasher.verify_password(password, user.password_hash):
        return None
    return user


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(
        access_token: str | None = Cookie(default=None),
        db: Session = Depends(get_db)
    ) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials"
    )
    
    if not access_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Хуй блятььб"
        )

    payload = jwt.decode(access_token, SECRET_KEY, algorithms=[ALGORITHM])
    id: Optional[int] = int(payload.get("sub"))
    if not id:
        raise credentials_exception
    user = get_user_by_id(id, db)
    if not user:
        raise credentials_exception
    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User | None:
    if current_user.is_blocked:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user")
    return current_user

@router.get("/users/me/", response_model=User)
async def read_users_me(current_user: User = Depends(get_current_active_user)) -> User:
    return current_user

@router.post("/login", response_model=Token, status_code=200)
async def login_for_access_token(
    response: Response,
    form_data: LoginUser,
    db: Session = Depends(get_db)
) -> Token:
    user = authenticate_user(form_data.input, form_data.password, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(data={"sub": str(user.id)}, expires_delta=access_token_expires)
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
    return {"message": f"Привет, {current_user.username}! id: {current_user.id}"}

@router.post("/logout")
async def logout(
    response: Response
):
    response.delete_cookie(key="access_token")