import json
import os
import time
import boto3
import pymysql

_secret_cache = None


def get_secret():
    global _secret_cache
    if _secret_cache is not None:
        return _secret_cache

    secret_name = os.environ["DB_SECRET_NAME"]
    region_name = os.environ.get("AWS_REGION", "ap-northeast-3")

    client = boto3.client("secretsmanager", region_name=region_name)
    response = client.get_secret_value(SecretId=secret_name)
    _secret_cache = json.loads(response["SecretString"])
    return _secret_cache


def get_connection():
    secret = get_secret()
    return pymysql.connect(
        host=secret.get("host") or os.environ["DB_HOST"],
        user=secret["username"],
        password=secret["password"],
        database=os.environ.get("DB_NAME", "rdsdb"),
        port=int(os.environ.get("DB_PORT", 3306)),
        connect_timeout=5,
        cursorclass=pymysql.cursors.DictCursor,
    )


def get_students():
    retries = 3
    last_error = None

    while retries > 0:
        conn = None
        try:
            conn = get_connection()
            with conn.cursor() as cursor:
                sql = """
                    SELECT b.email, b.name, b.location, c.class_name
                    FROM tstudent b
                    INNER JOIN tclass c ON b.class_idx = c.idx
                """
                cursor.execute(sql)
                return cursor.fetchall()
        except Exception as e:
            last_error = e
            print(f"student query failed (retries left: {retries - 1}): {e}")
            retries -= 1
            time.sleep(1)
        finally:
            if conn:
                conn.close()

    print(f"student query permanently failed: {last_error}")
    return None


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    if method == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": "",
        }

    students = get_students()
    if students is None:
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"status": "Failure"}),
        }

    return {
        "statusCode": 200,
        "headers": cors_headers(),
        "body": json.dumps(students, default=str, ensure_ascii=False),
    }


def cors_headers():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    }