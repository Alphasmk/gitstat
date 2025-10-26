from sqlalchemy import Column, Integer, String, Date, CHAR, CheckConstraint, func
from tools.db_helper import DBHelper

class User(DBHelper.Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False, default="user")
    is_blocked = Column(CHAR(1), default="N")
    created_at = Column(Date, server_default=func.current_date())
    __table_args__ = (
        CheckConstraint("is_blocked IN ('Y', 'N')"),
    )