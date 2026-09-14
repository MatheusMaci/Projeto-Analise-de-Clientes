-- Projeto 2 - Análise de Clientes
-- Consultas principais | SQLite
--
-- Regras:
-- pedidos concluídos = base das análises
-- receita = quantidade * preço * (1 - desconto)
-- custo = quantidade * custo unitário
-- lucro = receita - custo
-- recorrente = 2+ pedidos concluídos
-- ativo <= 90 dias | atenção 91–180 | inativo > 180
-- data de referência RFM/status: 2025-12-31


/* ============================================================
   1. VISÃO GERAL
   ============================================================ */

SELECT
    COUNT(DISTINCT t1.order_id) AS pedidos,
    COUNT(DISTINCT t1.customer_id) AS clientes_compradores,
    ROUND(SUM(t2.quantity * t2.unit_price * (1 - t2.discount)), 2) AS receita,
    ROUND(SUM(t2.quantity * t2.unit_cost), 2) AS custo,
    ROUND(
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount))
        - SUM(t2.quantity * t2.unit_cost), 2
    ) AS lucro,
    ROUND(
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount))
        / COUNT(DISTINCT t1.order_id), 2
    ) AS ticket_medio
FROM orders t1
JOIN order_items t2 ON t1.order_id = t2.order_id
WHERE t1.order_status = 'Concluído';


/* ============================================================
   2. EVOLUÇÃO MENSAL
   ============================================================ */

SELECT
    strftime('%Y-%t4', t1.order_date) AS mes,
    COUNT(DISTINCT t1.order_id) AS pedidos,
    COUNT(DISTINCT t1.customer_id) AS clientes_compradores,
    ROUND(SUM(t2.quantity * t2.unit_price * (1 - t2.discount)), 2) AS receita,
    ROUND(
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount))
        - SUM(t2.quantity * t2.unit_cost), 2
    ) AS lucro
FROM orders t1
JOIN order_items t2 ON t1.order_id = t2.order_id
WHERE t1.order_status = 'Concluído'
GROUP BY mes
ORDER BY mes;


/* ============================================================
   3. FREQUÊNCIA E RECORRÊNCIA
   ============================================================ */

WITH clientes AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_pedidos
    FROM orders
    WHERE order_status = 'Concluído'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN total_pedidos = 1 THEN 'Apenas 1 compra'
        WHEN total_pedidos BETWEEN 2 AND 3 THEN '2–3 compras'
        WHEN total_pedidos BETWEEN 4 AND 6 THEN '4–6 compras'
        ELSE '7+ compras'
    END AS faixa_frequencia,
    COUNT(*) AS total_clientes,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM clientes), 2) AS percentual
FROM clientes
GROUP BY faixa_frequencia
ORDER BY
    CASE faixa_frequencia
        WHEN 'Apenas 1 compra' THEN 1
        WHEN '2–3 compras' THEN 2
        WHEN '4–6 compras' THEN 3
        ELSE 4
    END;


/* ============================================================
   4. INTERVALO ENTRE COMPRAS
   ============================================================ */

WITH compras AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id ORDER BY order_date
        ) AS compra_anterior
    FROM orders
    WHERE order_status = 'Concluído'
),
intervalos AS (
    SELECT
        CAST(
            julianday(order_date) - julianday(compra_anterior)
            AS INTEGER
        ) AS dias_entre_compras
    FROM compras
    WHERE compra_anterior IS NOT NULL
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
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM intervalos), 2
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
        ELSE 6
    END;


/* ============================================================
   5. STATUS DA BASE
   ============================================================ */

WITH metricas AS (
    SELECT
        t1.customer_id,
        MAX(t1.order_date) AS ultima_compra,
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)) AS receita
    FROM orders t1
    JOIN order_items t2 ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),
base AS (
    SELECT
        t3.customer_id,
        CASE
            WHEN t4.ultima_compra IS NULL THEN 'Sem compra'
            WHEN julianday('2025-12-31') - julianday(t4.ultima_compra) <= 90
                THEN 'Ativo'
            WHEN julianday('2025-12-31') - julianday(t4.ultima_compra) > 180
                THEN 'Inativo'
            ELSE 'Atenção'
        END AS status_cliente,
        COALESCE(t4.receita, 0) AS receita
    FROM clientes t3
    LEFT JOIN metricas t4 ON t3.customer_id = t4.customer_id
)
SELECT
    status_cliente,
    COUNT(*) AS total_clientes,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentual_clientes,
    ROUND(SUM(receita), 2) AS receita_total,
    ROUND(AVG(receita), 2) AS receita_media_cliente
FROM base
GROUP BY status_cliente
ORDER BY
    CASE status_cliente
        WHEN 'Ativo' THEN 1
        WHEN 'Atenção' THEN 2
        WHEN 'Inativo' THEN 3
        ELSE 4
    END;


/* ============================================================
   6. RETENÇÃO POR COORTE
   ============================================================ */

