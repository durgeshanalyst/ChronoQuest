CREATE DATABASE Mini_project_LDH
use Mini_project_LDH;

---script:
/*Data is saved in safehose repo by name Mini_Project_LDH.sql*/ 
/*question*/

----1. Which users did not log in during the past 5 months? CONSIDER A 5 MONTH BACK  DATE FROM TODAY
select * from users
select * from logins

/*approach 1*/
WITH not_login
     AS (SELECT user_id,
                Max(login_timestamp)          AS LATEST_LOGIN,
                Dateadd(month, -5, Getdate()) AS MONTHBACK
         FROM   logins
         GROUP  BY user_id)
SELECT user_id,
       latest_login
FROM   not_login
WHERE  latest_login < monthback 


/*App-2*/
SELECT DISTINCT user_id
FROM   logins
WHERE  user_id NOT IN (SELECT user_id
                       FROM   logins
                       WHERE  login_timestamp > Dateadd(month, -5, Getdate())) 


/*2. WAQ to return 1st day of quarter and How many users and sessions were there in each quarter, ordered from newest to oldest?*/
SELECT Datepart(year, login_timestamp)          AS year,
       Datetrunc(quarter, Min(login_timestamp)) AS First_day_of_qrt,
       Datepart(quarter, login_timestamp)       AS Qrt,
       Count(DISTINCT user_id)                  AS users,
       Count(session_id)                        AS sess
FROM   logins
GROUP  BY Datepart(year, login_timestamp),
          Datepart(quarter, login_timestamp) 


/*3. Which users logged in during January 2024 but did not log in during November 2023?*/


SELECT DISTINCT USER_ID FROM LOGINS WHERE YEAR(LOGIN_TIMESTAMP) = 2024 AND MONTH(LOGIN_TIMESTAMP) = 1
EXCEPT
SELECT DISTINCT USER_ID FROM LOGINS WHERE YEAR(LOGIN_TIMESTAMP) = 2023 AND MONTH(LOGIN_TIMESTAMP) = 11


/*4. ADDITION TO THE QUESTION 2 , What is the percentage change in sessions from the last quarter?
RETURN THE 1ST DAY OF QUARTER, SESSION CNT, SESSION_CNT_PREV AND SESSION % CHANGE*/

WITH CTE AS(
SELECT Datepart(year, login_timestamp)          AS year,
       Datetrunc(quarter, Min(login_timestamp)) AS First_day_of_qrt,
       Datepart(quarter, login_timestamp)       AS Qrt,
       Count(DISTINCT user_id)                  AS users,
       Count(session_id)                        AS sess
FROM   logins
GROUP  BY Datepart(year, login_timestamp),
          Datepart(quarter, login_timestamp))

	SELECT *
		,LAG(SESS) OVER(ORDER BY First_day_of_qrt) AS PREV_SESS_COUNT
		,(LAG(SESS) OVER(ORDER BY First_day_of_qrt)-SESS)*100.0/SESS AS '%CHANGE' FROM CTE

/*5. Which user had the highest session score each day?*/
SELECT * FROM LOGINS

WITH CTE AS(
SELECT 
	CAST(LOGIN_TIMESTAMP AS DATE) AS DAY,
	USER_ID,
	SUM(SESSION_SCORE) AS SESSION_SCORE
	FROM LOGINS
	GROUP BY CAST(LOGIN_TIMESTAMP AS DATE),USER_ID),
	CTE2 AS(
	SELECT DAY,
	MAX(SESSION_SCORE) AS HIGHEST
	FROM CTE
	GROUP BY DAY)

	SELECT DISTINCT USER_ID FROM CTE C JOIN CTE2 C2 ON C.SESSION_SCORE = C2.HIGHEST


/*6. Which users have had a session every single day since their first login?*/


WITH CTE AS (
SELECT USER_ID, MIN(LOGIN_TIMESTAMP) AS FIRST_LOGIN,
MAX(LOGIN_TIMESTAMP) AS LAST_LOGIN,
COUNT(*) AS USER_LOGIN_DAY
FROM LOGINS
GROUP BY USER_ID),
CTE2 AS(
SELECT *, DATEDIFF(DAY,FIRST_LOGIN,LAST_LOGIN)+1 AS NEEDED FROM CTE )
SELECT cte.USER_ID AS BestUser from cte,cte2 where NEEDED= cte.USER_LOGIN_DAY



/*APP2*/
SELECT USER_ID, min(cast(login_timestamp as date)) as first_date_login,
COUNT(*) AS All_day_USER_LOGIN,
DATEDIFF(day,min(cast(login_timestamp as date)),max(cast((login_timestamp +1) as date))) as needed
FROM LOGINS
GROUP BY USER_ID
having DATEDIFF(day,min(cast(login_timestamp as date)),max(cast((login_timestamp +1) as date))) = count(*)


/*7. On what dates were there no logins at all?
*/

/*Here is requirement of calender table
Lets generate*/

/*step 1: Create calender schema*/

CREATE TABLE Calendar (
    date DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    day_of_week VARCHAR(10),
    quarter INT
);

-- Declare start and end dates as needed
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2029-12-31';

WITH DateSeries AS ( --------------Recursive CTE to generate and add date frm start to end
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSeries
    WHERE DATEADD(DAY, 1, DateValue) <= @EndDate
)
INSERT INTO Calendar (date, year, month, day, day_of_week, quarter) ----------Insert records
SELECT 
    DateValue AS date,
    YEAR(DateValue) AS year,
    MONTH(DateValue) AS month,
    DAY(DateValue) AS day,
    DATENAME(WEEKDAY, DateValue) AS day_of_week,
    DATEPART(QUARTER, DateValue) AS quarter
FROM DateSeries
OPTION (MAXRECURSION 0);

SELECT * FROM Calendar ORDER BY date;


/*7. On what dates were there no logins at all?*/

select * from logins


select date from Calendar c join (select min(cast(login_timestamp as date)) as first_date, max(cast(login_timestamp as date)) as last_date
from logins) c1 on c.date between c1.first_date and c1.last_date
except
select cast(login_timestamp as date) from logins