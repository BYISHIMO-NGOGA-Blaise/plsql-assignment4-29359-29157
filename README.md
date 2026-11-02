# Group Assignment IV — Advanced Oracle PL/SQL

**Topic:** Records, Collections, Cursors, Bulk Processing, Stored Procedures,
Functions, and Exception Handling

**Course:** Database Development with PL/SQL (INSY 8311)
**Instructor:** Eric Maniraguha — eric.maniraguha@auca.ac.rw
**Teaching Assistant:** Afanyu Emmanuel

## Group Members

| Name | Student ID |
|------|------------|
| Blaise BYISHIMO NGOGA | 29359 |
| UWAYESU Samuel | 29157 |

> Public repository: `plsql-assignment4-29359-29157`.

---

## AI Use

An AI assistant (opencode) was used to help draft the SQL/PL/SQL scripts, tests,
and documentation. Both group members remain responsible for reviewing,
understanding, executing, and explaining all submitted code during the
presentation.

---

## Application Description

The project implements a **Student Registration and Grading System** for a
university. It manages students, courses, enrollments, and grades.

The application supports:

- Registering new students
- Enrolling new or existing students in courses
- Assigning and updating grades
- Removing enrollments
- Producing student, roster, and grade reports
- Calculating GPA and letter grades

All database operations are implemented through stored procedures and functions,
with exception handling for invalid input, missing records, duplicate data, and
bulk DML errors.

---

## Database Schema

```
STUDENTS ──< ENROLLMENTS >── COURSES
```

| Table | Columns |
|-------|---------|
| `students` | `student_id` (PK), `first_name`, `last_name`, `email` (unique) |
| `courses` | `course_id` (PK), `course_name`, `credits` |
| `enrollments` | `enrollment_id` (PK), `student_id` (FK), `course_id` (FK), `grade` |

Relationships and constraints:

- `fk_student` — an enrollment must reference an existing student.
- `fk_course` — an enrollment must reference an existing course.
- `ck_grade_range` — a grade must be `NULL` or between `0` and `100`.
- `uq_student_course` — a student cannot enroll twice in the same course.
- `enrollments_seq` — generates new `enrollment_id` values starting at `5`
  because the sample data uses IDs `1`–`4`.

Sample data:

```text
STUDENTS
1  John   Doe    john@gmail.com
2  Mary   Smith  mary@gmail.com
3  David  Brown  david@gmail.com

COURSES
101  Database Systems   3 credits
102  Java Programming   4 credits
103  Networks           3 credits

ENROLLMENTS
1  1  101  85
2  1  102  78
3  2  101  90
4  3  103  65
```

---

## Repository Structure

```text
plsql-assignment4-29359-29157/
│
├── README.md
├── .gitignore
├── 00_schema/
│   ├── 01_create_tables.sql
│   └── 02_insert_sample_data.sql
├── 01_procedures/
│   ├── add_bonus_marks.sql
│   ├── enroll_student.sql
│   ├── maintain_enrollment.sql
│   ├── show_course_report.sql
│   └── show_student_record.sql
├── 02_functions/
│   ├── calculate_gpa.sql
│   └── get_letter_grade.sql
├── 03_tests/
│   ├── test_success_cases.sql
│   └── test_error_cases.sql
├── screenshots/
│   ├── prompt 1.png
│   ├── prompt 2.png
│   ├── prompt 3.png
│   ├── prompt 4.png
│   ├── prompt 5.png
│   ├── prompt 6_1.png
│   ├── prompt 6_2.png
│   └── error.png
└── docs/
    └── IMPLEMENTATION_NOTES.md
```

---

## How to Run

Run the scripts from the project root in SQL*Plus or SQL Developer:

