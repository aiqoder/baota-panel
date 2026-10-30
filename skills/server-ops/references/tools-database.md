# 数据库 工具

共 6 个工具。

## DatabaseList · 获取数据库列表

- 风险：**low**（低）

获取面板管理的 MySQL 数据库列表。只读。

data.databases 每项含 name、username、accept（允许连接的来源 IP）、type。
不返回密码；连接密码须向用户索取。查库列表用本工具，不要用 SQL。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `search` | 否 | string | 按库名模糊搜索。 |

## DatabaseCreate · 创建数据库

- 风险：**medium**（中）

创建 MySQL 数据库（本地实例）并创建访问用户。中风险。

password 留空时自动生成强密码并在返回中给出。成功时 data 含 name、username、address。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `name` | 是 | string | 库名，必填。 |
| `db_user` | 是 | string | 用户名，必填。 |
| `password` | 否 | string | 密码，留空自动生成。 |
| `codeing` | 否 | string | 字符集，默认 utf8mb4（仅 utf8/utf8mb4/gbk/big5）。 |
| `address` | 否 | string | 访问权限，默认 127.0.0.1（仅本机），远程传 % 或具体 IP。 |
| `ps` | 否 | string | 备注。 |

## DatabaseDelete · 删除数据库

- 风险：**high**（高）

删除指定 MySQL 数据库。高风险：调用前必须向用户确认。删前用 DatabaseList 核对避免误删。

面板启用数据库回收站时，删除的库进回收站（可恢复）；否则真删、不可逆。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `name` | 是 | string | 库名，取自 DatabaseList 返回的 name。 |

## DatabaseBackup · 备份数据库

- 风险：**medium**（中）

备份指定 MySQL 数据库（全库，存入面板备份目录）。中风险：占用磁盘与 IO。

该操作可能进入后台并返回 task_id；用 BashStatus 查询状态与结果，用 BashStop 停止任务。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `name` | 是 | string | 库名，取自 DatabaseList 返回的 name。 |

## MysqlQuery · MySql查询

- 风险：**low**（低）

对 MySQL 执行只读 SQL 并返回结果行。只读，不修改任何数据。

仅允许 SELECT/SHOW/DESCRIBE/DESC/EXPLAIN/WITH/TABLE；写关键字、系统库表与敏感列
（password/authentication_string）一律拒绝。SQL 含 %s 占位符时必须以 params 提供
绑定值，禁止字符串拼接。表结构类查询直接传 SHOW CREATE TABLE/DESCRIBE 等。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `sql` | 是 | string | 单条只读 SQL，必填。 |
| `database` | 否 | string | 目标库名，留空连实例级（可查 SHOW DATABASES 等）。 |
| `params` | 否 | array/null | %s 占位符的绑定值列表，sql 含 %s 时必填。 |
| `limit` | 否 | integer | 最多返回行数，默认 100，上限 200；超出截断并以 truncated 标记。 |

## MysqlExecute · MySql写操作

- 风险：**high**（高）

对 MySQL 执行单条写 SQL（DML/表级 DDL）。高风险，在执行前要求用户确认。
系统库写入与库级/用户级 DDL 拒绝。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `sql` | 是 | string | 单条写 SQL，含 %s 占位符时必须以 params 提供绑定值。 |
| `database` | 是 | string | 目标库名，必填。 |
| `params` | 否 | array/null | %s 占位符的绑定值列表，sql 含 %s 时必填。 |
| `confirm` | 否 | boolean | 首次调用必须为 false，仅建立确认记录且不会执行。收到 waiting_confirm 后必须停止并询问用户。只有收到一条后续用户消息明确同意，才可使用完全相同的业务参数设置为 true。 |
