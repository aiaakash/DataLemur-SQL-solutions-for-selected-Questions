


--Q1
--Assume you have the table below containing information on Facebook user actions. Write a query to obtain the active user retention in July 2022. Output the month (in numerical format 1, 2, 3) and the number of monthly active users (MAUs).
--Hint: An active user is a user who has user action ("sign-in", "like", or "comment") in the current month and last month.

--Active User Retention [Facebook SQL Interview Question]

WITH mo7 as
(select * from user_actions
WHERE EXTRACT(MONTH FROM event_date) = 07 AND
event_type in ('sign-in', 'like', 'comment') and user_id in (SELECT DISTINCT user_id
FROM user_actions
WHERE EXTRACT(MONTH FROM event_date) = 06 AND
event_type in ('sign-in', 'like', 'comment')))

select EXTRACT(MONTH FROM event_date) as mo, count(distinct user_id)
from mo7
group by mo




--Q2
--Y-on-Y Growth Rate [Wayfair SQL Interview Question]
--Assume you are given the table below containing information on user transactions for particular products. Write a query to obtain the year-on-year growth rate for the total spend of each product for each year.

Output the year (in ascending order) partitioned by product id, current year's spend, previous year's spend and year-on-year growth rate (percentage rounded to 2 decimal places).

SELECT EXTRACT(YEAR FROM transaction_date) as yr  ,product_id, spend as curr_year_spend, 
LAG(spend) OVER(PARTITION BY product_id ORDER BY transaction_date) as prev_year_spend, 
ROUND(((spend - LAG(spend) OVER(PARTITION BY product_id ORDER BY transaction_date))*100) / LAG(spend) OVER(PARTITION BY product_id ORDER BY transaction_date),2) as yoy_rate
FROM user_transactions
ORDER BY product_id
;




--Q3
--Write a query to update the Facebook advertiser's status using the daily_pay table. Advertiser is a two-column table containing the user id and their payment status based on the last payment and daily_pay table has current information about their payment. Only advertisers who paid will show up in this table.
--Output the user id and current payment status sorted by the user id.
--Advertiser Status [Facebook SQL Interview Question]


SELECT a.*, b.*,
CASE WHEN b.user_id IS NULL then 'CHURN' 
     WHEN b.user_id IS NOT NULL AND status = 'CHURN' then 'RESURRECT'
  ELSE 'EXISTING' END AS new_status
FROM advertiser a
LEFT JOIN daily_pay b on a.user_id = b.user_id
;




--Q4
--3-Topping Pizzas [McKinsey SQL Interview Question]
--You’re a consultant for a major pizza chain that will be running a promotion where all 3-topping pizzas will be sold for a fixed price, and are trying to understand the costs involved.
--Given a list of pizza toppings, consider all the possible 3-topping pizzas, and print out the total cost of those 3 toppings. Sort the results with the highest total cost on the top followed by pizza toppings in ascending order.
--Break ties by listing the ingredients in alphabetical order, starting from the first ingredient, followed by the second and third.
--P.S. Be careful with the spacing (or lack of) between each ingredient. Refer to our Example Output.


WITH tab1 as (SELECT ingredient_cost as cost2,  topping_name as top2 FROM pizza_toppings ORDER BY topping_name)
,
tab2 as (SELECT ingredient_cost as cost3,  topping_name as top3 FROM pizza_toppings ORDER BY topping_name)
,
tab3 as(select * from pizza_toppings a 
INNER JOIN tab1 b ON a.topping_name < b.top2
INNER JOIN tab2 c ON b.top2 < c.top3
-- WHERE a.topping_name <> b.top2 and b.top2 <> c.top3 and c.top3 <>a.topping_name
)
,
tab4 as(select *, ingredient_cost + cost2 + cost3 as total_cost from tab3)
, tab5 as (select topping_name, top2, top3, max(total_cost) as res from tab4 group by topping_name, top2, top3 order by max(total_cost) desc)

select *, concat(topping_name, ',',	top2, ',',	top3) from tab5





--Q5
--UnitedHealth Group has a program called Advocate4Me, which allows members to call an advocate and receive support for their health care needs – whether that's behavioural, clinical, well-being, health care financing, benefits, claims or pharmacy help.
--Write a query to get the patients who made a call within 7 days of their previous call. If a patient called more than twice in a span of 7 days, count them as once.

WITH tab1 as 
(SELECT *, EXTRACT(DOY FROM call_received) as doy
FROM callers ORDER BY policy_holder_id, call_received)
,
tab2 as
(select *, lag(doy) OVER(PARTITION BY policy_holder_id ORDER BY call_received) as lagdoy,
doy - lag(doy) OVER(PARTITION BY policy_holder_id ORDER BY call_received) as gapp
from tab1)
,
tab3 as
(select *, case when gapp <8 then 1 else 0 end as flag
from tab2)

select count(*) from
(select policy_holder_id, MAX(flag) as qwe
from tab3 group by 1 having MAX(flag) >0) as rere





--Q6
--Patient Support Analysis (Part 4) [UnitedHealth SQL Interview Question]
--UnitedHealth Group has a program called Advocate4Me, which allows members to call an advocate and receive support for their health care needs – whether that's behavioural, clinical, well-being, health care financing, benefits, claims or pharmacy help.
--A long-call is categorised as any call that lasts more than 5 minutes (300 seconds). What's the month-over-month growth of long-calls?
--Output the year, month (both in numerical and chronological order) and growth percentage rounded to 1 decimal place.

WITH tab1 as
(SELECT *, EXTRACT(YEAR FROM call_received) as yr, EXTRACT(MONTH FROM call_received) as mo
FROM callers
WHERE call_duration_secs > 300)
,

tab2 as
(select yr, mo, count(policy_holder_id) as cnt
from tab1 
group by 1,2
order by 1,2)

select *, ROUND((((cnt - lag(cnt) OVER(ORDER BY mo)) * 100.0) / lag(cnt) OVER(ORDER BY mo)), 1) as growth_pct
from tab2





--Q7
--Repeated Payments [Stripe SQL Interview Question]
--Sometimes, payment transactions are repeated by accident; it could be due to user error, API failure or a retry error that causes a credit card to be charged twice.
--Using the transactions table, identify any payments made at the same merchant with the same credit card for the same amount within 10 minutes of each other. Count such repeated payments.
--Assumptions:
--The first transaction of such payments should not be counted as a repeated payment. This means, if there are two transactions performed by a merchant with the same credit card and for the same amount within 10 minutes, there will only be 1 repeated payment.

WITH tab1 as
(SELECT *, LAG(transaction_timestamp) OVER(PARTITION BY merchant_id, credit_card_id, amount ORDER BY transaction_timestamp) as lg
FROM transactions)
,

tab2 as
(select *, 
-- EXTRACT(MINUTES FROM transaction_timestamp) original_min, EXTRACT(MINUTES FROM lg) as lag_min
age(transaction_timestamp, lg) as gap
from tab1)
,
tab3 as
(select *, 
-- EXTRACT(day FROM gap) dy,EXTRACT(HOUR FROM gap) hr, EXTRACT(MINUTES FROM gap) min,
EXTRACT(day FROM gap) * 1440 + EXTRACT(HOUR FROM gap) * 60  + EXTRACT(MINUTES FROM gap)  as actual_gap
from tab2)

select count(*) from tab3 where actual_gap < 11