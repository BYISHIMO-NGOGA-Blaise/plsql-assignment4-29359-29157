# Student Registration and Grading System

**Course:** Database Development with PL/SQL (INSY 8311)  
**Assignment:** Group Assignment IV — Records, Collections, Cursors, Bulk Processing, Stored Procedures, Functions, and Exception Handling  
**Instructor:** Eric Maniraguha — eric.maniraguha@auca.ac.rw  
**Teaching Assistant:** Afanyu Emmanuel

## Team

| Name | Student ID |
|------|------------|
| BYISHIMO NGOGA Blaise | 29359 |
| UWAYESU Samuel | 29157 |

**Repository:** [plsql-assignment4-29359-29157](https://github.com/BYISHIMO-NGOGA-Blaise/plsql-assignment4-29359-29157)

## Overview

This project implements a student registration and grading system in Oracle
PL/SQL. It manages students, courses, enrollments, and grades through stored
procedures and functions.

The system supports:

- Registering new students
- Enrolling new or existing students in courses
- Assigning, updating, and validating grades
- Removing enrollments
- Producing student, course-roster, and grade reports
- Calculating GPA and letter grades

All application logic is implemented in stored objects. The test scripts only
invoke those objects and do not contain business logic.

## Database Schema

```text
STUDENTS ──< ENROLLMENTS >── COURSES
```

| Table | Columns |
|-------|---------|
| `students` | `student_id` (PK), `first_name`, `last_name`, `email` (unique) |
| `courses` | `course_id` (PK), `course_name`, `credits` |
| `enrollments` | `enrollment_id` (PK), `student_id` (FK), `course_id` (FK), `grade` |

Constraints:

- `fk_student` — an enrollment must reference an existing student.
- `fk_course` — an enrollment must reference an existing course.
- `ck_grade_range` — a grade must be `NULL` or between `0` and `100`.
- `uq_student_course` — a student cannot enroll twice in the same course.
- `enrollments_seq` — generates enrollment IDs starting at `5`, because the
  seed data uses IDs `1`–`4`.

The seed data contains three students, three courses, and four enrollments. See
[`00_schema/02_insert_sample_data.sql`](00_schema/02_insert_sample_data.sql).

## Repository Layout

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

## Build and Run

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
before recreating them. Re-run it, then recompile the stored objects, to reset
the demonstration data.

Both test scripts end with `ROLLBACK`, so they do not permanently change the
seed data. Sequence values are not rolled back, so enrollment IDs can differ on
repeated runs.

All scripts were compiled and executed successfully on Oracle Database 21c.

## Stored Objects

| Object | Type | Description |
|--------|------|-------------|
| `enroll_student` | Procedure | Enrolls an existing student, or registers a new student and enrolls them. Returns the new enrollment ID through an `OUT` parameter. |
| `maintain_enrollment` | Procedure | Updates a grade (`GRADE`) or deletes an enrollment (`DELETE`) and reports the affected-row status. |
| `show_student_record` | Procedure | Reads one student with `%ROWTYPE`, copies the data into a user-defined record, and returns the name and email through `OUT` parameters. |
| `show_course_report` | Procedure | Prints a course roster and grade statistics using an explicit cursor, an associative array, a nested table, and `BULK COLLECT`. |
| `add_bonus_marks` | Procedure | Adds bonus marks to all graded enrollments using `BULK COLLECT` and `FORALL ... SAVE EXCEPTIONS`. |
| `calculate_gpa` | Function | Returns the average grade for a student, rounded to two decimals, or `NULL` when there are no graded enrollments. |
| `get_letter_grade` | Function | Maps a numeric grade to `A`, `B`, `C`, `D`, or `F`. |

## Requirement Coverage

| Requirement | Implementation |
|-------------|----------------|
| `%ROWTYPE` record | `show_student_record` |
| User-defined record | `show_student_record` |
| Nested table collection | `show_course_report` |
| Associative array collection | `show_course_report` |
| Implicit cursor `INSERT` | `enroll_student` |
| Implicit cursor `UPDATE` | `maintain_enrollment` |
| Implicit cursor `DELETE` | `maintain_enrollment` |
| Cursor attributes | `SQL%ROWCOUNT`, `SQL%FOUND`, and `SQL%NOTFOUND` in `enroll_student` and `maintain_enrollment` |
| Explicit cursor | `OPEN`/`FETCH`/`CLOSE` in `show_course_report` |
| `BULK COLLECT` | `show_course_report` and `add_bonus_marks` |
| `FORALL` | `add_bonus_marks` |
| Bulk DML error handling | `FORALL ... SAVE EXCEPTIONS` and `SQL%BULK_EXCEPTIONS` in `add_bonus_marks` |
| `IN` and `OUT` parameters | `enroll_student` and `show_student_record` |
| Functions | `calculate_gpa` and `get_letter_grade` |
| Predefined exceptions | `NO_DATA_FOUND` in `show_student_record`; `TOO_MANY_ROWS` in the error tests |
| User-defined exception | `invalid_grade` in `test_error_cases.sql` |
| `RAISE_APPLICATION_ERROR` | Used by the procedures and functions for application-level validation |
| Bulk DML errors | Reported with `PRAGMA EXCEPTION_INIT(..., -24381)` and `SQL%BULK_EXCEPTIONS` |

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

## Testing

Two scripts are provided:

- `03_tests/test_success_cases.sql` exercises records, collections, cursors,
  bulk processing, procedures, and functions.
- `03_tests/test_error_cases.sql` triggers each validation and exception path.
  It uses `WHENEVER SQLERROR CONTINUE` so every expected error is displayed and
  the script continues.

Representative output is captured in the screenshots below.

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

## Performance Considerations

Row-by-row processing causes a SQL-to-PL/SQL context switch for every row.
`BULK COLLECT` retrieves many rows in one operation, and `FORALL` sends multiple
DML statements to SQL together. These techniques reduce context switches and
improve performance when processing large datasets.

`show_course_report` uses `BULK COLLECT` to load all course grades in one
round-trip. `add_bonus_marks` uses `BULK COLLECT` plus `FORALL` to update every
graded enrollment in one operation. `SAVE EXCEPTIONS` allows successful rows to
complete even when individual rows fail, and `SQL%BULK_EXCEPTIONS` reports the
failing enrollment IDs and Oracle error codes.

The full design and performance discussion is in
[`docs/IMPLEMENTATION_NOTES.md`](docs/IMPLEMENTATION_NOTES.md).

## Development Note

Some SQL/PL/SQL scripts, tests, and documentation were drafted with AI assistance
(opencode). Both group members are responsible for reviewing, executing, and
explaining the final artifacts during the presentation.
