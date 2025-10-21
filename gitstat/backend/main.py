from fastapi import FastAPI, Depends
from routers.login_route import router as LoginRouter 
from routers.register_route import router as RegisterRouter 
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(LoginRouter)
app.include_router(RegisterRouter)