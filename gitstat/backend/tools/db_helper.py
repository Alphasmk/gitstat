from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager
import oracledb
import logging
import time

logger = logging.getLogger(__name__)

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
        logger.info("Попытка установить соединение с Oracle...") # Добавьте это
        start_conn_time = time.time()
        conn = oracledb.connect(user="system", password="1111", dsn="localhost:1522/freepdb1")
        conn.call_timeout = 5000
        end_conn_time = time.time()
        logger.info(f"Соединение с Oracle установлено за {end_conn_time - start_conn_time:.4f} секунд.") # Добавьте это
        try:
            cursor = conn.cursor()
            yield cursor
            conn.commit()
            logger.info("Транзакция Oracle закоммичена.")
        except Exception as e:
            conn.rollback()
            logger.error(f"Ошибка транзакции Oracle: {e}. Откат.")
            raise
        finally:
            cursor.close()
            conn.close()
            logger.info("Соединение с Oracle закрыто.")
    
    @staticmethod
    def execute_get_user(proc_name: str, value: str | int):
        logger.info(f"Вызов хранимой процедуры {proc_name} с значением: {value}")
        logger.info(f"Type of value: {type(value)}")
        start_exec_time = time.time()
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
                logger.info(f"Процедура {proc_name} успешно выполнена, получены данные: {row_dict}")
                return row_dict
        except Exception as e:
            logger.error(f"Ошибка при выполнении процедуры {proc_name}: {e}")
            raise
        finally:
            end_exec_time = time.time()
            logger.info(f"Выполнение DBHelper.execute_get_user завершено за {end_exec_time - start_exec_time:.4f} секунд.")
