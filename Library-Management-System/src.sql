-- 1. Database Cleanup
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE issue_return';
    EXECUTE IMMEDIATE 'DROP TABLE books';
    EXECUTE IMMEDIATE 'DROP TABLE members';
    EXECUTE IMMEDIATE 'DROP SEQUENCE mem_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE book_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE issue_seq';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- 2. Sequences
CREATE SEQUENCE mem_seq START WITH 101 INCREMENT BY 1;
CREATE SEQUENCE book_seq START WITH 5001 INCREMENT BY 1;
CREATE SEQUENCE issue_seq START WITH 9001 INCREMENT BY 1;

-- 3. Tables
CREATE TABLE members (
    member_id NUMBER PRIMARY KEY,
    full_name VARCHAR2(100) NOT NULL,
    join_date DATE DEFAULT SYSDATE,
    active_status VARCHAR2(1) DEFAULT 'Y'
);

CREATE TABLE books (
    book_id NUMBER PRIMARY KEY,
    title VARCHAR2(150) NOT NULL,
    author VARCHAR2(100),
    status VARCHAR2(15) DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'ISSUED')),
    added_date DATE DEFAULT SYSDATE
);

CREATE TABLE issue_return (
    issue_id NUMBER PRIMARY KEY,
    book_id NUMBER REFERENCES books(book_id),
    member_id NUMBER REFERENCES members(member_id),
    issue_date DATE DEFAULT SYSDATE,
    due_date DATE,
    return_date DATE,
    fine_amount NUMBER(10, 2) DEFAULT 0
);

-- 4. Trigger
CREATE OR REPLACE TRIGGER trg_book_status
AFTER INSERT OR UPDATE ON issue_return
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE books SET status = 'ISSUED' WHERE book_id = :NEW.book_id;
    ELSIF UPDATING AND :NEW.return_date IS NOT NULL THEN
        UPDATE books SET status = 'AVAILABLE' WHERE book_id = :NEW.book_id;
    END IF;
END;
/

-- 5. Package Specification 
CREATE OR REPLACE PACKAGE library_pkg AS
    c_fine_per_day CONSTANT NUMBER := 2.00;
    c_issue_days   CONSTANT NUMBER := 14; 
    
    e_book_unavailable EXCEPTION;
    
    PROCEDURE add_member(p_name VARCHAR2);
    PROCEDURE add_book(p_title VARCHAR2, p_author VARCHAR2);
    PROCEDURE issue_book(p_book_id NUMBER, p_mem_id NUMBER);
    PROCEDURE return_book(p_issue_id NUMBER);
    PROCEDURE overdue_report;
END library_pkg;
/

-- 6. Package Body
CREATE OR REPLACE PACKAGE BODY library_pkg AS

    PROCEDURE add_member(p_name VARCHAR2) IS
    BEGIN
        INSERT INTO members (member_id, full_name) VALUES (mem_seq.NEXTVAL, p_name);
    END;

    PROCEDURE add_book(p_title VARCHAR2, p_author VARCHAR2) IS
    BEGIN
        INSERT INTO books (book_id, title, author) VALUES (book_seq.NEXTVAL, p_title, p_author);
    END;

    FUNCTION calculate_fine(p_due_date DATE, p_return_date DATE) RETURN NUMBER IS
        v_days_late NUMBER;
    BEGIN
        IF p_return_date <= p_due_date THEN
            RETURN 0;
        ELSE
            v_days_late := TRUNC(p_return_date) - TRUNC(p_due_date);
            RETURN v_days_late * c_fine_per_day;
        END IF;
    END;

    PROCEDURE issue_book(p_book_id NUMBER, p_mem_id NUMBER) IS
        v_status VARCHAR2(15);
    BEGIN
        SELECT status INTO v_status FROM books WHERE book_id = p_book_id;
        
        IF v_status = 'ISSUED' THEN
            RAISE e_book_unavailable;
        ELSE
            INSERT INTO issue_return (issue_id, book_id, member_id, issue_date, due_date)
            VALUES (issue_seq.NEXTVAL, p_book_id, p_mem_id, SYSDATE, SYSDATE + c_issue_days);
            DBMS_OUTPUT.PUT_LINE('Book ' || p_book_id || ' issued successfully.');
        END IF;
    EXCEPTION
        WHEN e_book_unavailable THEN
            DBMS_OUTPUT.PUT_LINE('Error: Book ' || p_book_id || ' is currently unavailable.');
    END;

    PROCEDURE return_book(p_issue_id NUMBER) IS
        v_due_date DATE;
        v_fine NUMBER;
    BEGIN
        SELECT due_date INTO v_due_date 
        FROM issue_return 
        WHERE issue_id = p_issue_id AND return_date IS NULL;
        
        v_fine := calculate_fine(v_due_date, SYSDATE);
        
        UPDATE issue_return 
        SET return_date = SYSDATE,
            fine_amount = v_fine
        WHERE issue_id = p_issue_id;
        
        DBMS_OUTPUT.PUT_LINE('Book Returned. Fine Due: $' || v_fine);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: Invalid Issue ID or Book already returned.');
    END;

    PROCEDURE overdue_report IS
        CURSOR c_overdue IS
            SELECT m.full_name, b.title, i.due_date, 
                   TRUNC(SYSDATE) - TRUNC(i.due_date) as days_late
            FROM issue_return i
            JOIN books b ON i.book_id = b.book_id
            JOIN members m ON i.member_id = m.member_id
            WHERE i.return_date IS NULL 
            AND i.due_date < SYSDATE;
        r_rec c_overdue%ROWTYPE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- OVERDUE BOOK REPORT ---');
        OPEN c_overdue;
        LOOP
            FETCH c_overdue INTO r_rec;
            EXIT WHEN c_overdue%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Member: ' || r_rec.full_name || ' | Days Late: ' || r_rec.days_late);
        END LOOP;
        CLOSE c_overdue;
    END;
END library_pkg;
/

-- 7. Optimized Testing Block
SET SERVEROUTPUT ON;
DECLARE
    v_book_id NUMBER;
    v_mem_id NUMBER;
    v_issue_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- START TEST ---');

    -- 1. Setup Data
    library_pkg.add_member('Harry Potter');
    library_pkg.add_book('Advanced Potions', 'Libatius B.');
    
    COMMIT; -- Save Data

    -- Fetch IDs safely (Better than CURRVAL for stability)
    SELECT member_id INTO v_mem_id FROM members WHERE full_name = 'Harry Potter';
    SELECT book_id INTO v_book_id FROM books WHERE title = 'Advanced Potions';

    -- 2. Issue the Book
    library_pkg.issue_book(v_book_id, v_mem_id);
    
    -- Get the Issue ID safely
    SELECT issue_id INTO v_issue_id FROM issue_return WHERE book_id = v_book_id AND return_date IS NULL;

    -- 3. Attempt Duplicate Issue
    library_pkg.issue_book(v_book_id, v_mem_id);

    -- 4. Simulate Past Date (Manual Hack)
    UPDATE issue_return SET due_date = SYSDATE - 5 WHERE issue_id = v_issue_id;
    
    COMMIT; -- CRITICAL FIX: Commit the manual update to release locks before the procedure tries to update again

    -- 5. Report
    library_pkg.overdue_report;

    -- 6. Return
    library_pkg.return_book(v_issue_id);
    
    COMMIT; -- Final Commit
    DBMS_OUTPUT.PUT_LINE('--- END TEST ---');
END;
/

-- 8. Verify
SELECT * FROM books;
SELECT * FROM issue_return;