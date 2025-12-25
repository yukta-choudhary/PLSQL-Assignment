-- Database Cleanup (DDL)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE results';
    EXECUTE IMMEDIATE 'DROP TABLE marks';
    EXECUTE IMMEDIATE 'DROP TABLE subjects';
    EXECUTE IMMEDIATE 'DROP TABLE students';
    EXECUTE IMMEDIATE 'DROP SEQUENCE stu_seq';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Create Sequences & Tables
CREATE SEQUENCE stu_seq START WITH 1001 INCREMENT BY 1;

CREATE TABLE students (
    student_id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    batch_year NUMBER(4)
);

CREATE TABLE subjects (
    subject_id VARCHAR2(10) PRIMARY KEY,
    subject_name VARCHAR2(50),
    max_marks NUMBER(3) DEFAULT 100,
    pass_marks NUMBER(3) DEFAULT 40
);

CREATE TABLE marks (
    student_id NUMBER REFERENCES students(student_id),
    subject_id VARCHAR2(10) REFERENCES subjects(subject_id),
    score_obtained NUMBER(3),
    PRIMARY KEY (student_id, subject_id)
);

CREATE TABLE results (
    student_id NUMBER PRIMARY KEY REFERENCES students(student_id),
    total_score NUMBER(5),
    percentage NUMBER(5, 2),
    grade VARCHAR2(2),
    result_status VARCHAR2(10),
    class_rank NUMBER(3)
);

-- Create Trigger (With Error Handling)
CREATE OR REPLACE TRIGGER trg_check_max_marks
BEFORE INSERT OR UPDATE ON marks
FOR EACH ROW
DECLARE
    v_max NUMBER;
BEGIN
    -- Fetch max marks for the subject being inserted
    SELECT max_marks INTO v_max 
    FROM subjects 
    WHERE subject_id = :NEW.subject_id;
    
    -- Check constraint
    IF :NEW.score_obtained > v_max THEN
        RAISE_APPLICATION_ERROR(-20001, 'Score exceeds maximum marks for this subject.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- This handles the specific error you were facing
        RAISE_APPLICATION_ERROR(-20002, 'Subject ID ' || :NEW.subject_id || ' does not exist. Cannot verify max marks.');
END;
/

--  Create Package Specification
CREATE OR REPLACE PACKAGE exam_pkg AS
    PROCEDURE add_student(p_name VARCHAR2, p_batch NUMBER);
    PROCEDURE enter_mark(p_stu_id NUMBER, p_sub_id VARCHAR2, p_score NUMBER);
    PROCEDURE process_results; 
END exam_pkg;
/

-- 5. Create Package Body
CREATE OR REPLACE PACKAGE BODY exam_pkg AS

    FUNCTION get_grade(p_pct NUMBER) RETURN VARCHAR2 IS
    BEGIN
        IF p_pct >= 90 THEN RETURN 'A+';
        ELSIF p_pct >= 80 THEN RETURN 'A';
        ELSIF p_pct >= 70 THEN RETURN 'B';
        ELSIF p_pct >= 60 THEN RETURN 'C';
        ELSIF p_pct >= 50 THEN RETURN 'D';
        ELSE RETURN 'F';
        END IF;
    END;

    PROCEDURE add_student(p_name VARCHAR2, p_batch NUMBER) IS
    BEGIN
        INSERT INTO students VALUES (stu_seq.NEXTVAL, p_name, p_batch);
    END;

    PROCEDURE enter_mark(p_stu_id NUMBER, p_sub_id VARCHAR2, p_score NUMBER) IS
    BEGIN
        INSERT INTO marks VALUES (p_stu_id, p_sub_id, p_score);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE marks SET score_obtained = p_score 
            WHERE student_id = p_stu_id AND subject_id = p_sub_id;
    END;

    PROCEDURE process_results IS
        CURSOR c_student_totals IS
            SELECT m.student_id, 
                   SUM(m.score_obtained) as total_obt, 
                   SUM(s.max_marks) as total_max,
                   COUNT(CASE WHEN m.score_obtained < s.pass_marks THEN 1 END) as failed_subjects
            FROM marks m
            JOIN subjects s ON m.subject_id = s.subject_id
            GROUP BY m.student_id;
            
        v_pct NUMBER(5,2);
        v_status VARCHAR2(10);
        v_grade VARCHAR2(2);
    BEGIN
        FOR r IN c_student_totals LOOP
            IF r.failed_subjects > 0 THEN
                v_status := 'FAIL';
                v_grade := 'F';
            ELSE
                v_status := 'PASS';
                -- Protect against division by zero if max marks are missing
                IF r.total_max > 0 THEN
                    v_pct := (r.total_obt / r.total_max) * 100;
                ELSE
                    v_pct := 0;
                END IF;
                v_grade := get_grade(v_pct);
            END IF;
            
            DELETE FROM results WHERE student_id = r.student_id;
            
            INSERT INTO results (student_id, total_score, percentage, grade, result_status)
            VALUES (r.student_id, r.total_obt, v_pct, v_grade, v_status);
        END LOOP;
        
        DECLARE
            CURSOR c_rank IS
                SELECT student_id FROM results 
                WHERE result_status = 'PASS' ORDER BY total_score DESC;
            v_rank NUMBER := 1;
        BEGIN
            FOR r_rank IN c_rank LOOP
                UPDATE results SET class_rank = v_rank WHERE student_id = r_rank.student_id;
                v_rank := v_rank + 1;
            END LOOP;
        END;
        DBMS_OUTPUT.PUT_LINE('Result processing completed.');
    END;
END exam_pkg;
/

-- Setup + Testing
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- STARTING EXECUTION ---');

    -- Insert Subjects (Must happen before marks entry)
    -- Deleting first to prevent duplicates if run multiple times
    DELETE FROM subjects; 
    INSERT INTO subjects VALUES ('CS101', 'Database', 100, 40);
    INSERT INTO subjects VALUES ('CS102', 'Algorithms', 100, 40);
    INSERT INTO subjects VALUES ('MA101', 'Maths', 50, 20);
    
    COMMIT; -- Ensure subjects are saved before trigger fires

    -- Add Students
    exam_pkg.add_student('Riya Topper', 2025);
    exam_pkg.add_student('Asha Average', 2025);
    exam_pkg.add_student('Ram Fail', 2025);
    
    COMMIT; 

    -- Enter Marks (Now safe because Subjects exist)
    -- Using IDs 1001, 1002, 1003 assuming sequence started at 1001
    
    -- John (Topper)
    exam_pkg.enter_mark(1001, 'CS101', 95);
    exam_pkg.enter_mark(1001, 'CS102', 88);
    exam_pkg.enter_mark(1001, 'MA101', 48);
    
    -- Alice (Average)
    exam_pkg.enter_mark(1002, 'CS101', 60);
    exam_pkg.enter_mark(1002, 'CS102', 65);
    exam_pkg.enter_mark(1002, 'MA101', 30);
    
    -- Bob (Fails Maths)
    exam_pkg.enter_mark(1003, 'CS101', 50);
    exam_pkg.enter_mark(1003, 'CS102', 55);
    exam_pkg.enter_mark(1003, 'MA101', 10); 
    
    --Results
    exam_pkg.process_results;
    
    DBMS_OUTPUT.PUT_LINE('--- EXECUTION FINISHED ---');
END;
/

-- 7. Verify Output
SELECT s.name, r.total_score, r.percentage, r.grade, r.result_status, r.class_rank
FROM results r
JOIN students s ON r.student_id = s.student_id
ORDER BY r.class_rank NULLS LAST;