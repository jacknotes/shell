#!/bin/bash
# description: mysql - 全量 + 增量数据库恢复脚本
# author: jackli
# 使用方法:
#   ./mysql_restore.sh <全量备份文件> <数据库SQL文件名> <恢复截止时间>
#
# 例子:
#   [root@host ~/mysql_restore]# ls 
#	Pro_Full_20250819_010001.tar.gz  Pro_Increment_20250819_030001.tar.gz  Pro_Increment_20250820_030001.tar.gz  restore
#   [root@host ~/mysql_restore]# ./mysql_restore.sh Pro_Full_20250819_010001.tar.gz Pro_Full_20250819_010001/Pro_Full_20250819_011009_email_tool.sql "2025-08-19 10:30:00"
#   [root@host ~/mysql_restore]# RESTORE_HOME="/root/mysql_restore" ./mysql_restore.sh Pro_Full_20250819_010001.tar.gz Pro_Full_20250819_010001/Pro_Full_20250819_010051_czndc.sql "2025-08-19 19:30:00"
#

#set -x
set -euo pipefail

# 参数检查
if [ $# -ne 3 ]; then
    echo "用法: $0 <全量备份文件> <需要恢复的SQL文件名> <恢复截止时间>"
    exit 1
fi

echo "[INFO] BEGIN TIME `date +'%F %T'`"

FULL_BACKUP=$1
TARGET_SQL=$2
STOP_TIME=$3
TARGET_DATABASE=`echo "$TARGET_SQL" | sed -E 's/.*_[0-9]+_(.*)\.sql/\1/'`

WORKDIR=${RESTORE_HOME}/restore
MYSQL_CMD="mysql -uroot -ppassword"     # 按需修改用户名/密码
MYSQLBINLOG="mysqlbinlog --no-defaults"   # 转换所有数据库的binlog日志

# 更改到数据恢复根目录
RESTORE_HOME=${RESTORE_HOME:-~/mysql_restore}
cd "$RESTORE_HOME"

echo "=============================="
echo "[1] 准备工作目录: $WORKDIR"
echo "=============================="
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

echo "=============================="
echo "[2] 解压全量备份: $FULL_BACKUP"
echo "=============================="
tar -xzf "$FULL_BACKUP" -C "$WORKDIR" "$(${MYSQLBINLOG} --no-defaults --help >/dev/null 2>&1 || echo $TARGET_SQL)"

# 获取全量SQL路径
#FULL_DIR=$(tar -tzf "$FULL_BACKUP" | head -1 | cut -d/ -f1)
FULL_DIR=$(echo $TARGET_SQL | cut -d/ -f1)
FULL_SQL="$WORKDIR/$TARGET_SQL"

if [ ! -f "$FULL_SQL" ]; then
    echo "错误: 找不到目标SQL文件 $TARGET_SQL"
    exit 2
fi

echo "全量SQL文件路径: $FULL_SQL"

echo "=============================="
echo "[3] 提取 CHANGE MASTER 标志位"
echo "=============================="
CHANGE_MASTER_LINE=$(head -n 100 "$FULL_SQL" | grep "CHANGE MASTER TO MASTER_LOG_FILE=" | head -1)
if [ -z "$CHANGE_MASTER_LINE" ]; then
    echo "错误: 全量SQL文件中未找到 CHANGE MASTER 信息"
    exit 3
fi

BINLOG_FILE=$(echo "$CHANGE_MASTER_LINE" | sed -n "s/.*MASTER_LOG_FILE='\(.*\)', MASTER_LOG_POS=.*/\1/p")
BINLOG_POS=$(echo "$CHANGE_MASTER_LINE" | sed -n "s/.*MASTER_LOG_FILE='.*', MASTER_LOG_POS=\([0-9]\+\).*/\1/p")

echo "恢复起点: $BINLOG_FILE @ $BINLOG_POS"

echo "=============================="
echo "[4] 解压增量备份 (binlog)"
echo "=============================="
for INC in $(ls Pro_Increment_*.tar.gz 2>/dev/null | sort); do
    echo "解压增量文件: $INC"
    tar -xzf "$INC" -C "$WORKDIR/"
done

echo "=============================="
echo "[5] 生成增量SQL文件"
echo "=============================="
OUT_SQLS=()

# 遍历增量文件夹
# -print0 + -d '':
## find 输出以 null (\0) 分隔，而不是空格或换行
## read -d '': 按 null 读取，避免被空格拆开
# sort -z: 保持 null 分隔排序结果和输入一致
# IFS= + -r: 防止路径里出现奇怪字符（比如 \）被转义
while IFS= read -r -d '' DIR; do
    FILE=$(ls "$DIR"/* 2>/dev/null || true)
    if [[ -z "$FILE" ]]; then
        continue
    fi
    BASENAME=$(basename "$FILE")
    OUT_SQL="$WORKDIR/$FULL_DIR/${BASENAME}.sql"

    if [[ "$BASENAME" == *"$BINLOG_FILE"* ]]; then
        echo "处理增量: $BASENAME (从 $BINLOG_POS 开始)"
        #$MYSQLBINLOG --skip-gtids --start-position="$BINLOG_POS" "$FILE" > "$OUT_SQL"
        $MYSQLBINLOG --database=$TARGET_DATABASE --skip-gtids --start-position="$BINLOG_POS" "$FILE" | grep -v -i '^USE ' > "$OUT_SQL"
    else
        echo "处理增量: $BASENAME (截止时间 $STOP_TIME)"
	# 如果有多个增量文件，每个文件都会附带参数--stop-datetime="$STOP_TIME",如果当前文件最后一行数据写入时间小于--stop-datetime="$STOP_TIME"，那么表示这个文件将全部转换，否则将以--stop-datetime="$STOP_TIME"为截止时间，并不会文件无此时间而报错
        #$MYSQLBINLOG --skip-gtids --stop-datetime="$STOP_TIME" "$FILE" > "$OUT_SQL"
        $MYSQLBINLOG --database=$TARGET_DATABASE --skip-gtids --stop-datetime="$STOP_TIME" "$FILE" | grep -v -i '^USE ' > "$OUT_SQL"
    fi

    OUT_SQLS+=("$OUT_SQL")
done < <(find "$WORKDIR" -maxdepth 1 -type d -name "Pro_Increment_*" -print0 | sort -z) 
# < <(...) 是Bash 的进程替换 写法，对空格有要求
# <(...) 会把括号里的命令输出，映射成一个临时的 文件描述符。 < 再把这个文件描述符作为 while ... done 的输入

echo "=============================="
echo "[6] 开始恢复到MySQL"
echo "=============================="
echo "恢复全量: $FULL_SQL"
$MYSQL_CMD < "$FULL_SQL"

for SQL in "${OUT_SQLS[@]}"; do
    echo "恢复增量: $SQL"
    # --force表示恢复binlog时忽略错误
    #$MYSQL_CMD --force $TARGET_DATABASE < "$SQL"
    $MYSQL_CMD $TARGET_DATABASE < "$SQL"
done

echo "=============================="
echo "数据库恢复完成! 截止时间: $STOP_TIME"
echo "=============================="

echo "[INFO] END TIME `date +'%F %T'`"
