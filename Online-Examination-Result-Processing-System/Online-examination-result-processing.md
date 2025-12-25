**Project Title: Online Examination Result Processing System**

Description: A PL/SQL-based backend system designed to manage student examinations, process marks, calculate grades, and generate class rankings automatically.



 ***Key Features***

* Student \& Subject Management: 



&nbsp;		Supports registering new students with auto-generated IDs.



&nbsp;		Flexible subject configuration including specific Maximum Marks and Pass Marks thresholds per subject.



* Smart Marks Entry:



&nbsp;		Records student scores for specific subjects.



&nbsp;		 Automatically updates the score if a mark entry already exists for a student/subject pair, preventing duplicate errors.



* Automated Validation:



&nbsp;		Prevents data entry errors where the entered score exceeds the subject's maximum possible marks (e.g., cannot enter 105 in a 100-mark exam).



* Batch Result Processing:



&nbsp;		Aggregates scores across all subjects for every student.



&nbsp;		Calculates Total Score, Percentage, and Letter Grade (A+, A, B, etc.) in a single batch operation.



* Pass/Fail Logic:



&nbsp;		Implements strict validation: If a student fails a single subject (score < pass marks), their overall result is marked as FAIL, regardless of the total score.



* Dynamic Ranking System:



&nbsp;		Automatically assigns class ranks (1st, 2nd, 3rd...) based on total scores.



&nbsp;		Ranking is exclusive to students with a PASS status.



***🛠️ Technical Highlights (PL/SQL Concepts)***



* Exception Handling:



&nbsp;		Handles NO\_DATA\_FOUND to prevent crashes if referenced data (like a Subject ID) is missing.



&nbsp;		Uses RAISE\_APPLICATION\_ERROR to return meaningful, user-friendly error messages to the application layer.



* Advanced Cursors:



&nbsp;		Aggregation Cursor: Uses GROUP BY and CASE statements to calculate totals and count failed subjects efficiently.



&nbsp;		Ranking Cursor: Iterates through sorted results to assign sequential ranks using row updates.



* Relational Design:



&nbsp;		Normalized schema using Primary Keys, Foreign Keys, and Check Constraints.



&nbsp;		Uses Sequences for auto-incrementing unique keys.



***🗄️ Database Structure***

* students: Stores student metadata (ID, Name, Batch).



* subjects: Master table for subject rules (Max Marks, Pass Marks).



* marks: Transactional table linking Students and Subjects with Scores.



* results: Analytics table storing the final processed report card data.



***📋 Workflow***

Setup: Define subjects and criteria (Max/Pass marks).



Registration: Register students using exam\_pkg.add\_student.



Data Entry: Input marks using exam\_pkg.enter\_mark (Triggers validate input instantly).



Processing: Run exam\_pkg.process\_results to generate the final report card and class ranks.

