SET SERVEROUTPUT ON

CREATE OR REPLACE FUNCTION calculate_gpa (
    p_student_id IN NUMBER
) RETURN NUMBER IS
    v_count NUMBER;
    v_avg   NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM students
     WHERE student_id = p_student_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'Student not found: ' || p_student_id
        );
    END IF;

    SELECT AVG(grade)
      INTO v_avg
      FROM enrollments
     WHERE student_id = p_student_id
       AND grade IS NOT NULL;

    RETURN ROUND(v_avg, 2);
END;
/
