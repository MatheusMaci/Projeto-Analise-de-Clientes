WITH compras AS (
    SELECT
        t1.customer_id,
        t1.order_date,
        LAG(t1.order_date) OVER (
            PARTITION BY t1.customer_id
            ORDER BY t1.order_date
        ) AS compra_anterior
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
),

intervalos AS (
    SELECT
        t1.customer_id,
        CAST(
            julianday(t1.order_date)
            - julianday(t1.compra_anterior)
            AS INTEGER
        ) AS dias_entre_compras
    FROM compras t1
    WHERE t1.compra_anterior IS NOT NULL
)

SELECT
    COUNT(*) AS total_intervalos,
    ROUND(AVG(dias_entre_compras), 2) AS media_dias,
    MIN(dias_entre_compras) AS menor_intervalo,
    MAX(dias_entre_compras) AS maior_intervalo
FROM intervalos

;

WITH compras AS (
    SELECT
        t1.customer_id,
        t1.order_date,
        LAG(t1.order_date) OVER (
            PARTITION BY t1.customer_id
            ORDER BY t1.order_date
        ) AS compra_anterior
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
),

intervalos AS (
    SELECT
        t1.customer_id,
        CAST(
            julianday(t1.order_date)
            - julianday(t1.compra_anterior)
            AS INTEGER
        ) AS dias_entre_compras
    FROM compras t1
    WHERE t1.compra_anterior IS NOT NULL
)

SELECT
    CASE
        WHEN dias_entre_compras <= 30 THEN 'Até 30 dias'
        WHEN dias_entre_compras <= 60 THEN '31–60 dias'
        WHEN dias_entre_compras <= 90 THEN '61–90 dias'
        WHEN dias_entre_compras <= 180 THEN '91–180 dias'
        WHEN dias_entre_compras <= 365 THEN '181–365 dias'
        ELSE 'Mais de 365 dias'
    END AS faixa_intervalo,

    COUNT(*) AS total_intervalos,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM intervalos),
        2
    ) AS percentual

FROM intervalos
GROUP BY faixa_intervalo
ORDER BY
    CASE faixa_intervalo
        WHEN 'Até 30 dias' THEN 1
        WHEN '31–60 dias' THEN 2
        WHEN '61–90 dias' THEN 3
        WHEN '91–180 dias' THEN 4
        WHEN '181–365 dias' THEN 5
        WHEN 'Mais de 365 dias' THEN 6
    END

    ;

WITH primeira_compra AS (
    SELECT
        t1.customer_id,
        CAST(strftime('%Y', MIN(t1.order_date)) AS INTEGER) AS ano_primeira_compra
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),

compras_ano AS (
    SELECT DISTINCT
        t1.customer_id,
        CAST(strftime('%Y', t1.order_date) AS INTEGER) AS ano_compra
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
)

