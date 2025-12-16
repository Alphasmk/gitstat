from fastapi import APIRouter, HTTPException, status
from fastapi.responses import JSONResponse
import asyncio
from tools.db_helper import DBHelper
from tools.encrypt_helper import EncryptHelper

router = APIRouter()

@router.post("/generate-users", response_class=JSONResponse)
async def generate_test_users():
    BATCH_SIZE = 1000
    TOTAL_USERS = 100000
    PASSWORD = "1111"
    
    hashed_password = EncryptHelper.get_password_hash(PASSWORD)
    
    try:
        async with DBHelper.get_cursor() as cursor:
            for batch_start in range(0, TOTAL_USERS, BATCH_SIZE):
                batch_data = []
                
                for i in range(batch_start, min(batch_start + BATCH_SIZE, TOTAL_USERS)):
                    username = f"user_{i+1}"
                    email = f"user_{i+1}@test.com"
                    
                    encrypted_username = EncryptHelper.encrypt_data(username.lower())
                    encrypted_email = EncryptHelper.encrypt_data(email.lower())
                    
                    batch_data.append((
                        encrypted_username,
                        encrypted_email,
                        hashed_password,
                        "user",
                        "N"
                    ))
                
                sql = """
                    BEGIN
                        SYSTEM.add_user(:1, :2, :3, :4, :5);
                    END;
                """
                
                await cursor.executemany(sql, batch_data)
                
                print(f"Добавлено пользователей: {min(batch_start + BATCH_SIZE, TOTAL_USERS)}/{TOTAL_USERS}")
        
        return JSONResponse(
            content={
                "message": f"Успешно создано {TOTAL_USERS} пользователей",
                "total": TOTAL_USERS,
                "password": PASSWORD
            },
            status_code=status.HTTP_201_CREATED,
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка генерации пользователей: {str(e)}",
        )