```sql
@00_schema/01_create_tables.sql
@00_schema/02_insert_sample_data.sql

@01_procedures/enroll_student.sql
@01_procedures/maintain_enrollment.sql
@01_procedures/show_student_record.sql
@01_procedures/show_course_report.sql
@01_procedures/add_bonus_marks.sql

@02_functions/calculate_gpa.sql
@02_functions/get_letter_grade.sql

@03_tests/test_success_cases.sql
@03_tests/test_error_cases.sql
```

`01_create_tables.sql` is re-runnable: it drops the project tables and sequence
before recreating them. Re-run it, then recompile the procedures/functions, to
reset the data for a clean demonstration.

`test_success_cases.sql` and `test_error_cases.sql` end with `ROLLBACK`, so they
do not permanently change the sample data. Sequence values are not rolled back,
so enrollment IDs can differ on repeated runs.

---

## Requirement Coverage

| PDF Requirement | Implementation |
|-----------------|----------------|
| Records — `%ROWTYPE` | `show_student_record` reads a full student row into `students%ROWTYPE`. |
| Records — user-defined | `show_student_record` also uses `TYPE student_rec IS RECORD (...)`. |
| Collections — nested table | `show_course_report` uses `TYPE grade_tab IS TABLE OF ...` with `BULK COLLECT`. |
| Collections — associative array | `show_course_report` uses `TYPE student_names IS TABLE OF ... INDEX BY PLS_INTEGER`. |
| Implicit cursor — INSERT | `enroll_student` inserts the student and enrollment, reporting `SQL%ROWCOUNT` and `SQL%FOUND`. |
| Implicit cursor — UPDATE | `maintain_enrollment('GRADE', ...)` reports `SQL%ROWCOUNT`, `SQL%FOUND`, and `SQL%NOTFOUND`. |
| Implicit cursor — DELETE | `maintain_enrollment('DELETE', ...)` reports `SQL%ROWCOUNT` and `SQL%NOTFOUND`. |
| Explicit cursor — `OPEN`/`FETCH`/`CLOSE` | `show_course_report` uses an explicit cursor and `%NOTFOUND`, `%ISOPEN`. |
| `BULK COLLECT` | `show_course_report` collects all course grades into a nested table in one round-trip. |
| `FORALL` | `add_bonus_marks` updates many enrollments in one DML operation. |
| Bulk DML error handling | `add_bonus_marks` uses `FORALL ... SAVE EXCEPTIONS` and `SQL%BULK_EXCEPTIONS` with `PRAGMA EXCEPTION_INIT(..., -24381)`. |
| Stored procedures with input/output | `enroll_student` has `IN` parameters and an `OUT` enrollment ID; `show_student_record` has two `OUT` parameters. |
| Functions | `calculate_gpa` and `get_letter_grade` are called from SQL. |
| Predefined exceptions | `NO_DATA_FOUND` and `TOO_MANY_ROWS` are demonstrated in error tests and `show_student_record`. |
| User-defined exception | `test_error_cases.sql` raises an `invalid_grade` exception with `RAISE`. |
| `RAISE_APPLICATION_ERROR` | Used by `enroll_student`, `maintain_enrollment`, `calculate_gpa`, `get_letter_grade`, and `add_bonus_marks`. |
| Error handling in procedures/functions | Duplicate data, missing students/courses/enrollments, invalid grades, invalid actions, and bulk DML failures are handled with meaningful messages. |

---

## Stored Procedures

| Procedure | Purpose | Key features |
|-----------|---------|--------------|
| `enroll_student` | Enrolls an existing student, or registers a new student and enrolls them | `INSERT`, `SQL%ROWCOUNT`, `SQL%FOUND`, `DUP_VAL_ON_INDEX`, `OUT` enrollment ID |
| `maintain_enrollment` | Updates a grade or deletes an enrollment | `UPDATE`, `DELETE`, `SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND`, grade validation |
| `show_student_record` | Prints and returns one student's details | `%ROWTYPE`, user-defined record, two `OUT` parameters, `NO_DATA_FOUND` |
| `show_course_report` | Prints a course roster plus grade statistics | Explicit cursor `OPEN`/`FETCH`/`CLOSE`, associative array, nested table, `BULK COLLECT` |
| `add_bonus_marks` | Adds bonus marks to all graded enrollments | `BULK COLLECT`, `FORALL ... SAVE EXCEPTIONS`, `SQL%BULK_EXCEPTIONS` |

