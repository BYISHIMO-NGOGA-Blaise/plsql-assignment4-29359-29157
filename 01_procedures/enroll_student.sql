SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE enroll_student (
    p_student_id    IN  NUMBER,
    p_course_id     IN  NUMBER,
    p_enrollment_id OUT NUMBER,
    p_first_name    IN  VARCHAR2 DEFAULT NULL,
    p_last_name     IN  VARCHAR2 DEFAULT NULL,
    p_email         IN  VARCHAR2 DEFAULT NULL
) AS
    v_student_count NUMBER;
    v_course_count  NUMBER;
BEGIN
    p_enrollment_id := NULL;

    SELECT COUNT(*)
      INTO v_student_count
      FROM students
     WHERE student_id = p_student_id;

    SELECT COUNT(*)
      INTO v_course_count
      FROM courses
     WHERE course_id = p_course_id;

    IF v_course_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Course not found');
    END IF;

    IF v_student_count = 0 THEN
        IF p_first_name IS NULL OR p_last_name IS NULL OR p_email IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Student not found. Provide first name, last name, and email to register.'
            );
        END IF;

        BEGIN
            INSERT INTO students (student_id, first_name, last_name, email)
            VALUES (p_student_id, p_first_name, p_last_name, p_email);

            DBMS_OUTPUT.PUT_LINE(
                SQL%ROWCOUNT || ' student row inserted. SQL%FOUND is TRUE.'
            );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                RAISE_APPLICATION_ERROR(
                    -20013,
                    'Student ID or email already exists'
                );
        END;
    END IF;

    p_enrollment_id := enrollments_seq.NEXTVAL;

    BEGIN
        INSERT INTO enrollments (enrollment_id, student_id, course_id, grade)
        VALUES (p_enrollment_id, p_student_id, p_course_id, NULL);

        DBMS_OUTPUT.PUT_LINE(
            SQL%ROWCOUNT || ' enrollment row inserted. Enrollment ID: ' ||
            p_enrollment_id
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            p_enrollment_id := NULL;
            RAISE_APPLICATION_ERROR(
                -20002,
                'Student is already enrolled in this course'
            );
    END;
END;
/
