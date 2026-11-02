SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE show_student_record (
    p_student_id IN  NUMBER,
    p_full_name  OUT VARCHAR2,
    p_email      OUT VARCHAR2
) AS
    v_student students%ROWTYPE;

    TYPE student_rec IS RECORD (
        full_name VARCHAR2(100),
        email     VARCHAR2(100)
    );

    v_rec student_rec;
BEGIN
    SELECT *
      INTO v_student
      FROM students
     WHERE student_id = p_student_id;

    v_rec.full_name := v_student.first_name || ' ' || v_student.last_name;
    v_rec.email     := v_student.email;

    p_full_name := v_rec.full_name;
    p_email     := v_rec.email;

    DBMS_OUTPUT.PUT_LINE('Student : ' || v_student.first_name || ' ' || v_student.last_name);
    DBMS_OUTPUT.PUT_LINE('Email   : ' || v_student.email);
    DBMS_OUTPUT.PUT_LINE('Record  : ' || v_rec.full_name || ' / ' || v_rec.email);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_full_name := NULL;
        p_email     := NULL;
        DBMS_OUTPUT.PUT_LINE('Student not found.');
END;
/
