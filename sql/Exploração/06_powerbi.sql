WITH clientes_base AS (
    SELECT
        t1.customer_id,
        t1.customer_segment,
        t1.state,
        t1.region
    FROM clientes t1
),

metricas AS (
    SELECT
        t1.customer_id,

        COUNT(DISTINCT t1.order_id) AS total_pedidos,

        MAX(t1.order_date) AS ultima_compra,

        SUM(
            t2.quantity * t2.unit_price * (1 - t2.discount)
        ) AS receita,

        SUM(
            t2.quantity * t2.unit_cost
        ) AS custo

    FROM orders t1

    INNER JOIN order_items t2
        ON t1.order_id = t2.order_id

    WHERE t1.order_status = 'Concluído'

    GROUP BY t1.customer_id
)

SELECT
    t1.customer_id,
    t1.customer_segment,
    t1.state,
    t1.region,

    COALESCE(t2.total_pedidos, 0) AS total_pedidos,

    ROUND(COALESCE(t2.receita, 0), 2) AS receita,

    ROUND(
        COALESCE(t2.receita, 0)
        - COALESCE(t2.custo, 0),
        2
    ) AS lucro,

    t2.ultima_compra,

    CASE
        WHEN t2.ultima_compra IS NULL
            THEN 'Sem compra'

        WHEN julianday('2025-12-31')
             - julianday(t2.ultima_compra) <= 90
            THEN 'Ativo'

        WHEN julianday('2025-12-31')
             - julianday(t2.ultima_compra) > 180
            THEN 'Inativo'

        ELSE 'Atenção'
    END AS status_cliente

FROM clientes_base t1

LEFT JOIN metricas t2
    ON t1.customer_id = t2.customer_id

;

WITH clientes_base AS (
    SELECT
        t1.customer_id,
        t1.customer_segment,
        t1.state,
        t1.region
    FROM clientes t1
),

metricas AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS total_pedidos,
        MAX(t1.order_date) AS ultima_compra,
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)) AS receita,
        SUM(t2.quantity * t2.unit_cost) AS custo
    FROM orders t1
    INNER JOIN order_items t2
        ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),

rfm AS (
    SELECT
        t1.customer_id,

        CAST(
            julianday('2025-12-31')
            - julianday(MAX(t1.order_date))
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
),

scores AS (
    SELECT
        t1.*,

        NTILE(5) OVER (
            ORDER BY t1.recencia_dias DESC
        ) AS recencia_score,

        NTILE(5) OVER (
            ORDER BY t1.frequencia ASC
        ) AS frequencia_score,

        NTILE(5) OVER (
            ORDER BY t1.monetario ASC
        ) AS monetario_score

    FROM rfm t1
),

rfm_final AS (
    SELECT
        t1.*,

        t1.recencia_score
        + t1.frequencia_score
        + t1.monetario_score AS score_rfm,

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

    FROM scores t1
)

SELECT
    t1.customer_id,
    t1.customer_segment,
    t1.state,
    t1.region,

    COALESCE(t2.total_pedidos, 0) AS total_pedidos,

    ROUND(COALESCE(t2.receita, 0), 2) AS receita,

    ROUND(
        COALESCE(t2.receita, 0)
        - COALESCE(t2.custo, 0),
        2
    ) AS lucro,

    t2.ultima_compra,

    CASE
        WHEN t2.ultima_compra IS NULL
            THEN 'Sem compra'
        WHEN julianday('2025-12-31')
             - julianday(t2.ultima_compra) <= 90
            THEN 'Ativo'
        WHEN julianday('2025-12-31')
             - julianday(t2.ultima_compra) > 180
            THEN 'Inativo'
        ELSE 'Atenção'
    END AS status_cliente,

    t3.recencia_dias,
    t3.frequencia,
    ROUND(t3.monetario, 2) AS monetario,
    t3.recencia_score,
    t3.frequencia_score,
    t3.monetario_score,
    t3.score_rfm,
    t3.segmento_rfm

FROM clientes_base t1

LEFT JOIN metricas t2
    ON t1.customer_id = t2.customer_id

LEFT JOIN rfm_final t3
    ON t1.customer_id = t3.customer_id

;

SELECT
    strftime('%Y-%m', t1.order_date) AS mes,

    COUNT(DISTINCT t1.order_id) AS pedidos,

    COUNT(DISTINCT t1.customer_id) AS clientes_compradores,

    ROUND(
        SUM(
            t2.quantity
            * t2.unit_price
            * (1 - t2.discount)
        ),
        2
    ) AS receita,

    ROUND(
        SUM(
            t2.quantity * t2.unit_price * (1 - t2.discount)
        )
        -
        SUM(
            t2.quantity * t2.unit_cost
        ),
        2
    ) AS lucro

FROM orders t1

INNER JOIN order_items t2
    ON t1.order_id = t2.order_id

WHERE t1.order_status = 'Concluído'

GROUP BY strftime('%Y-%m', t1.order_date)

ORDER BY mes

;

WITH rfm AS (
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
),

scores AS (
    SELECT
        t1.*,

        NTILE(5) OVER (ORDER BY t1.recencia_dias DESC) AS recencia_score,
        NTILE(5) OVER (ORDER BY t1.frequencia ASC) AS frequencia_score,
        NTILE(5) OVER (ORDER BY t1.monetario ASC) AS monetario_score

    FROM rfm t1
),

segmentacao AS (
    SELECT
        t1.*,

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

    FROM scores t1
)

SELECT
    t1.segmento_rfm,

    COUNT(*) AS total_clientes,

    ROUND(SUM(t1.monetario), 2) AS receita_total,

    ROUND(AVG(t1.monetario), 2) AS receita_media_cliente,

    ROUND(AVG(t1.frequencia), 2) AS frequencia_media,

    ROUND(AVG(t1.recencia_dias), 2) AS recencia_media

FROM segmentacao t1

GROUP BY t1.segmento_rfm

ORDER BY receita_total DESC

;

WITH base_clientes AS (
    SELECT
        t1.customer_id,

        CASE
            WHEN t2.ultima_compra IS NULL
                THEN 'Sem compra'

            WHEN julianday('2025-12-31')
                 - julianday(t2.ultima_compra) <= 90
                THEN 'Ativo'

            WHEN julianday('2025-12-31')
                 - julianday(t2.ultima_compra) > 180
                THEN 'Inativo'

            ELSE 'Atenção'
        END AS status_cliente,

        COALESCE(t2.receita, 0) AS receita

    FROM clientes t1

    LEFT JOIN (
        SELECT
            t1.customer_id,
            MAX(t1.order_date) AS ultima_compra,

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
    ) t2
        ON t1.customer_id = t2.customer_id
)

SELECT
    status_cliente,

    COUNT(*) AS total_clientes,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_clientes,

    ROUND(SUM(receita), 2) AS receita_total,

    ROUND(AVG(receita), 2) AS receita_media_cliente

FROM base_clientes

GROUP BY status_cliente

ORDER BY
    CASE status_cliente
        WHEN 'Ativo' THEN 1
        WHEN 'Atenção' THEN 2
        WHEN 'Inativo' THEN 3
        WHEN 'Sem compra' THEN 4
    END

;