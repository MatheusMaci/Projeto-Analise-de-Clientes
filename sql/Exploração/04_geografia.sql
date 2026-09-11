SELECT
    t1.region,
    COUNT(DISTINCT t1.customer_id) AS total_clientes,
    COUNT(DISTINCT CASE
        WHEN t2.order_status = 'Concluído'
        THEN t1.customer_id
    END) AS clientes_compradores,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN t2.order_status = 'Concluído'
            THEN t1.customer_id
        END) * 100.0
        / COUNT(DISTINCT t1.customer_id),
        2
    ) AS taxa_compra,

    ROUND(
        COALESCE(
            SUM(
                CASE
                    WHEN t2.order_status = 'Concluído'
                    THEN t3.quantity
                         * t3.unit_price
                         * (1 - t3.discount)
                END
            ),
            0
        ),
        2
    ) AS receita

FROM clientes t1

LEFT JOIN orders t2
    ON t1.customer_id = t2.customer_id

LEFT JOIN order_items t3
    ON t2.order_id = t3.order_id

GROUP BY t1.region
ORDER BY receita DESC

;

SELECT
    t1.region,

    COUNT(DISTINCT CASE
        WHEN t2.order_status = 'Concluído'
        THEN t1.customer_id
    END) AS clientes_compradores,

    COUNT(DISTINCT CASE
        WHEN t2.order_status = 'Concluído'
        THEN t2.order_id
    END) AS total_pedidos,

    ROUND(
        SUM(
            CASE
                WHEN t2.order_status = 'Concluído'
                THEN t3.quantity
                     * t3.unit_price
                     * (1 - t3.discount)
                ELSE 0
            END
        )
        / COUNT(DISTINCT CASE
            WHEN t2.order_status = 'Concluído'
            THEN t1.customer_id
        END),
        2
    ) AS receita_media_cliente,

    ROUND(
        SUM(
            CASE
                WHEN t2.order_status = 'Concluído'
                THEN t3.quantity
                     * t3.unit_price
                     * (1 - t3.discount)
                ELSE 0
            END
        )
        / COUNT(DISTINCT CASE
            WHEN t2.order_status = 'Concluído'
            THEN t2.order_id
        END),
        2
    ) AS ticket_medio

FROM clientes t1

LEFT JOIN orders t2
    ON t1.customer_id = t2.customer_id

LEFT JOIN order_items t3
    ON t2.order_id = t3.order_id

GROUP BY t1.region
ORDER BY receita_media_cliente DESC

;

SELECT
    t1.state,

    COUNT(DISTINCT t1.customer_id) AS total_clientes,

    COUNT(DISTINCT CASE
        WHEN t2.order_status = 'Concluído'
        THEN t1.customer_id
    END) AS clientes_compradores,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN t2.order_status = 'Concluído'
            THEN t1.customer_id
        END) * 100.0
        / COUNT(DISTINCT t1.customer_id),
        2
    ) AS taxa_compra,

    ROUND(
        SUM(
            CASE
                WHEN t2.order_status = 'Concluído'
                THEN t3.quantity
                     * t3.unit_price
                     * (1 - t3.discount)
                ELSE 0
            END
        ),
        2
    ) AS receita

FROM clientes t1

LEFT JOIN orders t2
    ON t1.customer_id = t2.customer_id

LEFT JOIN order_items t3
    ON t2.order_id = t3.order_id

GROUP BY t1.state
ORDER BY receita DESC

;

WITH receita_cliente AS (
    SELECT
        t1.customer_id,
        SUM(
            t2.quantity
            * t2.unit_price
            * (1 - t2.discount)
        ) AS receita
    FROM orders t1
    INNER JOIN order_items t2
        ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),
ranking AS (
    SELECT
        t1.customer_id,
        t1.receita,
        SUM(t1.receita) OVER (
            ORDER BY t1.receita DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS receita_acumulada,
        SUM(t1.receita) OVER () AS receita_total
    FROM receita_cliente t1
)
SELECT
    customer_id,
    ROUND(receita, 2) AS receita,
    ROUND(
        receita_acumulada * 100.0 / receita_total,
        2
    ) AS percentual_acumulado
FROM ranking
ORDER BY receita DESC

;