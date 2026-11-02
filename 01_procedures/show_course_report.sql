SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE show_course_report (
    p_course_id IN NUMBER
) AS
    TYPE student_names IS TABLE OF VARCHAR2(150)
        INDEX BY PLS_INTEGER;

    TYPE grade_tab IS TABLE OF enrollments.grade%TYPE;

    v_names  student_names;
    v_grades grade_tab;
    v_key    PLS_INTEGER;
    v_total  NUMBER := 0;

    CURSOR c_roster IS
        SELECT s.student_id,
               s.first_name || ' ' || s.last_name AS full_name,
               e.grade
          FROM students s
          JOIN enrollments e
            ON e.student_id = s.student_id
         WHERE e.course_id = p_course_id
         ORDER BY s.student_id;

    v_row c_roster%ROWTYPE;
BEGIN
    OPEN c_roster;

    LOOP
        FETCH c_roster INTO v_row;
        EXIT WHEN c_roster%NOTFOUND;

        v_key := NVL(v_key, 0) + 1;
        v_names(v_key) :=
            v_row.student_id || ' - ' || v_row.full_name ||
            ' - grade: ' || NVL(TO_CHAR(v_row.grade), 'not assigned');
    END LOOP;

    CLOSE c_roster;

    SELECT grade
      BULK COLLECT INTO v_grades
      FROM enrollments
     WHERE course_id = p_course_id
       AND grade IS NOT NULL
     ORDER BY enrollment_id;

    IF v_names.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No students enrolled in course ' || p_course_id);
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Roster for course ' || p_course_id || ':');

    v_key := v_names.FIRST;
    WHILE v_key IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE(v_names(v_key));
        v_key := v_names.NEXT(v_key);
    END LOOP;

    IF v_grades.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No grades recorded for this course.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Grades collected with BULK COLLECT: ' || v_grades.COUNT);

    FOR i IN 1 .. v_grades.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  Grade ' || i || ' : ' || v_grades(i));
        v_total := v_total + v_grades(i);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(
        'Average grade : ' || ROUND(v_total / v_grades.COUNT, 2)
    );
EXCEPTION
    WHEN OTHERS THEN
        IF c_roster%ISOPEN THEN
            CLOSE c_roster;
        END IF;
        RAISE;
END;
/
