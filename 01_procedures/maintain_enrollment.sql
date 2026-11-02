SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE maintain_enrollment (
    p_action        IN VARCHAR2,
    p_enrollment_id IN NUMBER,
    p_grade         IN NUMBER DEFAULT NULL
) AS
BEGIN
    IF UPPER(p_action) = 'GRADE' THEN
        IF p_grade IS NULL OR p_grade < 0 OR p_grade > 100 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Grade must be between 0 and 100');
        END IF;

        UPDATE enrollments
           SET grade = p_grade
         WHERE enrollment_id = p_enrollment_id;

        IF SQL%FOUND THEN
            DBMS_OUTPUT.PUT_LINE(
                SQL%ROWCOUNT || ' row updated. SQL%FOUND is TRUE.'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE(
                'No enrollment updated. SQL%NOTFOUND is TRUE.'
            );
            RAISE_APPLICATION_ERROR(-20005, 'Enrollment not found');
        END IF;
    ELSIF UPPER(p_action) = 'DELETE' THEN
        DELETE FROM enrollments
         WHERE enrollment_id = p_enrollment_id;

        IF SQL%NOTFOUND THEN
            DBMS_OUTPUT.PUT_LINE(
                'No enrollment deleted. SQL%NOTFOUND is TRUE.'
            );
            RAISE_APPLICATION_ERROR(-20008, 'Enrollment not found');
        ELSE
            DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' row deleted.');
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(
            -20011,
            'Invalid action. Use GRADE or DELETE'
        );
    END IF;
END;
/
