-- ============================================================
-- PROJETO 2 — SQL STARTER QUERIES
-- SQL SERVER
-- ============================================================

-- ============================================================
-- 1. BASE FINANCEIRA POR CLIENTE
-- ============================================================

SELECT
    c.customer_id,
    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount)
    ) AS revenue,

    SUM(
        oi.quantity
        * oi.unit_cost
    ) AS cost,

    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount)
        -
        oi.quantity
        * oi.unit_cost
    ) AS profit,

    MAX(o.order_date) AS last_purchase_date

FROM clients c

LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Concluído'

LEFT JOIN order_items oi
    ON o.order_id = oi.order_id

GROUP BY
    c.customer_id;


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
    p.category,

    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount)
    ) AS revenue,

    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount)
        -
        oi.quantity
        * oi.unit_cost
    ) AS profit

FROM order_items oi

INNER JOIN orders o
    ON oi.order_id = o.order_id

INNER JOIN products p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'Concluído'

GROUP BY
    p.category

ORDER BY
    revenue DESC;


-- ============================================================
-- 4. RECÊNCIA POR CLIENTE
-- ============================================================

SELECT
    c.customer_id,
    MAX(o.order_date) AS last_purchase_date,

    DATEDIFF(
        DAY,
        MAX(o.order_date),
        '2025-12-31'
    ) AS recency_days

FROM clients c

LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Concluído'

GROUP BY
    c.customer_id;


-- ============================================================
-- 5. STATUS DO CLIENTE
-- ============================================================

WITH last_purchase AS (

    SELECT
        c.customer_id,
        MAX(o.order_date) AS last_purchase_date

    FROM clients c

    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
        AND o.order_status = 'Concluído'

    GROUP BY
        c.customer_id
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

    c.customer_id,

    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount)
    ) AS revenue

FROM clients c

INNER JOIN orders o
    ON c.customer_id = o.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Concluído'

GROUP BY
    c.customer_id

ORDER BY
    revenue DESC;


-- ============================================================
-- 7. BASE RFM
-- ============================================================

SELECT

    c.customer_id,

    DATEDIFF(
        DAY,
        MAX(o.order_date),
        '2025-12-31'
    ) AS recency,

    COUNT(DISTINCT o.order_id) AS frequency,

    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount)
    ) AS monetary

FROM clients c

INNER JOIN orders o
    ON c.customer_id = o.customer_id

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Concluído'

GROUP BY
    c.customer_id;


-- ============================================================
-- 8. TOP 10 CLIENTES E PARTICIPAÇÃO DA RECEITA
-- ============================================================

WITH customer_revenue AS (

    SELECT
        c.customer_id,

        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - oi.discount)
        ) AS revenue

    FROM clients c

    INNER JOIN orders o
        ON c.customer_id = o.customer_id

    INNER JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Concluído'

    GROUP BY
        c.customer_id
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

    r.customer_id,
    r.revenue,
    r.customer_rank,

    r.revenue / t.total_revenue
        AS revenue_share

FROM ranked r

CROSS JOIN total t

WHERE r.customer_rank <= 10

ORDER BY
    r.customer_rank;


-- ============================================================
-- 9. RECEITA MENSAL
-- ============================================================

SELECT

    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,

    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount)
    ) AS revenue

FROM orders o

INNER JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Concluído'

GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date)

ORDER BY
    year,
    month;


-- ============================================================
-- 10. TICKET MÉDIO
-- ============================================================

WITH order_revenue AS (

    SELECT

        o.order_id,
        o.customer_id,

        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - oi.discount)
        ) AS order_revenue

    FROM orders o

    INNER JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Concluído'

    GROUP BY
        o.order_id,
        o.customer_id
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
