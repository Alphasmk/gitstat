from asyncio import create_task, run
from aiohttp import ClientSession
from сonfig import GITHUB_ACCESS_TOKEN as token
import socket

class HTTPHelper:
    @staticmethod
    async def async_http_get(path: str):
        async with ClientSession() as session:
            response = await session.get(url=path, headers={"Authorization": f"Bearer {token}"})
            return await response.json()
    
    @staticmethod
    def check_internet(host="8.8.8.8", port=53, timeout=3):
        try:
            socket.setdefaulttimeout(timeout)
            socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
            return True
        except socket.error:
            return False