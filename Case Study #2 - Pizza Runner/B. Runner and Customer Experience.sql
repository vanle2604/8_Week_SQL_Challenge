-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT
  number_of_week,
  number_of_registrations
FROM
  (
    SELECT
      'Week ' || RANK () OVER (
        ORDER BY
          date_trunc('week', registration_date)
      ) number_of_week,
      DATE_TRUNC('week', registration_date) AS week,
      COUNT(*) AS number_of_registrations
    FROM
      pizza_runner.runners
    GROUP BY
      week
  ) AS count_weeks;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT
  runner_id,
  ROUND(
    AVG (
      DATE_PART(
        'minute',
        TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') - c.order_time
      )
    )
  ) AS average_pickup_time_in_minutes
FROM
  pizza_runner.runner_orders AS r,
  pizza_runner.customer_orders AS c
WHERE
  c.order_id = r.order_id
  AND pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  runner_id
ORDER BY
  runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT
  c.order_id,
  COUNT(c.order_id) AS items_in_order,
  ROUND(
    AVG (
      DATE_PART(
        'minute',
        pickup_time_new - c.order_time
      )
    )
  ) AS average_pickup_time_in_minutes,
  ROUND(
    AVG (
      DATE_PART(
        'minute',
        pickup_time_new - c.order_time
      )
    ) / COUNT(c.order_id)
  ) AS average_time_per_pizza_in_minutes
FROM
  pizza_runner.runner_orders AS r,
  pizza_runner.customer_orders AS c,
  LATERAL(
    SELECT
      TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') AS pickup_time_new
  ) pt
WHERE
  c.order_id = r.order_id
  AND pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  c.order_id
ORDER BY
  items_in_order DESC;

-- 4. What was the average distance travelled for each customer?

SELECT
  customer_id,
  ROUND(AVG(TO_NUMBER(distance, '99D9')), 1) AS average_distance_km
FROM
  pizza_runner.runner_orders AS r,
  pizza_runner.customer_orders AS c
WHERE
  c.order_id = r.order_id
  AND pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  customer_id
ORDER BY
  customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT
  MAX(TO_NUMBER(duration, '99')) - MIN(TO_NUMBER(duration, '99')) AS delivery_time_difference_in_minutes
FROM
  pizza_runner.runner_orders AS r
WHERE
  pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null';

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT
  order_id,
  runner_id,
  ROUND(
    AVG(
      TO_NUMBER(distance, '99D9') /(TO_NUMBER(duration, '99') / 60)
    )
  ) AS runner_average_speed
FROM
  pizza_runner.runner_orders AS r
WHERE
  pickup_time != 'null'
  AND distance != 'null'
  AND duration != 'null'
GROUP BY
  order_id,
  runner_id
ORDER BY
  order_id;

-- 7. What is the successful delivery percentage for each runner?

SELECT
  runner_id,
  ROUND(
    100 - (
      SUM(unsuccessful) / (SUM(unsuccessful) + SUM(successful))
    ) * 100
  ) AS successful_delivery_percent
FROM
  (
    SELECT
      runner_id,
      CASE
        WHEN pickup_time != 'null' THEN COUNT(*)
        ELSE 0
      END AS successful,
      CASE
        WHEN pickup_time = 'null' THEN COUNT(*)
        ELSE 0
      END AS unsuccessful
    FROM
      pizza_runner.runner_orders AS r
    GROUP BY
      runner_id,
      pickup_time
  ) AS count_rating
GROUP BY
  runner_id
ORDER BY
  runner_id;
