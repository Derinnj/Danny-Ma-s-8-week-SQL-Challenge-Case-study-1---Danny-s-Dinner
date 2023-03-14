---------------------------------------------------------------------------------------------------------------------------------------------------------------------
----PIZZER RUNNER DATA CLEANING TASK.
-------- TASK 1: CLEAN DATATIME COLUMN AND SEPARETE INTO INDIVIDUAL COLUMNS

SELECT order_time, CONVERT(date, order_time), CONVERT(time(0), order_time)
FROM customer_PizzaOrders

ALTER TABLE customer_PizzaOrders
ADD order_date DATE;

UPDATE customer_PizzaOrders
SET order_date = CONVERT(date, order_time)

ALTER TABLE customer_PizzaOrders
ADD order_timeNew TIME;

UPDATE customer_PizzaOrders
SET order_timeNew = CONVERT(time(0), order_time)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------TASK 2: REPLACE EMPTY SPACE WITH NULL VALUES

UPDATE customer_PizzaOrders
SET exclusions = NULL
WHERE exclusions = ' '

UPDATE customer_PizzaOrders
SET exclusions = NULL
WHERE exclusions = 'null'

UPDATE customer_PizzaOrders
SET extras = NULL
WHERE extras = ' '

UPDATE customer_PizzaOrders
SET extras = NULL
WHERE extras = 'null'

SELECT *
FROM customer_PizzaOrders

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------DATA CLEANING ON RUNNER ORDERS TABLE 
----TASK 1 CONVERT PICKUP TIME TO A DATETIME FORMAT
--
-- SOME null VALUES WERE CAUSING THE CONVERSION TO BREAK SO WE HAVE TO CONVERT THEM TO ACTUALL NULLS

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null'


ALTER TABLE runner_orders
ALTER COLUMN pickup_time DATETIME;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--


SELECT pickup_time, CONVERT(date, pickup_time), CONVERT(time(0), pickup_time)
FROM runner_orders

ALTER TABLE runner_orders
ADD pickup_date DATE;

UPDATE runner_orders
SET pickup_date = CONVERT(date, pickup_time)


ALTER TABLE runner_orders
ADD pickup_timeNew TIME;

UPDATE runner_orders
SET pickup_timeNew = CONVERT(time(0), pickup_time)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----- TASK 2 CLEANING THE DISTANCE COLUMN

UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null'

SELECT REPLACE(distance, 'km', '') AS [distance(km)]
FROM runner_orders;

ALTER TABLE runner_orders
ADD [distance(km)] float;

UPDATE runner_orders
SET [distance(km)] =  REPLACE(distance, 'km', '')


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---TASK 3 CLEANING THE DURATION COLUMN

UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null'


SELECT duration, REPLACE(REPLACE(REPLACE(REPLACE(duration, 'mins', ''), 'minutes', ''), ' ', ''), 'minute', ' ') AS [duration(mins)]
FROM runner_orders

ALTER TABLE runner_orders
ADD [duration(mins)] INT;


UPDATE runner_orders
SET [duration(mins)] = REPLACE(REPLACE(REPLACE(REPLACE(duration, 'mins', ''), 'minutes', ''), ' ', ''), 'minute', ' ')

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- TASK 4 CLEANING CANCELLATION TABLE

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = ' '

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null'

SELECT *
FROM runner_orders

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- TASK 5: DROP DUPLICATE COLUMNS

ALTER TABLE runner_orders
DROP COLUMN distance

ALTER TABLE runner_orders
DROP COLUMN duration


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ SECTION 1: Pizza Metrics
--1. How many pizzas were ordered?

SELECT COUNT(order_id)
FROM customer_PizzaOrders;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---2. How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id)
FROM customer_PizzaOrders;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---3. How many successful orders were delivered by each runner?

SELECT runner_id, COUNT(order_id) AS Successful_order
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---4. How many of each type of pizza was delivered?

SELECT pizza_id, COUNT(*)
FROM runner_orders
JOIN customer_PizzaOrders
	ON runner_orders.order_id = customer_PizzaOrders.order_id
WHERE cancellation IS NULL
GROUP BY pizza_id



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT ORD.customer_id, PIZ.pizza_name, COUNT(PIZ.pizza_name) Order_num
FROM customer_PizzaOrders ORD
JOIN pizza_names PIZ
	ON PIZ.pizza_id = ORD.pizza_id
GROUP BY ORD.customer_id, PIZ.pizza_name
ORDER BY customer_id

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---6. What was the maximum number of pizzas delivered in a single order?

SELECT TOP 1 ORD.order_id, COUNT(ORD.order_id) Order_num
FROM customer_PizzaOrders ORD  
JOIN runner_orders RUN
	ON RUN.order_id = ORD.order_id
WHERE cancellation IS NULL
GROUP BY ORD.order_id
ORDER BY COUNT(ORD.order_id) DESC

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?


SELECT 
    ORD.customer_id, 
    SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS pizzas_with_changes,
    SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS pizzas_no_changes
