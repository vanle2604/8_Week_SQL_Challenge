-- 1. What are the standard ingredients for each pizza?

SELECT
  pizza_name,
  string_agg(topping_name, ', ') AS toppings
FROM
  pizza_runner.pizza_toppings AS t,
  pizza_runner.pizza_recipes AS r
  JOIN pizza_runner.pizza_names AS n ON r.pizza_id = n.pizza_id
WHERE
  t.topping_id IN (
    SELECT
      unnest(string_to_array(r.toppings, ',') :: int [])
  )
GROUP BY
  1
ORDER BY
  1;

-- 2. What was the most commonly added extra?

SELECT
  extra_ingredient,
  number_of_pizzas
FROM
  (
    WITH extras_table AS (
      SELECT
        order_id,
        unnest(string_to_array(extras, ',') :: int []) AS topping_id
      FROM
        pizza_runner.customer_orders AS c
      WHERE
        extras != 'null'
    )
    SELECT
      topping_name AS extra_ingredient,
      COUNT(topping_name) AS number_of_pizzas,
      RANK() OVER (
        ORDER BY
          COUNT(topping_name) DESC
      ) AS rank
    FROM
      extras_table AS et
      JOIN pizza_runner.pizza_toppings AS t ON et.topping_id = t.topping_id
    GROUP BY
      topping_name
  ) t
WHERE
  rank = 1;

-- 3. What was the most common exclusion?

SELECT
  excluded_ingredient,
  number_of_pizzas
FROM
  (
    WITH exclusions_table AS (
      SELECT
        order_id,
        unnest(string_to_array(exclusions, ',') :: int []) AS topping_id
      FROM
        pizza_runner.customer_orders AS c
      WHERE
        exclusions != 'null'
    )
    SELECT
      topping_name AS excluded_ingredient,
      COUNT(topping_name) AS number_of_pizzas,
      RANK() OVER (
        ORDER BY
          COUNT(topping_name) DESC
      ) AS rank
    FROM
      exclusions_table AS et
      JOIN pizza_runner.pizza_toppings AS t ON et.topping_id = t.topping_id
    GROUP BY
      topping_name
  ) t
WHERE
  rank = 1;

/* --------------------
4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
   --------------------*/

SELECT
  order_id,
  CONCAT(
    pizza_name,
    ' ',
    CASE
      WHEN COUNT(exclusions) > 0 THEN '- Exclude '
      ELSE ''
    END,
    STRING_AGG(exclusions, ', '),
    CASE
      WHEN COUNT(extras) > 0 THEN ' - Extra '
      ELSE ''
    END,
    STRING_AGG(extras, ', ')
  ) AS pizza_name_exclusions_and_extras
FROM
  (
    WITH rank_added AS (
      SELECT
        *,
        ROW_NUMBER() OVER () AS rank
      FROM
        pizza_runner.customer_orders
    )
    SELECT
      rank,
      ra.order_id,
      pizza_name,
      CASE
        WHEN exclusions != 'null'
        AND topping_id IN (
          SELECT
            UNNEST(STRING_TO_ARRAY(exclusions, ',') :: int [])
        ) THEN topping_name
      END AS exclusions,
      CASE
        WHEN extras != 'null'
        AND topping_id IN (
          SELECT
            unnest(string_to_array(extras, ',') :: int [])
        ) THEN topping_name
      END AS extras
    FROM
      pizza_runner.pizza_toppings AS t,
      rank_added as ra
      JOIN pizza_runner.pizza_names AS n ON ra.pizza_id = n.pizza_id
    GROUP BY
      rank,
      ra.order_id,
      pizza_name,
      exclusions,
      extras,
      topping_id,
      topping_name
  ) AS toppings_as_names
GROUP BY
  pizza_name,
  rank,
  order_id
ORDER BY
  rank;

/* --------------------
5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
   --------------------*/

SELECT
  order_id,
  CONCAT(
    pizza_name,
    ': ',
    STRING_AGG(
      topping_name,
      ', '
      ORDER BY
        topping_name
    )
  ) AS all_ingredients
FROM
  (
    SELECT
      rank,
      order_id,
      pizza_name,
      CONCAT(
        CASE
          WHEN (SUM(count_toppings) + SUM(count_extra)) > 1 THEN (SUM(count_toppings) + SUM(count_extra)) || 'x'
        END,
        topping_name
      ) AS topping_name
    FROM
      (
        WITH rank_added AS (
          SELECT
            *,
            ROW_NUMBER() OVER () AS rank
          FROM
            pizza_runner.customer_orders
        )
        SELECT
          rank,
          ra.order_id,
          pizza_name,
          topping_name,
          CASE
            WHEN exclusions != 'null'
            AND t.topping_id IN (
              SELECT
                unnest(string_to_array(exclusions, ',') :: int [])
            ) THEN 0
            ELSE CASE
              WHEN t.topping_id IN (
                SELECT
                  UNNEST(STRING_TO_ARRAY(r.toppings, ',') :: int [])
              ) THEN COUNT(topping_name)
              ELSE 0
            END
          END AS count_toppings,
          CASE
            WHEN extras != 'null'
            AND t.topping_id IN (
              SELECT
                unnest(string_to_array(extras, ',') :: int [])
            ) THEN count(topping_name)
            ELSE 0
          END AS count_extra
        FROM
          rank_added AS ra,
          pizza_runner.pizza_toppings AS t,
          pizza_runner.pizza_recipes AS r
          JOIN pizza_runner.pizza_names AS n ON r.pizza_id = n.pizza_id
        WHERE
          ra.pizza_id = n.pizza_id
        GROUP BY
          pizza_name,
          rank,
          ra.order_id,
          topping_name,
          toppings,
          exclusions,
          extras,
          t.topping_id
      ) tt
    WHERE
      count_toppings > 0
      OR count_extra > 0
    GROUP BY
      pizza_name,
      rank,
      order_id,
      topping_name
  ) cc
GROUP BY
  pizza_name,
  rank,
  order_id
ORDER BY
  rank;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

SELECT
  topping_name,
  (SUM(topping_count) + SUM(extras_count)) AS total_ingredients
FROM
  (
    WITH rank_added AS (
      SELECT
        *,
        ROW_NUMBER() OVER () AS rank
      FROM
        pizza_runner.customer_orders
    )
    SELECT
      rank,
      topping_name,
      CASE
        WHEN extras != 'null'
        AND topping_id IN (
          SELECT
            unnest(string_to_array(extras, ',') :: int [])
        ) THEN count(topping_name)
        ELSE 0 END AS extras_count,
      CASE
        WHEN exclusions != 'null'
        AND topping_id IN (
          SELECT
            unnest(string_to_array(exclusions, ',') :: int [])
        ) THEN NULL
        ELSE CASE
          WHEN topping_id IN (
            SELECT
              UNNEST(STRING_TO_ARRAY(toppings, ',') :: int [])
          ) THEN COUNT(topping_name)
        END
      END AS topping_count
    FROM
      pizza_runner.pizza_toppings AS t,
      pizza_runner.pizza_recipes AS r,
      rank_added as ra,
      pizza_runner.runner_orders AS ro
    WHERE
      ro.order_id = ra.order_id
      and ra.pizza_id = r.pizza_id
      and pickup_time != 'null'
      AND distance != 'null'
      AND duration != 'null'
    GROUP BY
      topping_name,
      exclusions,
      extras,
      toppings,
      topping_id,
      rank
  ) AS topping_count
GROUP BY
  topping_name
ORDER BY
  total_ingredients DESC;
