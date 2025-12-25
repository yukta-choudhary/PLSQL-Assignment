**Project Title: Library Management System**

Description: A robust PL/SQL backend designed to handle the core operations of a library, including book circulation, member management, automatic fine calculation, and inventory status tracking.



***🚀 Key Features***

* Smart Inventory Management:



&nbsp;		Auto-Status Updates: You don't need to manually mark a book as "Unavailable." When a book is issued, the system automatically flips its status to 'ISSUED'. When returned, it flips back to 				'AVAILABLE'.



* Circulation Rules:



&nbsp;		Validation: Prevents issuing a book that is already with another member.



&nbsp;		Loan Period: Default loan period is set to 14 days.



* Automated Fine System:



&nbsp;		Calculation: Automatically calculates overdue fines upon return.



&nbsp;		Rate: Charged at $2.00 per day for every day past the due date.



* Reporting:



&nbsp;		Overdue Tracker: Generates a report listing members who have books currently overdue and calculates how many days late they are.



***🛠️ Technical Highlights (PL/SQL Concepts)***

* Database Triggers (trg\_book\_status):



&nbsp;		Acts as the synchronization engine. It listens to the issue\_return table and updates the master books table instantly, ensuring data consistency between transactions and inventory.



* Package-Based Logic (library\_pkg):



&nbsp;		Encapsulates all procedures (issue\_book, return\_book) and functions into a single compilation unit for better organization and security.



* Date Arithmetic:



&nbsp;		Uses TRUNC(SYSDATE) logic to calculate fines based on full days, ignoring time stamps to ensure fair billing.



* Cursors:



&nbsp;		Used in the overdue\_report to join three tables (members, books, issue\_return) and iterate through the results efficiently.



* Transaction Control:



&nbsp;		Uses explicit COMMIT points during testing to prevent table locking issues (Timeouts) when updating and reading the same rows in quick succession.



***🗄️ Database Structure***

* books: The inventory. Tracks Title, Author, and Status (AVAILABLE / ISSUED).



* members: Registry of library users.



* issue\_return: A transaction log recording every time a book leaves or enters the library, including dates and fines.



***📋 Workflow***

* Setup: Initialize the library by adding Books and Members using the package helpers.



* Issue: Run library\_pkg.issue\_book.



* The system checks availability -> Creates a transaction record -> Trigger updates book status to 'ISSUED'.



* Simulate Time (Testing): Manually update the due\_date in the database to a past date to test the fine logic.



* Reporting: Run overdue\_report to see who is late.



* Return: Run library\_pkg.return\_book.



* The system calculates the fine -> Closes the transaction record -> Trigger updates book status back to 'AVAILABLE'.
