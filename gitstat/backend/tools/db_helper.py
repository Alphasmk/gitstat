from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager
import oracledb
import logging
import time

class DBHelper:
    DATABASE_URL = "oracle+oracledb://system:1111@localhost:1522/?service_name=freepdb1"
    engine = create_engine(DATABASE_URL)
    Base = declarative_base()
    SessionLocal = sessionmaker(bind=engine, autoflush=False)

    @staticmethod
    def get_db():
        db = DBHelper.SessionLocal()
        try:
            yield db
        finally:
            db.close()
    
    @staticmethod
    @contextmanager
    def get_cursor():
        conn = oracledb.connect(user="system", password="1111", dsn="localhost:1522/freepdb1")
        conn.call_timeout = 5000
        try:
            cursor = conn.cursor()
            yield cursor
            conn.commit()
        except:
            conn.rollback()
            raise
        finally:
            cursor.close()
            conn.close()
    
    @staticmethod
    def execute_get_user(proc_name: str, value: str | int):
        try:
            with DBHelper.get_cursor() as cursor:
                ref_cursor = cursor.var(oracledb.CURSOR)
                cursor.callproc(proc_name, [str(value), ref_cursor])
                result_cursor = ref_cursor.getvalue()
                row = result_cursor.fetchone()
                if not row:
                    return None
                columns = [col[0].lower() for col in result_cursor.description]
                row_dict = dict(zip(columns, row))
                return row_dict
        except Exception as e:
            raise
    
    @staticmethod
    def is_was_request(proc_name: str, value: int):
        try:
            with DBHelper.get_cursor() as cursor:
                out_param = cursor.var(oracledb.NUMBER)
                cursor.callproc(proc_name, [value, out_param])
                result = out_param.getvalue()
                return result
        except Exception as e:
            raise