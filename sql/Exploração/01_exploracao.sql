SELECT * FROM orders

order by order_date asc

limit 1

;

SELECT
    customer_segment,
    COUNT(*) AS total_clientes,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clientes),
        2
    ) AS percentual
FROM clientes
GROUP BY customer_segment
ORDER BY total_clientes DESC

;

SELECT
    region,
    COUNT(*) AS total_clientes,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clientes),
        2
    ) AS percentual
FROM clientes
GROUP BY region
ORDER BY total_clientes DESC

;


SELECT
    COUNT(DISTINCT t1.customer_id) AS clientes_com_pedido
FROM clientes t1
INNER JOIN orders t2
    ON t1.customer_id = t2.customer_id

;

SELECT
    COUNT(*) AS total_pedidos

FROM orders

;

SELECT
    order_status,
    COUNT(*) AS total_pedidos,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders),
        2
    ) AS percentual
FROM orders
GROUP BY order_status
ORDER BY total_pedidos DESC

;

SELECT
    ROUND(SUM(t2.quantity * t2.unit_price * (1 - t2.discount)), 2) AS receita,
    ROUND(SUM(t2.quantity * t2.unit_cost), 2) AS custo,
    ROUND(
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount))
        - SUM(t2.quantity * t2.unit_cost),
        2
    ) AS lucro
FROM orders t1
INNER JOIN order_items t2
    ON t1.order_id = t2.order_id
WHERE t1.order_status = 'Concluído'

;


SELECT
    ROUND(
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount))
        / COUNT(DISTINCT t1.order_id),
        2
    ) AS ticket_medio
FROM orders t1
INNER JOIN order_items t2
    ON t1.order_id = t2.order_id
WHERE t1.order_status = 'Concluído'

;


SELECT
    COUNT(DISTINCT t1.customer_id) AS clientes_compradores,
    COUNT(DISTINCT CASE
        WHEN t1.order_count >= 2 THEN t1.customer_id
    END) AS clientes_recorrentes
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    WHERE order_status = 'Concluído'
    GROUP BY customer_id
) t1

;

SELECT
    CASE
        WHEN julianday('2025-12-31') - julianday(t1.ultima_compra) <= 90
            THEN 'Ativo'
        WHEN julianday('2025-12-31') - julianday(t1.ultima_compra) > 180
            THEN 'Inativo'
        ELSE 'Atenção'
    END AS status_cliente,
    COUNT(*) AS total_clientes,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clientes),
        2
    ) AS percentual
FROM (
    SELECT
        customer_id,
        MAX(order_date) AS ultima_compra
    FROM orders
    WHERE order_status = 'Concluído'
    GROUP BY customer_id
) t1
GROUP BY status_cliente
ORDER BY total_clientes DESC

;

SELECT
    ano_primeira_compra,
    COUNT(*) AS novos_clientes
FROM (
    SELECT
        t1.customer_id,
        strftime('%Y', MIN(t1.order_date)) AS ano_primeira_compra
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
) t1
GROUP BY ano_primeira_compra
ORDER BY ano_primeira_compra

;

SELECT
    t2.customer_segment,
    COUNT(DISTINCT t1.customer_id) AS clientes_compradores
FROM orders t1
INNER JOIN clientes t2
    ON t1.customer_id = t2.customer_id
WHERE t1.order_status = 'Concluído'
GROUP BY t2.customer_segment
ORDER BY clientes_compradores DESC

;

SELECT
    t1.customer_segment,
    COUNT(DISTINCT t1.customer_id) AS total_clientes,
    COUNT(DISTINCT t2.customer_id) AS clientes_compradores,
    ROUND(
        COUNT(DISTINCT t2.customer_id) * 100.0
        / COUNT(DISTINCT t1.customer_id),
        2
    ) AS taxa_compra
FROM clientes t1
LEFT JOIN orders t2
    ON t1.customer_id = t2.customer_id
    AND t2.order_status = 'Concluído'
GROUP BY t1.customer_segment
ORDER BY taxa_compra DESC

;