---

## Functions

| Function | Returns | Notes |
|----------|---------|-------|
| `calculate_gpa(student_id)` | Average grade rounded to 2 decimals, or `NULL` when there are no graded enrollments | Raises `ORA-20006` if the student does not exist; errors are not hidden. |
| `get_letter_grade(grade)` | `A`, `B`, `C`, `D`, or `F` | Raises `ORA-20007` if the grade is `NULL` or outside `0`–`100`. |

Both functions are called directly from a SQL `SELECT` in
`03_tests/test_success_cases.sql`.

---

## Application Error Codes

| Code | Message |
|------|---------|
| `-20001` | Student not found; provide name and email to register |
| `-20002` | Student is already enrolled in this course |
| `-20003` | Course not found |
| `-20004` | Grade must be between 0 and 100 |
| `-20005` | Enrollment not found (update) |
| `-20006` | Student not found (GPA) |
| `-20007` | Grade must be between 0 and 100 (letter grade) |
| `-20008` | Enrollment not found (delete) |
| `-20010` | Bonus must be a positive number |
| `-20011` | Invalid maintenance action; use `GRADE` or `DELETE` |
| `-20013` | Student ID or email already exists |

---

## Test Results

### Success cases (`03_tests/test_success_cases.sql`)

```text
=== 1. Student record: %ROWTYPE, user-defined record, OUT ===
Student : John Doe
Email   : john@gmail.com
Record  : John Doe / john@gmail.com
V_NAME : John Doe
V_EMAIL : john@gmail.com

=== 2. Register and enroll a new student ===
1 student row inserted. SQL%FOUND is TRUE.
1 enrollment row inserted. Enrollment ID: 5
V_ID : 5
1 row updated. SQL%FOUND is TRUE.

=== 3. Enroll a student, update the grade, then delete ===
1 enrollment row inserted. Enrollment ID: 6
V_ID : 6
1 row updated. SQL%FOUND is TRUE.
1 row deleted.

=== 4. Course report: cursor, collections, BULK COLLECT ===
Roster for course 101:
1 - John Doe - grade: 85
2 - Mary Smith - grade: 90
10 - Peter Paul - grade: 70
Grades collected with BULK COLLECT: 3
Grade 1 : 85
Grade 2 : 90
Grade 3 : 70
Average grade : 81.67

=== 5. FORALL bulk update ===
5 row(s) updated with 5 bonus mark(s).

=== 6. Functions in SQL ===
STUDENT_ID     GPA LETTER_GRADE
---------- ------- ------------
         1   86.50 B
         2   95.00 A
         3   70.00 C
        10   75.00 C

=== Rollback test data ===
Rollback complete.
```

> `PL/SQL procedure successfully completed.` messages are omitted for brevity.

### Error cases (`03_tests/test_error_cases.sql`)

