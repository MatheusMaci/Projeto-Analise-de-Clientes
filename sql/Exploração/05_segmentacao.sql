SELECT
    CASE
        WHEN t1.total_pedidos = 1 THEN 'Apenas 1 compra'
        WHEN t1.total_pedidos BETWEEN 2 AND 3 THEN '2–3 compras'
        WHEN t1.total_pedidos BETWEEN 4 AND 6 THEN '4–6 compras'
        ELSE '7+ compras'
    END AS faixa_frequencia,

    COUNT(*) AS total_clientes,

    ROUND(
        COUNT(*) * 100.0
        / (SELECT COUNT(*) FROM (
            SELECT customer_id
            FROM orders
            WHERE order_status = 'Concluído'
            GROUP BY customer_id
        )),
        2
    ) AS percentual

FROM (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS total_pedidos
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
) t1

GROUP BY faixa_frequencia
ORDER BY
    CASE faixa_frequencia
        WHEN 'Apenas 1 compra' THEN 1
        WHEN '2–3 compras' THEN 2
        WHEN '4–6 compras' THEN 3
        ELSE 4
    END

;

WITH clientes_valor AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS total_pedidos,
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
)
SELECT
    CASE
        WHEN t1.receita < 1000 THEN 'Até R$ 1 mil'
        WHEN t1.receita < 3000 THEN 'R$ 1–3 mil'
        WHEN t1.receita < 7000 THEN 'R$ 3–7 mil'
        WHEN t1.receita < 15000 THEN 'R$ 7–15 mil'
        ELSE 'Acima de R$ 15 mil'
    END AS faixa_valor,

    COUNT(*) AS total_clientes,

    ROUND(SUM(t1.receita), 2) AS receita_total,

    ROUND(AVG(t1.receita), 2) AS receita_media

FROM clientes_valor t1
GROUP BY faixa_valor
ORDER BY
    CASE faixa_valor
        WHEN 'Até R$ 1 mil' THEN 1
        WHEN 'R$ 1–3 mil' THEN 2
        WHEN 'R$ 3–7 mil' THEN 3
        WHEN 'R$ 7–15 mil' THEN 4
        ELSE 5
    END

    ;

WITH clientes AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS frequencia,
        SUM(
            t2.quantity * t2.unit_price * (1 - t2.discount)
        ) AS receita
    FROM orders t1
    INNER JOIN order_items t2
        ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
)
SELECT
    CASE
        WHEN frequencia >= 4 AND receita >= 7000
            THEN 'Alto valor e recorrente'

        WHEN frequencia >= 4 AND receita < 7000
            THEN 'Recorrente'

        WHEN frequencia < 4 AND receita >= 7000
            THEN 'Alto valor'

        ELSE 'Baixa frequência e valor'
    END AS segmento,

    COUNT(*) AS total_clientes,

    ROUND(SUM(receita), 2) AS receita_total,

    ROUND(AVG(receita), 2) AS receita_media,

    ROUND(AVG(frequencia), 2) AS frequencia_media

FROM clientes
GROUP BY segmento
ORDER BY receita_total DESC

;

WITH clientes AS (
    SELECT
        t1.customer_id,
        CAST(
            julianday('2025-12-31') - julianday(MAX(t1.order_date))
            AS INTEGER
        ) AS recencia_dias,
        COUNT(DISTINCT t1.order_id) AS frequencia
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
)
SELECT
    CASE
        WHEN recencia_dias <= 90 AND frequencia >= 4
            THEN 'Recorrente ativo'

        WHEN recencia_dias > 180 AND frequencia >= 4
            THEN 'Recorrente em risco'

        WHEN recencia_dias <= 90 AND frequencia < 4
            THEN 'Cliente recente/ocasional'

        WHEN recencia_dias > 180 AND frequencia < 4
            THEN 'Baixa frequência e inativo'

        ELSE 'Em atenção'
    END AS segmento,

    COUNT(*) AS total_clientes,

    ROUND(AVG(recencia_dias), 2) AS recencia_media,

    ROUND(AVG(frequencia), 2) AS frequencia_media

FROM clientes
GROUP BY segmento
ORDER BY total_clientes DESC

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
)

SELECT
    customer_id,
    recencia_dias,
    frequencia,
    ROUND(monetario, 2) AS monetario,

    recencia_score,
    frequencia_score,
    monetario_score,

    recencia_score
        + frequencia_score
        + monetario_score AS score_rfm,

    CASE
        WHEN recencia_score >= 4
             AND frequencia_score >= 4
             AND monetario_score >= 4
            THEN 'Campeões'

        WHEN recencia_score >= 3
             AND frequencia_score >= 4
            THEN 'Clientes Fiéis'

        WHEN frequencia_score >= 3
             AND monetario_score >= 4
            THEN 'Alto Valor'

        WHEN recencia_score >= 4
             AND frequencia_score BETWEEN 2 AND 3
            THEN 'Potenciais Fiéis'

        WHEN recencia_score = 5
             AND frequencia_score <= 2
            THEN 'Recentes'

        WHEN recencia_score BETWEEN 2 AND 3
             AND frequencia_score <= 3
            THEN 'Em Atenção'

        WHEN recencia_score <= 2
             AND frequencia_score >= 3
            THEN 'Em Risco'

        WHEN recencia_score = 1
             AND frequencia_score <= 2
            THEN 'Hibernando'

        ELSE 'Outros'
    END AS segmento_rfm

FROM scores
ORDER BY score_rfm DESC

;