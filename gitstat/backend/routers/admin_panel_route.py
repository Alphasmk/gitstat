from fastapi import APIRouter, HTTPException
from tools.db_helper import DBHelper
from tools.encrypt_helper import EncryptHelper

router = APIRouter()

@router.get('/users')
async def get_all_users():
    users = await DBHelper.get_all_users()
    return [
        {
            "id": user["id"],
            "username": EncryptHelper.decrypt_data(user["username"]),
            "email": EncryptHelper.decrypt_data(user["email"]),
            "role": user["role"],
            "is_blocked": user["is_blocked"],
            "created_at": user["created_at"]
        }
        for user in users
    ]

@router.put('/users/{user_id}/role')
async def change_user_role(user_id: int, role_data: dict):
    try:
        new_role = role_data.get('role')
        if new_role not in ['user', 'moderator', 'admin']:
            raise HTTPException(status_code=400, detail="Недопустимая роль")
        
        async with DBHelper.get_cursor() as cursor:
            await cursor.callproc("SYSTEM.change_user_role", [str(user_id), new_role])
        
        return {"status": "success", "message": "Роль успешно изменена"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put('/users/{user_id}/block')
async def toggle_user_block(user_id: int):
    print("tuytututut" + str(user_id))
    async with DBHelper.get_cursor() as cursor:
        await cursor.callproc("SYSTEM." + "change_user_block_state", [str(user_id)])
    return {"status": "success"}

@router.delete('/users/{user_id}')
async def delete_user(user_id: int):
    async with DBHelper.get_cursor() as cursor:
        await cursor.callproc("SYSTEM." + "delete_user", [str(user_id)])
    return {"status": "success"}