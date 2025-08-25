#!/bin/bash
set -euo pipefail

# 参数配置
OLD_DB="email_tool"
NEW_DB="email_tool_2025_08_19"
USER="root"
PASS="password"
HOST="localhost"
PORT="3306"

BACKUP_FILE="/tmp/${OLD_DB}_backup_$(date +%F_%H%M%S).sql"

echo "=== ������ 开始数据库重命名 [$OLD_DB] -> [$NEW_DB] ==="

# 0. 备份旧数据库
echo ">>> 备份 [$OLD_DB] 到 $BACKUP_FILE"
mysqldump -h$HOST -P$PORT -u$USER -p$PASS --set-gtid-purged=OFF --routines --events --triggers $OLD_DB > "$BACKUP_FILE"
echo "✅ 备份完成"

# 1. 创建新库
echo ">>> 创建新库 [$NEW_DB]"
mysql -h$HOST -P$PORT -u$USER -p$PASS -e "CREATE DATABASE IF NOT EXISTS \`$NEW_DB\`"

# 2. 迁移表
echo ">>> 开始迁移表"
TABLES=$(mysql -N -h$HOST -P$PORT -u$USER -p$PASS -e "SELECT table_name FROM information_schema.tables WHERE table_schema='$OLD_DB'")
for T in $TABLES; do
  echo "    - RENAME TABLE $T"
  mysql -h$HOST -P$PORT -u$USER -p$PASS -e "RENAME TABLE \`$OLD_DB\`.\`$T\` TO \`$NEW_DB\`.\`$T\`"
done

# 3. 导出视图、存储过程、函数、触发器（替换库名后导入）
echo ">>> 导出 [$OLD_DB] 的视图/存储过程/函数/触发器"
DEF_FILE="/tmp/${OLD_DB}_defs.sql"
mysqldump -h$HOST -P$PORT -u$USER -p$PASS \
  --no-data --no-create-info --set-gtid-purged=OFF --routines --events --triggers \
  $OLD_DB > "$DEF_FILE"

echo ">>> 替换库名并导入新库"
sed -i "s/\b$OLD_DB\b/$NEW_DB/g" "$DEF_FILE"
mysql -h$HOST -P$PORT -u$USER -p$PASS $NEW_DB < "$DEF_FILE"

echo "=== ✅ 数据库 [$OLD_DB] 已迁移到 [$NEW_DB]，备份保存在 $BACKUP_FILE ==="
echo "⚠️ 请确认新库正常后，再手动 DROP DATABASE \`$OLD_DB\`"