WITH primeira_compra AS (
    SELECT
        customer_id,
        CAST(strftime('%Y', MIN(order_date)) AS INTEGER) AS ano_primeira_compra
    FROM orders
    WHERE order_status = 'Concluído'
    GROUP BY customer_id
),
compras_ano AS (
    SELECT DISTINCT
        customer_id,
        CAST(strftime('%Y', order_date) AS INTEGER) AS ano_compra
    FROM orders
    WHERE order_status = 'Concluído'
)
SELECT
    t5.ano_primeira_compra,
    COUNT(*) AS clientes_coorte,
    COUNT(
        CASE WHEN t3.ano_compra = t5.ano_primeira_compra + 1 THEN 1 END
    ) AS clientes_retidos_ano_seguinte,
    ROUND(
        COUNT(
            CASE WHEN t3.ano_compra = t5.ano_primeira_compra + 1 THEN 1 END
        ) * 100.0 / COUNT(*), 2
    ) AS taxa_retencao
FROM primeira_compra t5
LEFT JOIN compras_ano t3 ON t5.customer_id = t3.customer_id
GROUP BY t5.ano_primeira_compra
ORDER BY t5.ano_primeira_compra;


/* ============================================================
   7. ANÁLISE GEOGRÁFICA
   ============================================================ */

SELECT
    t3.region,
    COUNT(DISTINCT t3.customer_id) AS total_clientes,
    COUNT(DISTINCT CASE
        WHEN t1.order_status = 'Concluído' THEN t3.customer_id
    END) AS clientes_compradores,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN t1.order_status = 'Concluído' THEN t3.customer_id
        END) * 100.0 / COUNT(DISTINCT t3.customer_id), 2
    ) AS taxa_compra,
    ROUND(
        COALESCE(SUM(CASE
            WHEN t1.order_status = 'Concluído'
                THEN t2.quantity * t2.unit_price * (1 - t2.discount)
            ELSE 0
        END), 0), 2
    ) AS receita
FROM clientes t3
LEFT JOIN orders t1 ON t3.customer_id = t1.customer_id
LEFT JOIN order_items t2 ON t1.order_id = t2.order_id
GROUP BY t3.region
ORDER BY receita DESC;


/* ============================================================
   8. SEGMENTAÇÃO POR FREQUÊNCIA E VALOR
   ============================================================ */

WITH clientes AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS frequencia,
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)) AS receita
    FROM orders t1
    JOIN order_items t2 ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
)
SELECT
    CASE
        WHEN frequencia >= 4 AND receita >= 7000
            THEN 'Alto valor e recorrente'
        WHEN frequencia >= 4
            THEN 'Recorrente'
        WHEN receita >= 7000
            THEN 'Alto valor'
        ELSE 'Baixa frequência e valor'
    END AS segmento,
    COUNT(*) AS total_clientes,
    ROUND(SUM(receita), 2) AS receita_total,
    ROUND(AVG(receita), 2) AS receita_media,
    ROUND(AVG(frequencia), 2) AS frequencia_media
FROM clientes
GROUP BY segmento
ORDER BY receita_total DESC;


/* ============================================================
   9. RFM
   Recência, frequência, valor monetário e segmento
   ============================================================ */

WITH rfm AS (
    SELECT
        t1.customer_id,
        CAST(
            julianday('2025-12-31') - julianday(MAX(t1.order_date))
            AS INTEGER
        ) AS recencia_dias,
        COUNT(DISTINCT t1.order_id) AS frequencia,
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)) AS monetario
    FROM orders t1
    JOIN order_items t2 ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),
scores AS (
    SELECT
        rfm.*,
        NTILE(5) OVER (ORDER BY recencia_dias DESC) AS recencia_score,
        NTILE(5) OVER (ORDER BY frequencia ASC) AS frequencia_score,
        NTILE(5) OVER (ORDER BY monetario ASC) AS monetario_score
    FROM rfm
),
segmentacao AS (
    SELECT
        scores.*,
        recencia_score + frequencia_score + monetario_score AS score_rfm,
        CASE
            WHEN recencia_score >= 4
                 AND frequencia_score >= 4
                 AND monetario_score >= 4
                THEN 'Campeões'
            WHEN recencia_score >= 3 AND frequencia_score >= 4
                THEN 'Clientes Fiéis'
            WHEN frequencia_score >= 3 AND monetario_score >= 4
                THEN 'Alto Valor'
            WHEN recencia_score >= 4 AND frequencia_score BETWEEN 2 AND 3
                THEN 'Potenciais Fiéis'
            WHEN recencia_score = 5 AND frequencia_score <= 2
                THEN 'Recentes'
            WHEN recencia_score BETWEEN 2 AND 3 AND frequencia_score <= 3
                THEN 'Em Atenção'
            WHEN recencia_score <= 2 AND frequencia_score >= 3
                THEN 'Em Risco'
            WHEN recencia_score = 1 AND frequencia_score <= 2
                THEN 'Hibernando'
            ELSE 'Outros'
        END AS segmento_rfm
    FROM scores
)
SELECT
    segmento_rfm,
    COUNT(*) AS total_clientes,
    ROUND(SUM(monetario), 2) AS receita_total,
    ROUND(AVG(monetario), 2) AS receita_media_cliente,
    ROUND(AVG(frequencia), 2) AS frequencia_media,
    ROUND(AVG(recencia_dias), 2) AS recencia_media
