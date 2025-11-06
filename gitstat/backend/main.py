from fastapi import FastAPI, Depends
from routers.login_route import router as LoginRouter 
from routers.register_route import router as RegisterRouter 
from routers.git_request_route import router as GitRequestRouter
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:5173",
                   "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(LoginRouter)
app.include_router(RegisterRouter)
app.include_router(GitRequestRouter)

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="localhost",
        port=8000,
        reload=True,
    )