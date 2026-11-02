SET SERVEROUTPUT ON

CREATE OR REPLACE PROCEDURE add_bonus_marks (
    p_bonus IN NUMBER
) AS
    TYPE id_tab IS TABLE OF enrollments.enrollment_id%TYPE;

    v_ids id_tab;

    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
BEGIN
    IF p_bonus IS NULL OR p_bonus <= 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Bonus must be a positive number');
    END IF;

    SELECT enrollment_id
      BULK COLLECT INTO v_ids
      FROM enrollments
     WHERE grade IS NOT NULL;

    IF v_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No graded enrollments to update.');
        RETURN;
    END IF;

    FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
        UPDATE enrollments
           SET grade = grade + p_bonus
         WHERE enrollment_id = v_ids(i);

    DBMS_OUTPUT.PUT_LINE(
        SQL%ROWCOUNT || ' row(s) updated with ' || p_bonus || ' bonus mark(s).'
    );
EXCEPTION
    WHEN e_bulk_errors THEN
        DBMS_OUTPUT.PUT_LINE(
            'Bulk update completed with ' ||
            SQL%BULK_EXCEPTIONS.COUNT || ' error(s).'
        );

        FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE(
                '  Enrollment ' ||
                v_ids(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX) ||
                ' failed with ORA-' ||
                ABS(SQL%BULK_EXCEPTIONS(i).ERROR_CODE)
            );
        END LOOP;

        DBMS_OUTPUT.PUT_LINE(
            (v_ids.COUNT - SQL%BULK_EXCEPTIONS.COUNT) ||
            ' row(s) updated successfully.'
        );
END;
/
