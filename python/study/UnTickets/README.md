# 说明
学习python脚本

`UC.sqlite3`数据库`companys`表结构
```sql
CREATE TABLE "main"."Untitled" (
  "序号" INTEGER PRIMARY KEY AUTOINCREMENT,
  "UC号码" STRING NOT NULL,
  "单位名称" STRING,
  "差旅顾问中文名" STRING,
  "差旅顾问英文名" STRING,
  "差旅顾问邮箱" STRING,
  "差旅经理中文名" STRING,
  "差旅经理邮箱" STRING,
  UNIQUE ("UC号码" ASC)
);

INSERT INTO "main"."sqlite_sequence" (name, seq) VALUES ('Untitled', '77');
```