FROM segmentacao
GROUP BY segmento_rfm
ORDER BY receita_total DESC;


/* ============================================================
   10. CONCENTRAÇÃO DE RECEITA
   ============================================================ */

WITH receita_cliente AS (
    SELECT
        t1.customer_id,
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)) AS receita
    FROM orders t1
    JOIN order_items t2 ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),
ranking AS (
    SELECT
        customer_id,
        receita,
        SUM(receita) OVER (
            ORDER BY receita DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS receita_acumulada,
        SUM(receita) OVER () AS receita_total
    FROM receita_cliente
)
SELECT
    customer_id,
    ROUND(receita, 2) AS receita,
    ROUND(receita_acumulada * 100.0 / receita_total, 2)
        AS percentual_acumulado
FROM ranking
ORDER BY receita DESC;


/* ============================================================
   11. BASE FINAL PARA POWER BI
   Consolida métricas, status e RFM por cliente
   ============================================================ */

WITH metricas AS (
    SELECT
        t1.customer_id,
        COUNT(DISTINCT t1.order_id) AS total_pedidos,
        MAX(t1.order_date) AS ultima_compra,
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)) AS receita,
        SUM(t2.quantity * t2.unit_cost) AS custo
    FROM orders t1
    JOIN order_items t2 ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),
rfm AS (
    SELECT
        t1.customer_id,
        CAST(
            julianday('2025-12-31') - julianday(MAX(t1.order_date))
            AS INTEGER
        ) AS recencia_dias,
        COUNT(DISTINCT t1.order_id) AS frequencia,
        SUM(t2.quantity * t2.unit_price * (1 - t2.discount)) AS monetario
    FROM orders t1
    JOIN order_items t2 ON t1.order_id = t2.order_id
    WHERE t1.order_status = 'Concluído'
    GROUP BY t1.customer_id
),
scores AS (
    SELECT
        rfm.*,
        NTILE(5) OVER (ORDER BY recencia_dias DESC) AS recencia_score,
        NTILE(5) OVER (ORDER BY frequencia ASC) AS frequencia_score,
        NTILE(5) OVER (ORDER BY monetario ASC) AS monetario_score
    FROM rfm
),
rfm_final AS (
    SELECT
        scores.*,
        recencia_score + frequencia_score + monetario_score AS score_rfm,
        CASE
            WHEN recencia_score >= 4
                 AND frequencia_score >= 4
                 AND monetario_score >= 4
                THEN 'Campeões'
            WHEN recencia_score >= 3 AND frequencia_score >= 4
                THEN 'Clientes Fiéis'
            WHEN frequencia_score >= 3 AND monetario_score >= 4
                THEN 'Alto Valor'
            WHEN recencia_score >= 4 AND frequencia_score BETWEEN 2 AND 3
                THEN 'Potenciais Fiéis'
            WHEN recencia_score = 5 AND frequencia_score <= 2
                THEN 'Recentes'
            WHEN recencia_score BETWEEN 2 AND 3 AND frequencia_score <= 3
                THEN 'Em Atenção'
            WHEN recencia_score <= 2 AND frequencia_score >= 3
                THEN 'Em Risco'
            WHEN recencia_score = 1 AND frequencia_score <= 2
                THEN 'Hibernando'
            ELSE 'Outros'
        END AS segmento_rfm
    FROM scores
)
SELECT
    t3.customer_id,
    t3.customer_segment,
    t3.state,
    t3.region,
    COALESCE(t4.total_pedidos, 0) AS total_pedidos,
    ROUND(COALESCE(t4.receita, 0), 2) AS receita,
    ROUND(COALESCE(t4.receita, 0) - COALESCE(t4.custo, 0), 2) AS lucro,
    t4.ultima_compra,
    CASE
        WHEN t4.ultima_compra IS NULL THEN 'Sem compra'
        WHEN julianday('2025-12-31') - julianday(t4.ultima_compra) <= 90
            THEN 'Ativo'
        WHEN julianday('2025-12-31') - julianday(t4.ultima_compra) > 180
            THEN 'Inativo'
        ELSE 'Atenção'
    END AS status_cliente,
    t6.recencia_dias,
    t6.frequencia,
    ROUND(t6.monetario, 2) AS monetario,
    t6.recencia_score,
    t6.frequencia_score,
    t6.monetario_score,
    t6.score_rfm,
    t6.segmento_rfm
FROM clientes t3
LEFT JOIN metricas t4 ON t3.customer_id = t4.customer_id
LEFT JOIN rfm_final t6 ON t3.customer_id = t6.customer_id;
