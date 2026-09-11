import sqlite3
import csv
from pathlib import Path

# ============================================================
# CONFIGURAÇÃO
# ============================================================

BASE_DIR = Path(__file__).parent

DB_PATH = BASE_DIR / "projeto_2.db"

clientes_CSV = BASE_DIR / "clientes.csv"
PRODUCTS_CSV = BASE_DIR / "products.csv"
ORDERS_CSV = BASE_DIR / "orders.csv"
ORDER_ITEMS_CSV = BASE_DIR / "order_items.csv"

# ============================================================
# CONEXÃO
# ============================================================

conn = sqlite3.connect(DB_PATH)

cursor = conn.cursor()

cursor.execute("PRAGMA foreign_keys = ON;")

# ============================================================
# CRIAÇÃO DAS TABELAS
# ============================================================

cursor.executescript("""
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
    customer_id TEXT PRIMARY KEY,
    signup_date DATE NOT NULL,
    state TEXT NOT NULL,
    region TEXT NOT NULL,
    customer_segment TEXT NOT NULL
);

CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    subcategory TEXT NOT NULL,
    standard_cost REAL NOT NULL,
    list_price REAL NOT NULL
);

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_date DATE NOT NULL,
    order_status TEXT NOT NULL,
    channel TEXT NOT NULL,
    payment_method TEXT NOT NULL,

    FOREIGN KEY (customer_id)
        REFERENCES clientes(customer_id)
);

CREATE TABLE order_items (
    order_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    discount REAL NOT NULL,
    unit_cost REAL NOT NULL,

    PRIMARY KEY (order_id, product_id),

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_orders_date
ON orders(order_date);

CREATE INDEX idx_order_items_product
ON order_items(product_id);
""")

# ============================================================
# FUNÇÃO DE IMPORTAÇÃO
# ============================================================

def import_csv(filename, table, columns):

    print(f"Importando {filename.name}...")

    with open(filename, "r", encoding="utf-8-sig", newline="") as file:

        reader = csv.DictReader(file)

        placeholders = ",".join(["?"] * len(columns))

        query = f"""
        INSERT INTO {table}
        ({",".join(columns)})
        VALUES ({placeholders})
        """

        rows = []

        for row in reader:
            rows.append(
                tuple(row[column] for column in columns)
            )

        cursor.executemany(query, rows)

        print(f"  → {len(rows):,} registros")

# ============================================================
# IMPORTAÇÃO
# ============================================================

import_csv(
    clientes_CSV,
    "clientes",
    [
        "customer_id",
        "signup_date",
        "state",
        "region",
        "customer_segment"
    ]
)

import_csv(
    PRODUCTS_CSV,
    "products",
    [
        "product_id",
        "product_name",
        "category",
        "subcategory",
        "standard_cost",
        "list_price"
    ]
)

import_csv(
    ORDERS_CSV,
    "orders",
    [
        "order_id",
        "customer_id",
        "order_date",
        "order_status",
        "channel",
        "payment_method"
    ]
)

import_csv(
    ORDER_ITEMS_CSV,
    "order_items",
    [
        "order_id",
        "product_id",
        "quantity",
        "unit_price",
        "discount",
        "unit_cost"
    ]
)

# ============================================================
# SALVA
# ============================================================

conn.commit()

# ============================================================
# VALIDAÇÃO
# ============================================================

print()
print("=" * 50)
print("VALIDAÇÃO")
print("=" * 50)

tables = [
    "clientes",
    "products",
    "orders",
    "order_items"
]

for table in tables:

    cursor.execute(
        f"SELECT COUNT(*) FROM {table}"
    )

    count = cursor.fetchone()[0]

    print(f"{table:15} → {count:,} registros")

# ============================================================
# INTEGRIDADE
# ============================================================

print()
print("=" * 50)
print("INTEGRIDADE")
print("=" * 50)

cursor.execute("""
SELECT COUNT(*)
FROM orders o
LEFT JOIN clientes c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
""")

print(
    "Pedidos sem cliente:",
    cursor.fetchone()[0]
)

cursor.execute("""
SELECT COUNT(*)
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
""")

print(
    "Itens sem pedido:",
    cursor.fetchone()[0]
)

cursor.execute("""
SELECT COUNT(*)
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
""")

print(
    "Itens sem produto:",
    cursor.fetchone()[0]
)

# ============================================================
# FINAL
# ============================================================

conn.close()

print()
print("=" * 50)
print("BANCO SQLITE CRIADO COM SUCESSO!")
print("=" * 50)
print()
print(DB_PATH)