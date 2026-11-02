SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100
COLUMN v_name FORMAT A20
COLUMN v_email FORMAT A30
COLUMN v_id FORMAT 9999
COLUMN gpa FORMAT 999.99
COLUMN letter_grade FORMAT A12

PROMPT === 1. Student record: %ROWTYPE, user-defined record, OUT ===
VAR v_name VARCHAR2(100)
VAR v_email VARCHAR2(100)
EXEC show_student_record(1, :v_name, :v_email);
PRINT v_name v_email

PROMPT === 2. Register and enroll a new student ===
VAR v_id NUMBER
EXEC enroll_student(10, 101, :v_id, 'Peter', 'Paul', 'peter@gmail.com');
PRINT v_id
EXEC maintain_enrollment('GRADE', :v_id, 70);

PROMPT === 3. Enroll a student, update the grade, then delete ===
EXEC enroll_student(3, 101, :v_id);
PRINT v_id
EXEC maintain_enrollment('GRADE', :v_id, 88);
EXEC maintain_enrollment('DELETE', :v_id);

PROMPT === 4. Course report: cursor, collections, BULK COLLECT ===
EXEC show_course_report(101);

PROMPT === 5. FORALL bulk update ===
EXEC add_bonus_marks(5);

PROMPT === 6. Functions in SQL ===
SELECT s.student_id,
       calculate_gpa(s.student_id) AS gpa,
       get_letter_grade(calculate_gpa(s.student_id)) AS letter_grade
FROM students s
ORDER BY s.student_id;

PROMPT === Rollback test data ===
ROLLBACK;
