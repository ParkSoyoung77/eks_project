-- 커뮤니티에 사용할 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS testdb;
-- 데이터베이스 사용자 권한 생성
CREATE USER 'std17'@'%' IDENTIFIED BY 'std17pass';
GRANT ALL PRIVILEGES ON testdb.* TO 'std17'@'%';
CREATE USER 'std17'@'localhost' IDENTIFIED BY 'std17pass';
GRANT ALL PRIVILEGES ON testdb.* TO 'std17'@'localhost';
FLUSH PRIVILEGES;

USE testdb;

-- 과정 정보
DROP TABLE IF EXISTS tclass;
CREATE TABLE IF NOT EXISTS tclass (
    idx          INT            AUTO_INCREMENT
,   class_name  VARCHAR(100)    NOT NULL
,   PRIMARY KEY (idx)
) COMMENT '교육과정 정보'; -- 세미콜론 추가 완료

INSERT INTO tclass (class_name) VALUES
  ('MSP 솔류션 아키텍트 6기')
, ('AI로 완성하는 하이브리드 클라우드 아키텍쳐 엔지니어 양성 과정')
;

-- 학생 정보 테이블 생성
DROP TABLE IF EXISTS tstudent;
CREATE TABLE IF NOT EXISTS tstudent (
    idx             INT             AUTO_INCREMENT -- 띄어쓰기 수정 (AUTO_INCREMENT)
,   class_idx       INT             NOT NULL   
,   email           VARCHAR(50)     NOT NULL   
,   name            VARCHAR(20)     NOT NULL
,   location        VARCHAR(20)     NOT NULL
,   PRIMARY KEY (idx)
,   CONSTRAINT fk_class_idx 
        FOREIGN KEY (class_idx) 
        REFERENCES tclass(idx)
) COMMENT '교육생 정보 테이블';

-- 컬럼에 맞게 데이터 매칭 수정
INSERT INTO tstudent (class_idx, email, name, location) VALUES
 (1, 'aaa@aaa.cloud', '홍길동', '부산')
,(1, 'bbb@bbb.cloud', '김유신', '부산')
,(2, 'abc@abc.cloud', '강감찬', '경기')
;

-- 성적 TABLE 생성
DROP TABLE IF EXISTS tscore;
CREATE TABLE IF NOT EXISTS tscore (
    idx             INT     AUTO_INCREMENT
,   student_idx     INT     NOT NULL
,   kor             TINYINT
,   eng             TINYINT
,   mat             TINYINT
,   PRIMARY KEY (idx)   
,   CONSTRAINT fk_student_idx 
        FOREIGN KEY (student_idx) 
        REFERENCES tstudent(idx)
) COMMENT '성적 테이블';

-- student_idx, kor, eng, mat 순서에 맞게 데이터 입력
INSERT INTO tscore (student_idx, kor, eng, mat) VALUES
  (1, 100, 100, 90)
, (2, 90, 80, 70)
;




-- ========================================================
-- fastAPI에서 사용할 VIEW를 생성합니다.
CREATE VIEW vinfo
as
    select b.email, b.name, c.class_name, kor, eng, mat, 
        (kor+eng+mat) as tot, (kor+eng+mat)/3 as avg 
    from tscore a 
    inner join tstudent b on a.student_idx=b.idx 
    inner join tclass c on b.class_idx=c.idx
;