SELECT
    t2.customer_segment,
    ROUND(SUM(t3.quantity * t3.unit_price * (1 - t3.discount)), 2) AS receita,
    ROUND(SUM(t3.quantity * t3.unit_cost), 2) AS custo,
    ROUND(
        SUM(t3.quantity * t3.unit_price * (1 - t3.discount))
        - SUM(t3.quantity * t3.unit_cost),
        2
    ) AS lucro
FROM orders t1
INNER JOIN clientes t2
    ON t1.customer_id = t2.customer_id
INNER JOIN order_items t3
    ON t1.order_id = t3.order_id
WHERE t1.order_status = 'Concluído'
GROUP BY t2.customer_segment
ORDER BY receita DESC

;


SELECT
    t2.customer_segment,
    COUNT(DISTINCT t1.customer_id) AS clientes_compradores,
    ROUND(
        SUM(t3.quantity * t3.unit_price * (1 - t3.discount))
        / COUNT(DISTINCT t1.customer_id),
        2
    ) AS receita_media_cliente
FROM orders t1
INNER JOIN clientes t2
    ON t1.customer_id = t2.customer_id
INNER JOIN order_items t3
    ON t1.order_id = t3.order_id
WHERE t1.order_status = 'Concluído'
GROUP BY t2.customer_segment
ORDER BY receita_media_cliente DESC

;

SELECT
    t2.customer_segment,
    COUNT(DISTINCT t1.order_id) AS total_pedidos,
    COUNT(DISTINCT t1.customer_id) AS clientes_compradores,
    ROUND(
        COUNT(DISTINCT t1.order_id) * 1.0
        / COUNT(DISTINCT t1.customer_id),
        2
    ) AS pedidos_medios_cliente
FROM orders t1
INNER JOIN clientes t2
    ON t1.customer_id = t2.customer_id
WHERE t1.order_status = 'Concluído'
GROUP BY t2.customer_segment
ORDER BY pedidos_medios_cliente DESC

;

SELECT
    t2.customer_segment,
    ROUND(
        SUM(t3.quantity * t3.unit_price * (1 - t3.discount))
        / COUNT(DISTINCT t1.order_id),
        2
    ) AS ticket_medio
FROM orders t1
INNER JOIN clientes t2
    ON t1.customer_id = t2.customer_id
INNER JOIN order_items t3
    ON t1.order_id = t3.order_id
WHERE t1.order_status = 'Concluído'
GROUP BY t2.customer_segment
ORDER BY ticket_medio DESC

;

SELECT
    t2.customer_segment,
    ROUND(
        SUM(t3.quantity) * 1.0
        / COUNT(DISTINCT t1.order_id),
        2
    ) AS itens_medios_pedido
FROM orders t1
INNER JOIN clientes t2
    ON t1.customer_id = t2.customer_id
INNER JOIN order_items t3
    ON t1.order_id = t3.order_id
WHERE t1.order_status = 'Concluído'
GROUP BY t2.customer_segment
ORDER BY itens_medios_pedido DESC

;

SELECT
    t1.customer_id,
    CAST(
        julianday('2025-12-31') - julianday(MAX(t1.order_date))
        AS INTEGER
    ) AS recencia_dias,
    COUNT(DISTINCT t1.order_id) AS frequencia,
    ROUND(
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)),
        2
    ) AS monetario
FROM orders t1
INNER JOIN order_items t2
    ON t1.order_id = t2.order_id
WHERE t1.order_status = 'Concluído'
GROUP BY t1.customer_id

;

SELECT
    t1.customer_id,
    t1.recencia_dias,
    t1.frequencia,
    t1.monetario,

    NTILE(5) OVER (
        ORDER BY t1.recencia_dias DESC
    ) AS recencia_score,

    NTILE(5) OVER (
        ORDER BY t1.frequencia ASC
    ) AS frequencia_score,

    NTILE(5) OVER (
        ORDER BY t1.monetario ASC
    ) AS monetario_score

