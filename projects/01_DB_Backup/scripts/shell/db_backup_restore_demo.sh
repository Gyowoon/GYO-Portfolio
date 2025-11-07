#!/bin/bash

# ================================================
# PostgreSQL & SQLite Backup-Recovery Demo Script
# Purpose: Demonstrate Whole Process From Backup -> Fail -> Recovery
# Used DB: pgsql_backup_test[PostgreSQL], sqlite_backup_test.db[SQLite]
# =================================================

set -e 
# Halt if any err occure 

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
# Define colour for readability ; NC(No Color)

PG_BACKUP_DIR="/opt/git/GYO-Portfolio/backup/postgresql"
SQLITE_BACKUP_DIR="/opt/git/GYO-Portfolio/backup/sqlite"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
# Define Backup Directory


PG_BIN="/usr/pgsql-15/bin"
PG_USER="postgres"
PG_DB="pgsql_backup_test"
# Postgresql Configurations

SQLITE_DB="/tmp/sqlite_backup_test.db"
# Sqlite Configurations

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PostgreSQL & SQLite Backup/Recovery Demo${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""


# ============================================================
# Part 1: [PostgreSQL] DB CREATION
# ============================================================

echo -e "${GREEN}[1/10] PostgreSQL DB CREATION: ${PG_DB}${NC}"
sudo -u $PG_USER $PG_BIN/psql -c "DROP DATABASE IF EXISTS ${PG_DB};" 2>/dev/null || true
sudo -u $PG_USER $PG_BIN/psql -c "CREATE DATABASE ${PG_DB};"
echo -e "${GREEN}DB CREATION COMPLETE${NC}"
echo ""

echo -e "${GREEN}[2/10] PostgreSQL TABLE CREATEION & RECORD INSERTION${NC}"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} << 'PGSQL_EOF'
-- create user tables
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- create order tables
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- insert sample records
INSERT INTO users (name, email) VALUES
    ('GilDong', 'hong@example.com'),
    ('CheolSu', 'kim@example.com'),
    ('YeoungHee', 'lee@example.com'),
    ('MinSu', 'park@example.com'),
    ('Suhyeon', 'jung@example.com');

INSERT INTO orders (user_id, product_name, price) VALUES
    (1, 'Laptop', 1200000.00),
    (1, 'Mouse', 35000.00),
    (2, 'Keyboard', 89000.00),
    (3, 'Monitor', 450000.00),
    (4, 'Headset', 125000.00),
    (5, 'SSD 1TB', 180000.00);

PGSQL_EOF

echo -e "${GREEN} TABLE & RECORD CREATED!${NC}"
echo ""

echo -e "${GREEN}[3/10] PostgreSQL DATA CHECK (Before Backup)${NC}"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "SELECT COUNT(*) as user_count FROM users;"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "SELECT COUNT(*) as order_count FROM orders;"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "SELECT * FROM users;"
echo ""

echo -e "${YELLOW}[4/10] PostgreSQL BACKUP${NC}"
PG_BACKUP_FILE="${PG_BACKUP_DIR}/${PG_DB}_${TIMESTAMP}.sql.gz"
sudo -u $PG_USER $PG_BIN/pg_dump ${PG_DB} | gzip > "$PG_BACKUP_FILE"
echo -e "${YELLOW}BACKUP COMPLETE!: $PG_BACKUP_FILE${NC}"
echo -e "   File Size: $(du -h "$PG_BACKUP_FILE" | cut -f1)"
echo ""

echo -e "${RED}[5/10] PostgreSQL DATA DROP (DR)${NC}"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "DROP TABLE orders CASCADE;"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "DROP TABLE users CASCADE;"
echo -e "${RED}ALL TABLE DROPPED!${NC}"
echo ""

echo -e "${RED}[6/10] PostgreSQL DATA CHECK (After Backup)${NC}"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "\dt" || echo "Nothing (Eliminated)"
echo ""

echo -e "${GREEN}[7/10] PostgreSQL RECOVERY${NC}"
gunzip -c "$PG_BACKUP_FILE" | sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB}
echo -e "${GREEN}RECOVERY COMPLETE!${NC}"
echo ""

