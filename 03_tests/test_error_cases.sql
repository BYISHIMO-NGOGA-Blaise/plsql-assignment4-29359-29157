SET SERVEROUTPUT ON
SET LINESIZE 200
WHENEVER SQLERROR CONTINUE

VAR v_id NUMBER
VAR v_name VARCHAR2(100)
VAR v_email VARCHAR2(100)

PROMPT === 1. Student not found ===
EXEC enroll_student(999, 101, :v_id);

PROMPT === 2. Course not found ===
EXEC enroll_student(1, 999, :v_id);

PROMPT === 3. Duplicate enrollment ===
EXEC enroll_student(1, 101, :v_id);

PROMPT === 4. Duplicate email ===
EXEC enroll_student(20, 101, :v_id, 'John', 'Doe', 'john@gmail.com');

PROMPT === 5. Grade above 100 ===
EXEC maintain_enrollment('GRADE', 1, 120);

PROMPT === 6. Grade for an unknown enrollment ===
EXEC maintain_enrollment('GRADE', 9999, 80);

PROMPT === 7. Delete an unknown enrollment ===
EXEC maintain_enrollment('DELETE', 9999);

PROMPT === 8. Invalid action ===
EXEC maintain_enrollment('INVALID', 1, 80);

PROMPT === 9. GPA for an unknown student ===
SELECT calculate_gpa(999) FROM dual;

PROMPT === 10. Letter grade outside 0-100 ===
SELECT get_letter_grade(120) FROM dual;

PROMPT === 11. Bulk DML errors ===
EXEC add_bonus_marks(20);

PROMPT === 12. Invalid bonus ===
EXEC add_bonus_marks(0);

PROMPT === 13. NO_DATA_FOUND handled in show_student_record ===
EXEC show_student_record(999, :v_name, :v_email);

PROMPT === 14. TOO_MANY_ROWS ===
DECLARE
    v_course_name courses.course_name%TYPE;
BEGIN
    SELECT course_name INTO v_course_name FROM courses;
EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('More than one row returned.');
END;
/

PROMPT === 15. User-defined exception ===
DECLARE
    invalid_grade EXCEPTION;
BEGIN
    RAISE invalid_grade;
EXCEPTION
    WHEN invalid_grade THEN
        DBMS_OUTPUT.PUT_LINE('Grade cannot exceed 100.');
END;
/

PROMPT === 16. Direct RAISE_APPLICATION_ERROR ===
BEGIN
    RAISE_APPLICATION_ERROR(-20099, 'Demonstration of RAISE_APPLICATION_ERROR');
END;
/

PROMPT === Rollback bulk test changes ===
ROLLBACK;
