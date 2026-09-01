import os
import time
import pymysql
from fastapi import FastAPI, HTTPException

app = FastAPI()

DB_HOST = os.environ.get("DB_HOST")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_NAME = os.environ.get("DB_NAME", "testdb")
DB_PORT = int(os.environ.get("DB_PORT", "3306"))

def get_db_connection():
    # MySQL이 완전히 뜰 때까지 최대 몇 번 재시도하는 로직
    retries = 5
    while retries > 0:
        try:
            return pymysql.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                port=DB_PORT,
                charset='utf8mb4',
                cursorclass=pymysql.cursors.DictCursor
            )
        except pymysql.err.OperationalError:
            retries -= 1
            time.sleep(2)
    raise Exception("MySQL 서버에 연결할 수 없습니다.")

@app.get("/items")
def get_items():
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = "select email, name, class_name, kor, eng, mat, tot, avg from vinfo ;"
            cursor.execute(sql)
            result = cursor.fetchall()
        connection.close()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))