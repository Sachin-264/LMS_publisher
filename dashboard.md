Of course. This is an excellent question for understanding the full data flow.

Here is a detailed breakdown of each data point on your dashboard, tracing it back to the specific database table and column from which it originates.

Data Traceability: From Database to Dashboard
UI Component	Data Point	Source Table(s)	Source Column(s)	How It's Calculated in the Stored Procedure
Total Schools KPI	The total number of active schools.	School_Master	School_ID, Status	COUNT(School_ID) where Status is 1.
Total Revenue KPI	The sum of prices for all active subscriptions.	Subscription_Master, School_Subscription_Map	Subscription_Master.Price, School_Subscription_Map.Status, Subscription_ID (for JOIN)	SUM(Price) for all records where Status is 'Active'.
Active Subscriptions KPI	The total count of active school subscriptions.	School_Subscription_Map	School_Subscription_ID, Status	COUNT(School_Subscription_ID) where Status is 'Active'.
Upcoming Expiry KPI	The count of subscriptions ending in the next 30 days.	School_Subscription_Map	School_Subscription_ID, End_Date	COUNT(School_Subscription_ID) where End_Date is between today and 30 days from now.
Monthly Revenue Chart	Revenue per month (for the last year).	Subscription_Master, School_Subscription_Map	Subscription_Master.Price, School_Subscription_Map.Purchase_Date	SUM(Price) grouped by the month and year of Purchase_Date.
Schools by Type Chart	The number of schools for each type (e.g., Private).	School_Master	School_Type, School_ID	COUNT(School_ID) grouped by School_Type.
Content Growth (Materials)	Materials uploaded per month (for the last year).	Study_Material	Material_ID, Uploaded_On	COUNT(Material_ID) grouped by the month and year of Uploaded_On.
Top Plan Insight	The name of the most purchased subscription plan.	Subscription_Master, School_Subscription_Map	Subscription_Master.Subscription_Name, School_Subscription_Map.Subscription_ID	Groups subscriptions by Subscription_Name, counts them, and returns the top one (TOP 1).
Auto-Renewal Insight	The count of active subscriptions set to auto-renew.	School_Subscription_Map	School_Subscription_ID, Auto_Renewal, Status	COUNT(School_Subscription_ID) where Auto_Renewal is 1 and Status is 'Active'.
Top State Insight	The state with the highest number of schools.	School_Master	State, School_ID	COUNT(School_ID) grouped by State, returning the top one (TOP 1).
Newly Registered Insight	The count of schools created in the current month.	School_Master	School_ID, Created_Date	COUNT(School_ID) where the month and year of Created_Date match the current month and year.
Content Growth (Chapters)	New chapters with content uploaded per month.	Study_Material	Chapter_ID, Uploaded_On	Finds the earliest Uploaded_On date for each unique Chapter_ID, then counts how many of these "first uploads" occurred in each month.