SELECT
    t1.ano_primeira_compra,
    COUNT(*) AS clientes_corte,

    COUNT(
        CASE
            WHEN t2.ano_compra = t1.ano_primeira_compra + 1
            THEN 1
        END
    ) AS clientes_retidos_ano_seguinte,

    ROUND(
        COUNT(
            CASE
                WHEN t2.ano_compra = t1.ano_primeira_compra + 1
                THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS taxa_retencao

FROM primeira_compra t1

LEFT JOIN compras_ano t2
    ON t1.customer_id = t2.customer_id

GROUP BY t1.ano_primeira_compra
ORDER BY t1.ano_primeira_compra

;


WITH receita_cliente AS (
    SELECT
        t1.customer_id,
        ROUND(
            SUM(
                t2.quantity
                * t2.unit_price
                * (1 - t2.discount)
            ),
            2
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
    receita,
    ROUND(
        receita_acumulada * 100.0 / receita_total,
        2
    ) AS percentual_acumulado
FROM ranking
ORDER BY receita DESC

;

SELECT
    strftime('%Y-%m', t1.order_date) AS mes,
    COUNT(DISTINCT t1.customer_id) AS clientes_compradores
FROM orders t1
WHERE t1.order_status = 'Concluído'
GROUP BY strftime('%Y-%m', t1.order_date)
ORDER BY mes

;

WITH primeira_compra AS (
    SELECT
        t1.customer_id,
        MIN(t1.order_date) AS primeira_compra
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),

classificacao AS (
    SELECT
        t1.order_id,
        t1.customer_id,
        t1.order_date,
        CASE
            WHEN t1.order_date = t2.primeira_compra
                THEN 'Novo'
            ELSE 'Recorrente'
        END AS tipo_cliente
    FROM orders t1
    INNER JOIN primeira_compra t2
        ON t1.customer_id = t2.customer_id
    WHERE t1.order_status = 'Concluído'
)

SELECT
    strftime('%Y-%m', t1.order_date) AS mes,

    COUNT(DISTINCT CASE
        WHEN t1.tipo_cliente = 'Novo'
        THEN t1.customer_id
    END) AS clientes_novos,

    COUNT(DISTINCT CASE
        WHEN t1.tipo_cliente = 'Recorrente'
        THEN t1.customer_id
    END) AS clientes_recorrentes

FROM classificacao t1
GROUP BY strftime('%Y-%m', t1.order_date)
ORDER BY mes

;

WITH ultima_compra AS (
    SELECT
        t1.customer_id,
        MAX(t1.order_date) AS ultima_compra
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),

status_cliente AS (
    SELECT
        t1.customer_id,
        t2.customer_segment,
        CASE
            WHEN julianday('2025-12-31')
                 - julianday(t1.ultima_compra) <= 90
                THEN 'Ativo'

            WHEN julianday('2025-12-31')
                 - julianday(t1.ultima_compra) > 180
                THEN 'Inativo'

            ELSE 'Atenção'
        END AS status_cliente
    FROM ultima_compra t1
    INNER JOIN clientes t2
        ON t1.customer_id = t2.customer_id
)

SELECT
    customer_segment,
    status_cliente,
    COUNT(*) AS total_clientes,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (
            PARTITION BY customer_segment
        ),
        2
    ) AS percentual_segmento

FROM status_cliente
GROUP BY
    customer_segment,
    status_cliente

ORDER BY
    customer_segment,
    total_clientes DESC

    ;

WITH pedidos_cliente AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS total_pedidos
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
)

SELECT
    CASE
        WHEN t1.total_pedidos = 1 THEN 'Apenas 1 compra'
        ELSE '2 ou mais compras'
    END AS tipo_cliente,

    COUNT(*) AS total_clientes,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM pedidos_cliente),
        2
    ) AS percentual

FROM pedidos_cliente t1
GROUP BY tipo_cliente
ORDER BY total_clientes DESC

;

WITH pedidos_cliente AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS total_pedidos
    FROM orders t1
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
)

SELECT
    t2.customer_segment,

    COUNT(*) AS clientes,

    COUNT(
        CASE
            WHEN t1.total_pedidos >= 2 THEN 1
        END
    ) AS clientes_recorrentes,

    ROUND(
        COUNT(
            CASE
                WHEN t1.total_pedidos >= 2 THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS taxa_recompra

FROM pedidos_cliente t1

INNER JOIN clientes t2
    ON t1.customer_id = t2.customer_id

GROUP BY t2.customer_segment
ORDER BY taxa_recompra DESC

;

WITH compras AS (
    SELECT
        t1.customer_id,
        t1.order_date,

        LAG(t1.order_date) OVER (
            PARTITION BY t1.customer_id
            ORDER BY t1.order_date
        ) AS compra_anterior

    FROM orders t1

    WHERE t1.order_status = 'Concluído'
),

reativacoes AS (
    SELECT
        t1.customer_id,
        t1.order_date,
        CAST(
            julianday(t1.order_date)
            - julianday(t1.compra_anterior)
            AS INTEGER
        ) AS dias_sem_comprar

    FROM compras t1

    WHERE t1.compra_anterior IS NOT NULL
      AND julianday(t1.order_date)
          - julianday(t1.compra_anterior) > 180
)

SELECT
    COUNT(*) AS total_reativacoes,
    COUNT(DISTINCT customer_id) AS clientes_reativados,

    ROUND(
        AVG(dias_sem_comprar),
        2
    ) AS media_dias_ate_reativacao,

    MAX(dias_sem_comprar) AS maior_periodo_inativo

FROM reativacoes

;