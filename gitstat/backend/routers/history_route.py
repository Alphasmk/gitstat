from fastapi import APIRouter
from tools.db_helper import DBHelper

router = APIRouter()

@router.get("/history")
async def get_user_history(user_id: int):
    return await DBHelper.get_user_history(user_id)

@router.get("/history_secure")
async def get_user_history_secure(user_id: int):
    return await DBHelper.get_user_history_secure(user_id)