# Implementation Notes — Student Registration and Grading System

## 1. Application design

The application models a university registration and grading process with three
base tables: `students`, `courses`, and `enrollments`. `enrollments` is the
junction table between students and courses and also stores the grade.

The schema is split into two scripts:

- `00_schema/01_create_tables.sql` drops and recreates the tables, constraints,
  and sequence so the demonstration can start from a clean state.
- `00_schema/02_insert_sample_data.sql` inserts the seed students, courses, and
  enrollments and commits them.

The application logic is kept in five stored procedures and two functions. The
test scripts only call those stored objects; they do not contain the application
logic.

## 2. Why the procedures are grouped

The PDF requires records, collections, implicit cursors, explicit cursors, and
bulk processing to be integrated into stored procedures or functions. Instead of
creating one small procedure per concept, related operations are grouped into
meaningful business operations:

| Stored object | Concepts combined |
|---------------|-------------------|
| `enroll_student` | INSERT of a student and enrollment, `OUT` parameter, `SQL%ROWCOUNT`, `SQL%FOUND`, `DUP_VAL_ON_INDEX` |
| `maintain_enrollment` | `UPDATE`, `DELETE`, `SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND`, grade validation |
| `show_student_record` | `%ROWTYPE`, user-defined record, two `OUT` parameters, `NO_DATA_FOUND` |
| `show_course_report` | Explicit cursor `OPEN`/`FETCH`/`CLOSE`, associative array, nested table, `BULK COLLECT` |
| `add_bonus_marks` | `BULK COLLECT`, `FORALL ... SAVE EXCEPTIONS`, `SQL%BULK_EXCEPTIONS` |
| `calculate_gpa` | Function called from SQL, validation, `RAISE_APPLICATION_ERROR` |
| `get_letter_grade` | Function called from SQL, grade validation, `RAISE_APPLICATION_ERROR` |

Grouping the logic this way reduces the number of procedures while keeping every
required concept visible in stored code.

## 3. Records

`show_student_record` declares `v_student students%ROWTYPE` and fetches an entire
student row with `SELECT *`. `%ROWTYPE` keeps the record in sync with the table
definition and avoids listing every column.

The same procedure also declares a user-defined record with only the fields the
report needs:

```sql
TYPE student_rec IS RECORD (
    full_name VARCHAR2(100),
    email     VARCHAR2(100)
);
```

The values from the `%ROWTYPE` record are copied into the user-defined record,
and then into the two `OUT` parameters. This demonstrates both record types and
output parameters in one procedure.

## 4. Collections

`show_course_report` uses a nested table for grades:

```sql
TYPE grade_tab IS TABLE OF enrollments.grade%TYPE;
```

The grades are loaded with `BULK COLLECT`, processed with a numeric `FOR` loop,
and averaged.

The same procedure uses an associative array indexed by `PLS_INTEGER` for the
roster:

```sql
TYPE student_names IS TABLE OF VARCHAR2(150) INDEX BY PLS_INTEGER;
```

The explicit cursor fetches each student into the array, and the procedure walks
the array with `FIRST` and `NEXT`. This shows that collection keys do not have to
be consecutive.

## 5. Implicit cursors

Implicit cursor attributes are demonstrated across the three DML operations:

| Procedure | DML | Attributes |
|-----------|-----|------------|
| `enroll_student` | `INSERT` student and enrollment | `SQL%ROWCOUNT`, `SQL%FOUND` |
| `maintain_enrollment` with action `GRADE` | `UPDATE` | `SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND` |
| `maintain_enrollment` with action `DELETE` | `DELETE` | `SQL%ROWCOUNT`, `SQL%NOTFOUND` |

`enroll_student` can enroll an existing student, or register a new student when
first name, last name, and email are supplied. It validates the course before
inserting anything. A duplicate student ID or email is caught by
`DUP_VAL_ON_INDEX`; a duplicate enrollment is converted into `ORA-20002`.

`maintain_enrollment` converts "no row affected" into
`RAISE_APPLICATION_ERROR` messages instead of silently reporting success.

## 6. Explicit cursors

`show_course_report` uses the full explicit cursor pattern:

```sql
OPEN c_roster;
LOOP
    FETCH c_roster INTO v_row;
    EXIT WHEN c_roster%NOTFOUND;
    ...
END LOOP;
CLOSE c_roster;
```

The exception handler also closes the cursor if it is still open when an error
occurs. The PDF accepts `OPEN`/`FETCH`/`CLOSE` or a cursor `FOR` loop, so the
explicit form is sufficient.

## 7. Bulk processing and performance

Traditional row-by-row processing causes a context switch between SQL and PL/SQL
for every row. `BULK COLLECT` retrieves many rows at once, reducing context
switches. `FORALL` sends multiple DML statements to SQL in a single operation,
which significantly improves performance when processing large datasets.

In this project:

- `show_course_report` uses `BULK COLLECT` to fetch all grades for a course in
  one SQL round-trip instead of fetching one row at a time.
- `add_bonus_marks` uses `BULK COLLECT` to gather enrollment IDs and `FORALL` to
  update every graded enrollment in one DML operation.

For a table with thousands of enrollments, these techniques replace thousands of
PL/SQL-to-SQL switches with a small, fixed number of calls.

## 8. Bulk DML error handling

`add_bonus_marks` uses:

```sql
FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
    UPDATE enrollments
       SET grade = grade + p_bonus
     WHERE enrollment_id = v_ids(i);
```

The `SAVE EXCEPTIONS` clause lets successful rows complete even if some rows
fail. The procedure declares:

```sql
e_bulk_errors EXCEPTION;
PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
```

and handles `e_bulk_errors` by walking `SQL%BULK_EXCEPTIONS`. For each failure it
prints the enrollment ID from `v_ids(ERROR_INDEX)` and the Oracle error code from
`ERROR_CODE`. It then reports how many rows succeeded.

The error test calls `add_bonus_marks(20)` against the sample data. Two grades
would exceed 100 and violate `ck_grade_range`, so the output shows two failures
and two successful updates. The test rolls back afterwards.

## 9. Functions and error behaviour

`calculate_gpa` checks that the student exists and raises `ORA-20006` if not. It
returns `NULL` when the student has no graded enrollments, because `AVG` returns
`NULL` for an empty set. Returning `NULL` is clearer than returning `0`, which
would incorrectly look like a real GPA. Unexpected errors are not swallowed, so
callers are not misled.

`get_letter_grade` validates the input and raises `ORA-20007` for a `NULL` grade
or a value outside `0`–`100`. For valid grades it maps the score to
`A`/`B`/`C`/`D`/`F`.

Both functions are called from a SQL `SELECT` in the success test, demonstrating
that they work inside SQL as well as in PL/SQL.

## 10. Constraints and transaction behaviour

- `fk_student` and `fk_course` protect referential integrity.
- `ck_grade_range` enforces `0`–`100` at the database level.
- `uq_student_course` prevents duplicate enrollment.
- `enrollments_seq` starts at `5` because the sample data already uses IDs
  `1`–`4`.

The stored procedures do not commit. The caller controls the transaction, which
keeps the procedures reusable in larger operations. The test scripts end with
`ROLLBACK` so they can be rerun without permanently changing the sample data.
Sequence values are not transactional, so enrollment IDs may be higher after
repeated test runs.
