**Project Title: Employee Payroll Management System**

Description: A PL/SQL-based backend application designed to automate the calculation of monthly salaries, manage employee records, and strictly audit any changes to employee pay.



***🚀 Key Features***

* Employee Management:



&nbsp;		Easily onboard new employees into specific departments using a simple stored procedure.



&nbsp;		Automatically assigns unique Employee IDs.



* Automated Payroll Processing:



&nbsp;		One-Click Generation: Calculates salaries for all employees in a single batch execution.



&nbsp;		Smart Calculations: Automatically computes HRA (20% of Basic), Bonus (Flat 1000), and Net Salary.



* Tax Logic: Implements a logic-based tax system:



&nbsp;		Income ≤ 600,000/yr: 0% Tax.



&nbsp;		Income > 600,000/yr: 10% Tax on the excess amount.



* Safety Mechanisms:



&nbsp;		Double-Payment Prevention: Prevents processing payroll for the same employee twice in the same month (e.g., you cannot generate 'DEC-2025' slips twice).



* Security \& Auditing:



&nbsp;		Salary Audit Trail: If an admin updates an employee's Basic Salary, a Trigger automatically logs the old salary, new salary, date, and the user who made the change.



* Reporting:



&nbsp;		Generates a department-wise summary showing the number of staff and total salary spend per department.



***🛠️ Technical Highlights (PL/SQL Concepts)***

* Package-Based Architecture (payroll\_pkg):



&nbsp;		Groups all payroll logic (adding staff, calculating tax, running payroll) into a single, organized unit.



* Database Triggers (trg\_audit\_salary):



&nbsp;		Functions as an invisible "security camera." It listens for UPDATE events on the basic\_salary column and writes a permanent log to the audit table without any manual intervention.



* Explicit Cursors:



&nbsp;		Used in the Department Report to efficiently iterate through grouped data and print a summary.



* Modular Functions:



&nbsp;		calculate\_tax: A private function hidden inside the package body. It isolates the complex tax math from the main payroll loop, making the code cleaner and easier to maintain.



* Exception Handling:



&nbsp;		Uses DUP\_VAL\_ON\_INDEX to gracefully skip employees who have already been paid for the month, ensuring the batch process doesn't crash halfway through.



***🗄️ Database Structure***

departments: Master table for department names (IT, HR, Sales).



employees: Stores personal details and current basic\_salary.



salary\_details: The "Payslip" table. Stores the historical record of every calculated salary (Month, Basic, Tax, Net).



salary\_audit: A log table that tracks who changed a salary and when.



***📋 Workflow***

Setup: Initialize the system by creating departments (e.g., IT, HR).



Onboarding: Add new staff using payroll\_pkg.add\_employee.



Processing: Run payroll\_pkg.generate\_payroll('MONTH-YEAR').



The system loops through all employees, calculates net pay, and saves the record.



Reporting: View spending summaries via payroll\_pkg.dept\_wise\_report.



Auditing: If you update a salary (UPDATE employees...), check the salary\_audit table to see the automatic log entry.

