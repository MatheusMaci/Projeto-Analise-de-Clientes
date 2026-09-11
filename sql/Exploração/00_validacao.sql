SELECT 'clientes' AS tabela, COUNT(*) AS registros
FROM clientes

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items;

SELECT product_id,
       count(*) as quantidades
FROM products
GROUP BY product_id
HAVING COUNT (*) > 1

;


SELECT count(*) as itens_sem_pedido

FROM order_items as t1
LEFT JOIN orders as t2
ON t1.order_id = t2.order_id
WHERE t1.order_id is NULL

;

SELECT
    t1.customer_id,
    t1.state,
    t1.region,
    t1.customer_segment,

    t2.order_id,
    t2.order_date,
    t2.order_status,
    t2.channel,
    t2.payment_method,

    t3.product_id,
    t3.product_name,
    t3.category,
    t3.subcategory,

    t4.quantity,
    t4.unit_price,
    t4.discount,
    t4.unit_cost

FROM clientes t1

INNER JOIN orders t2
    ON t1.customer_id = t2.customer_id

INNER JOIN order_items t4
    ON t2.order_id = t4.order_id

INNER JOIN products t3
    ON t4.product_id = t3.product_id
    
;