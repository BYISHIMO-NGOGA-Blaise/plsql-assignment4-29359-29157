SET DEFINE OFF

INSERT INTO students VALUES (1, 'John',  'Doe',   'john@gmail.com');
INSERT INTO students VALUES (2, 'Mary',  'Smith', 'mary@gmail.com');
INSERT INTO students VALUES (3, 'David', 'Brown', 'david@gmail.com');

INSERT INTO courses VALUES (101, 'Database Systems', 3);
INSERT INTO courses VALUES (102, 'Java Programming', 4);
INSERT INTO courses VALUES (103, 'Networks', 3);

INSERT INTO enrollments VALUES (1, 1, 101, 85);
INSERT INTO enrollments VALUES (2, 1, 102, 78);
INSERT INTO enrollments VALUES (3, 2, 101, 90);
INSERT INTO enrollments VALUES (4, 3, 103, 65);

COMMIT;