FROM customer_PizzaOrders ORD
JOIN runner_orders RUN
	ON ORD.order_id = RUN.order_id
WHERE cancellation IS NULL
GROUP BY customer_id;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---8. How many pizzas were delivered that had both exclusions and extras?

SELECT SUM(CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 ELSE 0 END) AS Pizza_with_both
FROM customer_PizzaOrders ORD
JOIN runner_orders RUN
	ON ORD.order_id = RUN.order_id
WHERE cancellation IS NULL
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---9. What was the total volume of pizzas ordered for each hour of the day?

SELECT DATEPART(hour, order_time) AS hour_of_day, COUNT(order_id) AS total_order
FROM customer_PizzaOrders
GROUP BY DATEPART(hour, order_time)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---10. What was the volume of orders for each day of the week?

SELECT DATEPART(WEEKDAY, order_date) AS weekday, COUNT(*) AS total_order
FROM customer_PizzaOrders
GROUP BY DATEPART(WEEKDAY, order_date)
ORDER BY weekday;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- SECTION 2: Runner and Customer Experience
---- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
    DATEADD(week, DATEDIFF(week, 0, registration_date), 0) AS week_start_date,
    COUNT(DISTINCT runner_id) AS num_runners_signed_up
FROM 
    pizza_runners
GROUP BY 
    DATEADD(week, DATEDIFF(week, 0, registration_date), 0)
ORDER BY 
    week_start_date;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT  RUN.runner_id, 
    AVG(DATEDIFF(minute, ORD.order_time, RUN.pickup_time)) AS avg_pickup_time_minutes
FROM customer_PizzaOrders ORD
JOIN runner_orders RUN
	ON ORD.order_id = RUN.order_id
GROUP BY RUN.runner_id

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----3. 





---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----4. What was the average distance travelled for each customer?

SELECT ORD.customer_id, AVG(RUN.[distance(km)]) Avg_distance
FROM customer_PizzaOrders ORD
JOIN runner_orders RUN
	ON ORD.order_id = RUN.order_id
GROUP BY ORD.customer_id;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----5. What was the difference between the longest and shortest delivery times for all orders?
SELECT *
FROM customer_PizzaOrders


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, [distance(km)], [duration(mins)], ROUND(([distance(km)] / [duration(mins)]), 2) AS average_speed
FROM runner_orders


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----7. What is the successful delivery percentage for each runner?
SELECT 
    RUN.runner_id,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN RUN.cancellation IS NULL THEN 1 ELSE 0 END) AS successful_deliveries,
   SUM(CASE WHEN RUN.cancellation IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS successful_delivery_percentage
FROM customer_PizzaOrders ORD
JOIN runner_orders RUN
	ON ORD.order_id = RUN.order_id
GROUP BY runner_id;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- SECTION 3: Pricing and Ratings

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT PIZ.pizza_id, SUM(CASE WHEN PIZ.pizza_id = '1' THEN 12 ELSE 10 END )
FROM customer_PizzaOrders ORD
JOIN pizza_names PIZ
	ON ORD.pizza_id = PIZ.pizza_id
GROUP BY PIZ.pizza_id;

WITH Price_table AS (
SELECT ORD.order_id, ORD.customer_id, PIZ.pizza_id, PIZ.pizza_name, CASE WHEN PIZ.pizza_id = '1' THEN 12 ELSE 10 END AS price 
FROM customer_PizzaOrders ORD
JOIN pizza_names PIZ
	ON ORD.pizza_id = PIZ.pizza_id)

SELECT pizza_name, SUM(price)
FROM Price_table
GROUP BY pizza_name;



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----2 What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra

WITH Price_table AS (
SELECT ORD.order_id, ORD.customer_id, PIZ.pizza_id,extras,exclusions, PIZ.pizza_name, CASE WHEN PIZ.pizza_id = '1' THEN 12 ELSE 10 END AS price 
FROM customer_PizzaOrders ORD
JOIN pizza_names PIZ
	ON ORD.pizza_id = PIZ.pizza_id),

Ext_charge AS (
SELECT order_id, customer_id, pizza_id,extras,exclusions, pizza_name, price,
		CASE WHEN extras IS NOT NULL THEN price + 1 ELSE price END AS Price_with_extra
		 --CASE WHEN extras IS NOT NULL AND extras LIKE '%4%' THEN price + 1 + 1 ELSE price END AS with_cheese 
FROM Price_table
),

With_cheese AS (
SELECT order_id, customer_id, pizza_id,extras,pizza_name, price, Price_with_extra,
		CASE WHEN extras IS NOT NULL AND extras LIKE '%4%' THEN Price_with_extra + 1 ELSE Price_with_extra END AS with_cheese
FROM Ext_charge)

SELECT pizza_name, SUM(price) price, SUM(Price_with_extra) Price_with_extra, SUM(with_cheese) Price_with_extraNcheese
FROM With_cheese
GROUP BY pizza_name