```text
=== 1. Student not found ===
ORA-20001: Student not found. Provide first name, last name, and email to register.

=== 2. Course not found ===
ORA-20003: Course not found

=== 3. Duplicate enrollment ===
ORA-20002: Student is already enrolled in this course

=== 4. Duplicate email ===
ORA-20013: Student ID or email already exists

=== 5. Grade above 100 ===
ORA-20004: Grade must be between 0 and 100

=== 6. Grade for an unknown enrollment ===
No enrollment updated. SQL%NOTFOUND is TRUE.
ORA-20005: Enrollment not found

=== 7. Delete an unknown enrollment ===
No enrollment deleted. SQL%NOTFOUND is TRUE.
ORA-20008: Enrollment not found

=== 8. Invalid action ===
ORA-20011: Invalid action. Use GRADE or DELETE

=== 9. GPA for an unknown student ===
ORA-20006: Student not found: 999

=== 10. Letter grade outside 0-100 ===
ORA-20007: Grade must be between 0 and 100

=== 11. Bulk DML errors ===
Bulk update completed with 2 error(s).
Enrollment 1 failed with ORA-2290
Enrollment 3 failed with ORA-2290
2 row(s) updated successfully.

=== 12. Invalid bonus ===
ORA-20010: Bonus must be a positive number

=== 13. NO_DATA_FOUND handled in show_student_record ===
Student not found.

=== 14. TOO_MANY_ROWS ===
More than one row returned.

=== 15. User-defined exception ===
Grade cannot exceed 100.

=== 16. Direct RAISE_APPLICATION_ERROR ===
ORA-20099: Demonstration of RAISE_APPLICATION_ERROR

=== Rollback bulk test changes ===
Rollback complete.
```

> The error test uses `WHENEVER SQLERROR CONTINUE`, so each expected error is
> printed and the script continues. SQL*Plus also prints `ORA-06512` stack lines;
> they are omitted here.

---

## Performance Considerations

Traditional row-by-row processing causes a context switch between SQL and PL/SQL
for every row. `BULK COLLECT` retrieves many rows at once, reducing context
switches. `FORALL` sends multiple DML statements to SQL in a single operation,
which significantly improves performance when processing large datasets.

`show_course_report` uses `BULK COLLECT` to load all course grades in one
round-trip. `add_bonus_marks` uses `BULK COLLECT` plus `FORALL` to update every graded
enrollment in one operation. The `SAVE EXCEPTIONS` clause allows successful rows
to complete even when individual rows fail, and `SQL%BULK_EXCEPTIONS` reports the
failing enrollment IDs and Oracle error codes.

The full explanation is in
[`docs/IMPLEMENTATION_NOTES.md`](docs/IMPLEMENTATION_NOTES.md).

---

## Screenshots

### 1. Student record — `%ROWTYPE`, user-defined record, `OUT`

![Prompt 1 — student record](<screenshots/prompt 1.png>)

### 2. Register and enroll a new student

![Prompt 2 — new student enrollment](<screenshots/prompt 2.png>)

### 3. Enroll a student, update the grade, then delete

![Prompt 3 — grade update and delete](<screenshots/prompt 3.png>)

### 4. Course report — cursor, collections, `BULK COLLECT`

![Prompt 4 — course report](<screenshots/prompt 4.png>)

### 5. `FORALL` bulk update

![Prompt 5 — bulk update](<screenshots/prompt 5.png>)

### 6. Functions in SQL

![Prompt 6 part 1 — functions](<screenshots/prompt 6_1.png>)

![Prompt 6 part 2 — functions](<screenshots/prompt 6_2.png>)

### Error cases

![Error cases — expected ORA errors](<screenshots/error.png>)

---

## Final Checklist

- [x] Application description and requirements in `README.md`
- [x] Tables, relationships, and constraints created
- [x] Sample data inserted
- [x] Records — user-defined and `%ROWTYPE` used
- [x] Collections — associative array and nested table used
- [x] Implicit cursors with `SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND`
- [x] Explicit cursors — `OPEN`/`FETCH`/`CLOSE`
- [x] `BULK COLLECT` and `FORALL` with bulk DML error handling
- [x] Stored procedures and functions compile successfully
- [x] Predefined exceptions, user-defined exception, and `RAISE_APPLICATION_ERROR`
- [x] Success and error test cases completed
- [x] Implementation and performance notes completed
- [x] Screenshots added to `screenshots/`
- [x] Group of exactly two students confirmed
- [ ] Public GitHub repository named `plsql-assignment4-29359-29157`
- [ ] Both members have meaningful commits
- [ ] GitHub link submitted through the Google Form
- [ ] Both members prepared for the presentation and individual questions