echo -e "${GREEN}[8/10] PostgreSQL DATA CHECK (After Recovery)${NC}"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "SELECT COUNT(*) as user_count FROM users;"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "SELECT COUNT(*) as order_count FROM orders;"
sudo -u $PG_USER $PG_BIN/psql -d ${PG_DB} -c "SELECT * FROM users;"
echo ""


# ============================================================
# Part 2: SQLite Demo
# ============================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SQLite Backup&Recovery Demo START${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}[9/10] SQLite DB CREATION & RECORD INSERTION${NC}"

# Remove SQLite DB (if exist) 
rm -f "$SQLITE_DB"

# Create SQLite Table and Data 
sqlite3 "$SQLITE_DB" << 'SQLITE_EOF'
-- create products table
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    price REAL NOT NULL,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- insert sample data
INSERT INTO products (name, category, price, stock) VALUES
    ('MacBook Pro', 'Laptop', 2500000, 15),
    ('iPhone 15', 'Phone', 1300000, 50),
    ('AirPods Pro', 'Audio', 350000, 100),
    ('iPad Air', 'Tablet', 850000, 30),
    ('Apple Watch', 'Wearable', 650000, 45);

SQLITE_EOF

echo -e "${GREEN}SQLite DB CREATION COMPLETED!${NC}"
echo ""

echo -e "${GREEN}SQLite DATA CHECK (Before Backup)${NC}"
sqlite3 "$SQLITE_DB" "SELECT COUNT(*) as product_count FROM products;"
sqlite3 "$SQLITE_DB" "SELECT * FROM products;"
echo ""

echo -e "${YELLOW}[10/10] SQLite BACKUP${NC}"
SQLITE_BACKUP_FILE="${SQLITE_BACKUP_DIR}/sqlite_backup_test_${TIMESTAMP}.db"
sqlite3 "$SQLITE_DB" ".backup '$SQLITE_BACKUP_FILE'"
gzip -f "$SQLITE_BACKUP_FILE"
SQLITE_BACKUP_FILE="${SQLITE_BACKUP_FILE}.gz"
echo -e "${YELLOW}BACKUP COMPLETED!: $SQLITE_BACKUP_FILE${NC}"
echo -e "   File Size: $(du -h "$SQLITE_BACKUP_FILE" | cut -f1)"
echo ""

echo -e "${RED}SQLite DATA DROPING (DR)${NC}"
sqlite3 "$SQLITE_DB" "DROP TABLE products;"
echo -e "${RED}TABLE DROPPED!${NC}"
echo ""

echo -e "${RED}SQLite DATA CHECK (After Backup)${NC}"
sqlite3 "$SQLITE_DB" ".tables" || echo "No Tables (Eliminated)"
echo ""

echo -e "${GREEN}SQLite RECOVERY${NC}"
rm -f "$SQLITE_DB"
gunzip -c "$SQLITE_BACKUP_FILE" > "$SQLITE_DB"
echo -e "${GREEN}RECOVERY COMPLETED!${NC}"
echo ""

echo -e "${GREEN}SQLite DATA CHECK (After Recovery)${NC}"
sqlite3 "$SQLITE_DB" "SELECT COUNT(*) as product_count FROM products;"
sqlite3 "$SQLITE_DB" "SELECT * FROM products;"
echo ""

# ============================================================
# Final Summary
# ============================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Demo Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}PostgreSQL:${NC}"
echo "   - DB: ${PG_DB}"
echo "   - BACKUP_FILE: $PG_BACKUP_FILE"
#echo "   - RECOVERED_TABLES: users (5개 레코드), orders (6개 레코드)"
echo ""

echo -e "${GREEN}SQLite:${NC}"
echo "   - DB: $SQLITE_DB"
echo "   - BACKUP_FILE: $SQLITE_BACKUP_FILE"
#echo "   - RECOVERED_TABLES: "
echo ""

echo -e "${GREEN}MISSION COMPLETED!!${NC}"
echo ""

# BACKUP_File State
echo -e "${BLUE}CURRENT BACKUP FILES:${NC}"
echo "PostgreSQL Backup files:"
ls -lh ${PG_BACKUP_DIR}/*${TIMESTAMP}* 2>/dev/null || echo "  (None)"
echo ""
echo "SQLite BACKUP FILES:"
ls -lh ${SQLITE_BACKUP_DIR}/*${TIMESTAMP}* 2>/dev/null || echo "  (None)"
echo ""

exit 0

