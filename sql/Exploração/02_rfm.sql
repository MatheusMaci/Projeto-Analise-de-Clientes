WITH rfm AS (
    SELECT
        t1.customer_id,

        CAST(
            julianday('2025-12-31') - julianday(MAX(t1.order_date))
            AS INTEGER
        ) AS recencia_dias,

        COUNT(DISTINCT t1.order_id) AS frequencia,

        ROUND(
            SUM(
                t2.quantity
                * t2.unit_price
                * (1 - t2.discount)
            ),
            2
        ) AS monetario

    FROM orders t1

    INNER JOIN order_items t2
        ON t1.order_id = t2.order_id

    WHERE t1.order_status = 'Concluído'

    GROUP BY t1.customer_id
),

rfm_score AS (
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

    FROM rfm t1
),

rfm_segmentado AS (
    SELECT
        t1.*,

        (
            t1.recencia_score
            + t1.frequencia_score
            + t1.monetario_score
        ) AS score_rfm,

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

    FROM rfm_score t1
)

SELECT *
FROM rfm_segmentado
ORDER BY score_rfm DESC
