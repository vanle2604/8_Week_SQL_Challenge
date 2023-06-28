-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

WITH profit AS
(SELECT
  pizza_name,
  CASE
        WHEN pizza_name = 'Meatlovers' THEN COUNT(pizza_name)*12
        ELSE COUNT(pizza_name)*10
      END AS profit
FROM
  pizza_runner.customer_orders AS c
  JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
  JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
WHERE
  pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  1)
SELECT SUM(profit) AS profit_in_dollars
FROM profit;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

WITH profit AS (
  SELECT
    pizza_name,
    CASE
      WHEN pizza_name = 'Meatlovers' THEN COUNT(pizza_name) * 12
      ELSE COUNT(pizza_name) * 10
    END AS profit
  FROM
    pizza_runner.customer_orders AS c
    JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
    JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
  WHERE
    pickup_time != 'null'
    AND distance != 'null'
    AND duration != 'null'
  GROUP BY
    1
),
extras AS (
  SELECT
    COUNT(topping_id) AS extras
  FROM
    (
      SELECT
        UNNEST(STRING_TO_ARRAY(extras, ',') :: int []) AS topping_id
      FROM
        pizza_runner.customer_orders AS c
        JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
      WHERE
        pickup_time != 'null'
        AND distance != 'null'
        AND duration != 'null'
        AND extras != 'null'
    ) e
)
SELECT
  SUM(profit) + extras AS profit_in_dollars
FROM
  profit,
  extras
GROUP BY
  extras;

/* --------------------
3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
   --------------------*/
SET
  search_path = pizza_runner;
DROP TABLE IF EXISTS runner_rating;
CREATE TABLE runner_rating (
    "id" SERIAL PRIMARY KEY,
    "order_id" INTEGER,
    "customer_id" INTEGER,
    "runner_id" INTEGER,
    "rating" INTEGER,
    "rating_time" TIMESTAMP
  );
INSERT INTO
  runner_rating (
    "order_id",
    "customer_id",
    "runner_id",
    "rating",
    "rating_time"
  )
VALUES
  ('1', '101', '1', '5', '2020-01-01 19:34:51'),
  ('2', '101', '1', '5', '2020-01-01 20:23:03'),
  ('3', '102', '1', '4', '2020-01-03 10:12:58'),
  ('4', '103', '2', '5', '2020-01-04 16:47:06'),
  ('5', '104', '3', '5', '2020-01-08 23:09:27'),
  ('7', '105', '2', '4', '2020-01-08 23:50:12'),
  ('8', '102', '2', '4', '2020-01-10 12:30:45'),
  ('10', '104', '1', '5', '2020-01-11 20:05:35');

/* --------------------
4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas
   --------------------*/

SELECT
  co.customer_id,
  ro.order_id,
  runner_id,
  rating,
  TO_CHAR(order_time, 'YYYY-MM-DD HH24:MI:SS') AS order_time,
  pickup_time,
  ROUND(
    DATE_PART(
      'minute',
      TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') - co.order_time
    )
  ) AS time_between_order_and_pickup,
  TO_NUMBER(duration, '99') AS delivery_time_in_minutes,
  ROUND(
    AVG(
      TO_NUMBER(distance, '99D9') /(TO_NUMBER(duration, '99') / 60)
    )
  ) AS average_speed,
  COUNT(ro.order_id) AS number_of_pizzas
FROM
  pizza_runner.runner_orders as ro
  JOIN pizza_runner.runner_rating as rr on ro.order_id = rr.order_id
  JOIN pizza_runner.customer_orders as co on ro.order_id = co.order_id
GROUP BY
  co.customer_id,
  ro.order_id,
  runner_id,
  rating,
  order_time,
  pickup_time,
  duration
  ORDER BY 1;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH profit AS (
  SELECT
    pizza_name,
    CASE
      WHEN pizza_name = 'Meatlovers' THEN COUNT(pizza_name) * 12
      ELSE COUNT(pizza_name) * 10
    END AS profit
  FROM
    pizza_runner.customer_orders AS c
    JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
    JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
  WHERE
    pickup_time != 'null'
    AND distance != 'null'
    AND duration != 'null'
  GROUP BY
    1
),
expenses AS (
  SELECT
   sum(TO_NUMBER(distance, '99D9')*0.3) as expense
  FROM
    pizza_runner.runner_orders
      WHERE
        pickup_time != 'null'
        AND distance != 'null'
        AND duration != 'null'
    ) 
SELECT
  SUM(profit) - expense AS net_profit_in_dollars
FROM
  profit,
  expenses
GROUP BY
  expense;