FROM (
    SELECT
        t1.customer_id,
        CAST(
            julianday('2025-12-31') - julianday(MAX(t1.order_date))
            AS INTEGER
        ) AS recencia_dias,
        COUNT(DISTINCT t1.order_id) AS frequencia,
        ROUND(
            SUM(t2.quantity * t2.unit_price * (1 - t2.discount)),
            2
        ) AS monetario
    FROM orders t1
    INNER JOIN order_items t2
        ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
) t1

;

SELECT
    t1.customer_id,
    t1.recencia_score,
    t1.frequencia_score,
    t1.monetario_score,
    CAST(t1.recencia_score AS TEXT)
        || CAST(t1.frequencia_score AS TEXT)
        || CAST(t1.monetario_score AS TEXT) AS rfm_score
FROM (
    SELECT
        t1.customer_id,
        NTILE(5) OVER (ORDER BY t1.recencia_dias DESC) AS recencia_score,
        NTILE(5) OVER (ORDER BY t1.frequencia ASC) AS frequencia_score,
        NTILE(5) OVER (ORDER BY t1.monetario ASC) AS monetario_score
    FROM (
        SELECT
            t1.customer_id,
            CAST(
                julianday('2025-12-31') - julianday(MAX(t1.order_date))
                AS INTEGER
            ) AS recencia_dias,
            COUNT(DISTINCT t1.order_id) AS frequencia,
            SUM(
                t2.quantity * t2.unit_price * (1 - t2.discount)
            ) AS monetario
        FROM orders t1
        INNER JOIN order_items t2
            ON t1.order_id = t2.order_id
        WHERE t1.order_status = 'Concluído'
        GROUP BY t1.customer_id
    ) t1
) t1

;
SELECT
    t1.customer_id,
    t1.recencia_score,
    t1.frequencia_score,
    t1.monetario_score,
    t1.rfm_score,

    CASE
        WHEN t1.recencia_score >= 4
             AND t1.frequencia_score >= 4
             AND t1.monetario_score >= 4
            THEN 'Campeões'

        WHEN t1.recencia_score >= 3
             AND t1.frequencia_score >= 4
            THEN 'Clientes Fiéis'

        WHEN t1.frequencia_score >= 3
             AND t1.monetario_score >= 4
            THEN 'Alto Valor'

        WHEN t1.recencia_score >= 4
             AND t1.frequencia_score BETWEEN 2 AND 3
            THEN 'Potenciais Fiéis'

        WHEN t1.recencia_score = 5
             AND t1.frequencia_score <= 2
            THEN 'Recentes'

        WHEN t1.recencia_score BETWEEN 2 AND 3
             AND t1.frequencia_score <= 3
            THEN 'Em Atenção'

        WHEN t1.recencia_score <= 2
             AND t1.frequencia_score >= 3
            THEN 'Em Risco'

        WHEN t1.recencia_score = 1
             AND t1.frequencia_score <= 2
            THEN 'Hibernando'

        ELSE 'Outros'
    END AS segmento_rfm

FROM (
    SELECT
    t1.customer_id,
    t1.recencia_score,
    t1.frequencia_score,
    t1.monetario_score,
    CAST(t1.recencia_score AS TEXT)
        || CAST(t1.frequencia_score AS TEXT)
        || CAST(t1.monetario_score AS TEXT) AS rfm_score
FROM (
    SELECT
        t1.customer_id,
        NTILE(5) OVER (ORDER BY t1.recencia_dias DESC) AS recencia_score,
        NTILE(5) OVER (ORDER BY t1.frequencia ASC) AS frequencia_score,
        NTILE(5) OVER (ORDER BY t1.monetario ASC) AS monetario_score
    FROM (
        SELECT
            t1.customer_id,
            CAST(
                julianday('2025-12-31') - julianday(MAX(t1.order_date))
                AS INTEGER
            ) AS recencia_dias,
            COUNT(DISTINCT t1.order_id) AS frequencia,
            SUM(
                t2.quantity * t2.unit_price * (1 - t2.discount)
            ) AS monetario
        FROM orders t1
        INNER JOIN order_items t2
            ON t1.order_id = t2.order_id
        WHERE t1.order_status = 'Concluído'
        GROUP BY t1.customer_id
    ) t1
) t1
) t1


;

