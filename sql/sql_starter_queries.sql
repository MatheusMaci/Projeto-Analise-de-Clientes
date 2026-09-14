-- ============================================================
-- PROJETO 2 — SQL STARTER QUERIES
-- SQL SERVER
-- ============================================================

-- ============================================================
-- 1. BASE FINANCEIRA POR CLIENTE
-- ============================================================

SELECT
    t1.customer_id,
    COUNT(DISTINCT t2.order_id) AS total_orders,

    SUM(
        t3.quantity
        * t3.unit_price
        * (1 - t3.discount)
    ) AS revenue,

    SUM(
        t3.quantity
        * t3.unit_cost
    ) AS cost,

    SUM(
        t3.quantity
        * t3.unit_price
        * (1 - t3.discount)
        -
        t3.quantity
        * t3.unit_cost
    ) AS profit,

    MAX(t2.order_date) AS last_purchase_date

FROM clients t1

LEFT JOIN orders t2
    ON t1.customer_id = t2.customer_id
    AND t2.order_status = 'Concluído'

LEFT JOIN order_items t3
    ON t2.order_id = t3.order_id

GROUP BY
    t1.customer_id;


-- ============================================================
-- 2. ONE-TIME VS RECORRENTE
-- ============================================================

WITH customer_orders AS (

    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders

    FROM orders

    WHERE order_status = 'Concluído'

    GROUP BY customer_id
)

SELECT
    CASE
        WHEN total_orders = 1
            THEN 'One-time'

        WHEN total_orders >= 2
            THEN 'Recorrente'

        ELSE 'Sem compra'
    END AS customer_type,

    COUNT(*) AS customers

FROM customer_orders

GROUP BY
    CASE
        WHEN total_orders = 1
            THEN 'One-time'

        WHEN total_orders >= 2
            THEN 'Recorrente'

        ELSE 'Sem compra'
    END;


-- ============================================================
-- 3. RECEITA E LUCRO POR CATEGORIA
-- ============================================================

SELECT
    t4.category,

    SUM(
        t3.quantity
        * t3.unit_price
        * (1 - t3.discount)
    ) AS revenue,

    SUM(
        t3.quantity
        * t3.unit_price
        * (1 - t3.discount)
        -
        t3.quantity
        * t3.unit_cost
    ) AS profit

FROM order_items t3

INNER JOIN orders t2
    ON t3.order_id = t2.order_id

INNER JOIN products t4
    ON t3.product_id = t4.product_id

WHERE t2.order_status = 'Concluído'

GROUP BY
    t4.category

ORDER BY
    revenue DESC;


-- ============================================================
-- 4. RECÊNCIA POR CLIENTE
-- ============================================================

SELECT
    t1.customer_id,
    MAX(t2.order_date) AS last_purchase_date,

    DATEDIFF(
        DAY,
        MAX(t2.order_date),
        '2025-12-31'
    ) AS recency_days

FROM clients t1

LEFT JOIN orders t2
    ON t1.customer_id = t2.customer_id
    AND t2.order_status = 'Concluído'

GROUP BY
    t1.customer_id;


-- ============================================================
-- 5. STATUS DO CLIENTE
-- ============================================================

WITH last_purchase AS (

    SELECT
        t1.customer_id,
        MAX(t2.order_date) AS last_purchase_date

    FROM clients t1

    LEFT JOIN orders t2
        ON t1.customer_id = t2.customer_id
        AND t2.order_status = 'Concluído'

    GROUP BY
        t1.customer_id
)

SELECT
    customer_id,
    last_purchase_date,

    CASE

        WHEN last_purchase_date IS NULL
            THEN 'Sem compra'

        WHEN DATEDIFF(
            DAY,
            last_purchase_date,
            '2025-12-31'
        ) <= 90
            THEN 'Ativo'

        WHEN DATEDIFF(
            DAY,
            last_purchase_date,
            '2025-12-31'
        ) > 180
            THEN 'Inativo'

        ELSE 'Intermediário'

    END AS customer_status

FROM last_purchase;


-- ============================================================
-- 6. TOP 20 CLIENTES POR RECEITA
-- ============================================================

SELECT TOP 20

    t1.customer_id,

    SUM(
        t3.quantity
        * t3.unit_price
        * (1 - t3.discount)
    ) AS revenue

FROM clients t1

INNER JOIN orders t2
    ON t1.customer_id = t2.customer_id

INNER JOIN order_items t3
    ON t2.order_id = t3.order_id

WHERE t2.order_status = 'Concluído'

GROUP BY
    t1.customer_id

ORDER BY
    revenue DESC;


-- ============================================================
-- 7. BASE RFM
-- ============================================================

SELECT

    t1.customer_id,

    DATEDIFF(
        DAY,
        MAX(t2.order_date),
        '2025-12-31'
    ) AS recency,

    COUNT(DISTINCT t2.order_id) AS frequency,

    SUM(
        t3.quantity
        * t3.unit_price
        * (1 - t3.discount)
    ) AS monetary

FROM clients t1

INNER JOIN orders t2
    ON t1.customer_id = t2.customer_id

INNER JOIN order_items t3
    ON t2.order_id = t3.order_id

WHERE t2.order_status = 'Concluído'

GROUP BY
    t1.customer_id;


-- ============================================================
-- 8. TOP 10 CLIENTES E PARTICIPAÇÃO DA RECEITA
-- ============================================================

WITH customer_revenue AS (

    SELECT
        t1.customer_id,

        SUM(
            t3.quantity
            * t3.unit_price
            * (1 - t3.discount)
        ) AS revenue

    FROM clients t1

    INNER JOIN orders t2
        ON t1.customer_id = t2.customer_id

    INNER JOIN order_items t3
        ON t2.order_id = t3.order_id

    WHERE t2.order_status = 'Concluído'

    GROUP BY
        t1.customer_id
),

ranked AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS customer_rank

    FROM customer_revenue
),

total AS (

    SELECT
        SUM(revenue) AS total_revenue
    FROM customer_revenue
)

SELECT

    t5.customer_id,
    t5.revenue,
    t5.customer_rank,

    t5.revenue / t6.total_revenue
        AS revenue_share

FROM ranked t5

CROSS JOIN total t6

WHERE t5.customer_rank <= 10

ORDER BY
    t5.customer_rank;


-- ============================================================
-- 9. RECEITA MENSAL
-- ============================================================

SELECT

    YEAR(t2.order_date) AS year,
    MONTH(t2.order_date) AS month,

    SUM(
        t3.quantity
        * t3.unit_price
        * (1 - t3.discount)
    ) AS revenue

FROM orders t2

INNER JOIN order_items t3
    ON t2.order_id = t3.order_id

WHERE t2.order_status = 'Concluído'

GROUP BY
    YEAR(t2.order_date),
    MONTH(t2.order_date)

ORDER BY
    year,
    month;


-- ============================================================
-- 10. TICKET MÉDIO
-- ============================================================

WITH order_revenue AS (

    SELECT

        t2.order_id,
        t2.customer_id,

        SUM(
            t3.quantity
            * t3.unit_price
            * (1 - t3.discount)
        ) AS order_revenue

    FROM orders t2

    INNER JOIN order_items t3
        ON t2.order_id = t3.order_id

    WHERE t2.order_status = 'Concluído'

    GROUP BY
        t2.order_id,
        t2.customer_id
)

SELECT

    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_revenue) AS revenue,

    SUM(order_revenue)
        / COUNT(*) AS average_ticket

FROM order_revenue

GROUP BY
    customer_id

ORDER BY
    revenue DESC;
