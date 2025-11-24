from asyncio import create_task, run
from aiohttp import ClientSession
from сonfig import GITHUB_ACCESS_TOKEN as token

class HTTPHelper:
    @staticmethod
    async def async_http_get(path: str):
        async with ClientSession() as session:
            response = await session.get(url=path, headers={"Authorization": f"Bearer {token}"})
            return await response.json()