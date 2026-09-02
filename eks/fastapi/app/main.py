import os
import pymysql
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

DB_HOST = os.environ.get("DB_HOST")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_NAME = os.environ.get("DB_NAME", "rdsdb")
DB_PORT = int(os.environ.get("DB_PORT", "3306"))


def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        port=DB_PORT,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )


class ScoreInput(BaseModel):
    student_idx: int
    kor: int
    eng: int
    mat: int


@app.get("/students")
def get_students():
    """교육생 리스트 (이름 선택용 드롭다운에 사용)"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = """
                SELECT b.idx AS student_idx, b.name, c.class_name
                FROM tstudent b
                INNER JOIN tclass c ON b.class_idx = c.idx
            """
            cursor.execute(sql)
            result = cursor.fetchall()
        connection.close()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/scores")
def register_score(score: ScoreInput):
    """선택한 학생의 성적 등록 (INSERT)"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = """
                INSERT INTO tscore (student_idx, kor, eng, mat)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(sql, (score.student_idx, score.kor, score.eng, score.mat))
        connection.commit()
        connection.close()
        return {"message": "성적이 등록되었습니다."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/scores")
def get_scores():
    """등록된 성적 전체 조회 (tclass/tstudent/tscore JOIN)"""
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = """
                SELECT b.email, b.name, c.class_name, kor, eng, mat,
                    (kor + eng + mat) AS tot,
                    (kor + eng + mat) / 3 AS avg
                FROM tscore a
                INNER JOIN tstudent b ON a.student_idx = b.idx
                INNER JOIN tclass c ON b.class_idx = c.idx
            """
            cursor.execute(sql)
            result = cursor.fetchall()
        connection.close()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))