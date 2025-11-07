#!/bin/bash

# ============================================================
# PostgreSQL Auto-Backup Script
# Purpose: Backup All PostgreSQL DB, Periodically
# Execution By: Cron (every 2AM)
# ============================================================

# General Configs
BACKUP_DIR="/opt/git/GYO-Portfolio/backup/postgresql"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y-%m-%d)
# Backup Storage Period
RETENTION_DAYS=7  

# PostgreSQL Config
PG_BIN="/usr/pgsql-15/bin"
PG_USER="postgres"

# Log File PATH
LOG_FILE="${BACKUP_DIR}/auto-backup_log_${DATE}.txt"

# ============================================================
# 1. Ensure Backup Dir Exist
# ============================================================
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "[$(date)] CREATE BACKUP_DIR: $BACKUP_DIR" >> "$LOG_FILE"
fi

# ============================================================
# 2. Start Auto-Backup
# ============================================================
echo "========================================" >> "$LOG_FILE"
echo "[$(date)] PostgreSQL Backup Start" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Backup Whole DB (pg_dumpall)
BACKUP_FILE="${BACKUP_DIR}/all_databases_${TIMESTAMP}.sql.gz"

sudo -u $PG_USER $PG_BIN/pg_dumpall | gzip > "$BACKUP_FILE"

# Check the Backup Result 
# $? Returns 0, if the previous CMD is success(Otherwise, It returns none-0 values) 
if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] SUCCESS: $BACKUP_FILE (SIZE: $FILE_SIZE)" >> "$LOG_FILE"
else
    echo "[$(date)] FAIL!!!" >> "$LOG_FILE"
    exit 1
fi
#echo "Cuurent Dirrectory is $(pwd)" >> "$LOG_FILE"
# ============================================================
# 3. Delete Outdated Files
# ============================================================
echo "[$(date)] DELETE OLD FILES, (${RETENTION_DAYS} Days+)" >> "$LOG_FILE"

DELETED_COUNT=$(find "$BACKUP_DIR" -name "all_databases_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete -print | wc -l)

echo "[$(date)] DELETED FILE NUM: $DELETED_COUNT" >> "$LOG_FILE"

# ============================================================
# 4. Show Current BackUp Files
# ============================================================
echo "[$(date)] Current File List:" >> "$LOG_FILE"
ls -lh "$BACKUP_DIR"/all_databases_*.sql.gz >> "$LOG_FILE" 2>/dev/null || echo "NO BACKUP FILES" >> "$LOG_FILE"

# ============================================================
# 5. Backup Completed
# ============================================================
echo "[$(date)] PostgreSQL BACKUP COMPLETED" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit 0
