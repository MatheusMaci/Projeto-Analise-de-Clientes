-- ============================================================
-- PROJETO 2 — ANÁLISE DE CLIENTES
-- SQL SERVER
-- ============================================================

CREATE TABLE clients (
    customer_id VARCHAR(10) PRIMARY KEY,
    signup_date DATE NOT NULL,
    state CHAR(2) NOT NULL,
    region VARCHAR(20) NOT NULL,
    customer_segment VARCHAR(20) NOT NULL
);

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50) NOT NULL,
    standard_cost DECIMAL(12,2) NOT NULL,
    list_price DECIMAL(12,2) NOT NULL
);

CREATE TABLE orders (
    order_id VARCHAR(12) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    order_date DATE NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,

    CONSTRAINT FK_orders_clients
        FOREIGN KEY (customer_id)
        REFERENCES clients(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(12) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount DECIMAL(5,4) NOT NULL,
    unit_cost DECIMAL(12,2) NOT NULL,

    CONSTRAINT PK_order_items
        PRIMARY KEY (order_id, product_id),

    CONSTRAINT FK_order_items_orders
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT FK_order_items_products
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- ============================================================
-- VALIDAÇÕES
-- ============================================================

ALTER TABLE clients
ADD CONSTRAINT CK_clients_segment
CHECK (
    customer_segment IN (
        'Mass Market',
        'Intermediário',
        'Premium'
    )
);

ALTER TABLE orders
ADD CONSTRAINT CK_orders_status
CHECK (
    order_status IN (
        'Concluído',
        'Cancelado',
        'Devolvido'
    )
);

ALTER TABLE order_items
ADD CONSTRAINT CK_order_items_quantity
CHECK (quantity > 0);

ALTER TABLE order_items
ADD CONSTRAINT CK_order_items_price
CHECK (unit_price > 0);

ALTER TABLE order_items
ADD CONSTRAINT CK_order_items_cost
CHECK (unit_cost > 0);

ALTER TABLE order_items
ADD CONSTRAINT CK_order_items_discount
CHECK (
    discount >= 0
    AND discount <= 0.15
);
