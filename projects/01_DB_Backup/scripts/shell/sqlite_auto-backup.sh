#!/bin/bash

# ============================================================
# SQLite Auto Backup Script 
# Purpose: SQLite DB File Backup & Mgmt
# Executed By: Cron (Every 3AM)
# ============================================================

# Default Configs
BACKUP_DIR="/opt/git/GYO-Portfolio/backup/sqlite"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y-%m-%d)
RETENTION_DAYS=7

# SQLite DB File PATH
SQLITE_DB_FILES=(
    "/tmp/sqlite_backup_test.db"
    # Add below if additional DB files 
    # "/path/to/another/database.db"
)

# Log File PATH
LOG_FILE="${BACKUP_DIR}/auto-backup_log_${DATE}.txt"

# ============================================================
# 1. Ensure Backup Directory Exists
# ============================================================
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "[$(date)] Create Backup Directory: $BACKUP_DIR" >> "$LOG_FILE"
fi

# ============================================================
# 2. Backup Start
# ============================================================
echo "========================================" >> "$LOG_FILE"
echo "[$(date)] SQLite Backup Start" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# 각 SQLite DB 파일 백업
for DB_FILE in "${SQLITE_DB_FILES[@]}"; do
    if [ -f "$DB_FILE" ]; then
        # 파일명 추출
        DB_NAME=$(basename "$DB_FILE" .db)
        
        # 백업 파일 생성
        BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.db"
        
        # SQLite 백업 명령 (안전한 방법)
        sqlite3 "$DB_FILE" ".backup '$BACKUP_FILE'"
        
        # 압축
        gzip -f "$BACKUP_FILE"
        BACKUP_FILE="${BACKUP_FILE}.gz"
        
        # 백업 결과 확인
	# [ -f "someFile"] Returns 0(==true) if someFile Exist, Otherwise returns 1
        if [ -f "$BACKUP_FILE" ]; then
            FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
	    echo "[$(date)] Backup Success: $DB_FILE → $BACKUP_FILE (Size: $FILE_SIZE)" >> "$LOG_FILE"
        else
            echo "[$(date)] Backup Fail!!: $DB_FILE" >> "$LOG_FILE"
        fi
    else
        echo "[$(date)] !WARNING!: $DB_FILE" >> "$LOG_FILE"
    fi
done

# ============================================================
# 3. Remove Outdated Backup Files
# ============================================================
echo "[$(date)] Remove OLD Backup Files (${RETENTION_DAYS}Days+)" >> "$LOG_FILE"

DELETED_COUNT=$(find "$BACKUP_DIR" -name "*.db.gz" -type f -mtime +$RETENTION_DAYS -delete -print | wc -l)

echo "[$(date)] Deleted Files Num: $DELETED_COUNT" >> "$LOG_FILE"

# ============================================================
# 4. List Current Backup Files
# ============================================================
echo "[$(date)] Current Backup Files:" >> "$LOG_FILE"
ls -lh "$BACKUP_DIR"/*.db.gz >> "$LOG_FILE" 2>/dev/null || echo "No Backups" >> "$LOG_FILE"

# ============================================================
# 5. Backup Completed 
# ============================================================
echo "[$(date)] SQLite Backup Completed" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit 0
