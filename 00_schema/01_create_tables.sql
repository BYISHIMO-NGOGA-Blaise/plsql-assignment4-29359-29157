SET SERVEROUTPUT ON
SET DEFINE OFF

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE enrollments CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE courses CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE students CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE enrollments_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE students (
    student_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name  VARCHAR2(50),
    email      VARCHAR2(100) UNIQUE
);

CREATE TABLE courses (
    course_id   NUMBER PRIMARY KEY,
    course_name VARCHAR2(100),
    credits     NUMBER
);

CREATE TABLE enrollments (
    enrollment_id NUMBER PRIMARY KEY,
    student_id    NUMBER,
    course_id     NUMBER,
    grade         NUMBER,
    CONSTRAINT fk_student
        FOREIGN KEY (student_id)
        REFERENCES students (student_id),
    CONSTRAINT fk_course
        FOREIGN KEY (course_id)
        REFERENCES courses (course_id),
    CONSTRAINT ck_grade_range
        CHECK (grade IS NULL OR grade BETWEEN 0 AND 100),
    CONSTRAINT uq_student_course
        UNIQUE (student_id, course_id)
);

CREATE SEQUENCE enrollments_seq
    START WITH 5
    INCREMENT BY 1
    NOCACHE;
