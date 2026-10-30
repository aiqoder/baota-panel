# 计划任务 工具

共 2 个工具。

## GetCrontab · 获取计划任务列表

- 风险：**low**（低）

获取面板计划任务列表。只读。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `search` | 否 | string | 按任务名/脚本内容模糊搜索。 |
| `category` | 否 | string | 过滤：system(系统)/enabled(启用)/disabled(停用)/分类 id，空=全部。 |
| `page` | 否 | integer | 页码，默认 1。 |
| `page_size` | 否 | integer | 每页条数，默认 0=全部。 |

## ManageCrontab · 计划任务管理

- 风险：**high**（高）

管理计划任务：add 创建 / del 删除。高风险。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 是 | string | add创建 / del删除 |
| `id` | 否 | integer | 任务id，del必填，取自GetCrontab |
| `name` | 否 | string | 任务名，add必填 |
| `schedule` | 否 | object | 周期对象，含 type 及 interval/hour/minute/weekday。 |
| `task` | 否 | object | 任务对象，含 type 及按类型的字段。 |
