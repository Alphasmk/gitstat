from fastapi import FastAPI, Depends
from routers.login_route import router as LoginRouter 
from routers.register_route import router as RegisterRouter 
from fastapi.middleware.cors import CORSMiddleware

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