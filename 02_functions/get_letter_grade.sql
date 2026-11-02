SET SERVEROUTPUT ON

CREATE OR REPLACE FUNCTION get_letter_grade (
    p_grade IN NUMBER
) RETURN VARCHAR2 IS
BEGIN
    IF p_grade IS NULL OR p_grade < 0 OR p_grade > 100 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Grade must be between 0 and 100');
    END IF;

    IF p_grade >= 90 THEN
        RETURN 'A';
    ELSIF p_grade >= 80 THEN
        RETURN 'B';
    ELSIF p_grade >= 70 THEN
        RETURN 'C';
    ELSIF p_grade >= 60 THEN
        RETURN 'D';
    ELSE
        RETURN 'F';
    END IF;
END;
/
