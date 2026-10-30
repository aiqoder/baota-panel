# 基础 工具

共 9 个工具。

## Read · 读取文件

- 风险：**low**（低） · 基础工具

读取文本文件；查看文件或读取 Grep 命中位置附近内容时使用。只读。

data 返回 lines 和 next_offset；结果达到约 40KB 时会提前分页。lines 包含 number 和 content，单行最多返回
1000 字符，超出时追加 ...；无效 UTF-8 字节会替换。next_offset 非空时传回 offset 继续读取。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `file_path` | 是 | string | 允许范围内的绝对路径。 |
| `offset` | 否 | integer | 起始行，默认 1。 |
| `limit` | 否 | integer | 行数，默认及上限 2000。 |

## Edit · 精确修改文件

- 风险：**high**（高） · 基础工具

精确修改已有 UTF-8 文本文件；先用 Read 获取原文，再进行小范围替换。高风险：调用前必须向用户确认。

修改前后的文件上限均为 4MB。匹配多处时请增加上下文，或设置 replace_all=true 全部替换。成功时仅返回 replacements。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `file_path` | 是 | string | 允许范围内的绝对路径。 |
| `old_string` | 是 | string | 必须与原文完全一致。 |
| `new_string` | 是 | string | 替换后的文本。 |
| `replace_all` | 否 | boolean | true 时全部替换，默认 false 只替换第一处。 |

## Write · 写入文件

- 风险：**high**（高） · 基础工具

创建或完整覆盖 UTF-8 文本文件；局部修改请使用 Edit。高风险：调用前必须向用户确认。

父目录不存在时自动创建。覆盖已有文件前先用 Read 确认原文。成功时仅返回 bytes。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `file_path` | 是 | string | 允许范围内的绝对路径。 |
| `content` | 是 | string | 文件完整内容，不支持追加。 |

## Glob · 查找文件

- 风险：**low**（低） · 基础工具

按名称或扩展名查找文件；不知道文件准确路径时使用。只读。

默认跳过 .git、node_modules、venv、dist 等目录。files 是按修改时间倒序排列的绝对路径；
next_offset 非空时传回 offset 继续。匹配超过 2000 个文件时请缩小范围。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `pattern` | 是 | string | 相对 glob 模式，如 **/*.py。 |
| `path` | 否 | string | 允许范围内的绝对目录，留空使用当前目录。 |
| `offset` | 否 | integer | 默认 0。 |
| `limit` | 否 | integer | 默认及上限 50。 |

## Grep · 搜索文件内容

- 风险：**low**（低） · 基础工具

在文件或目录中搜索内容；找代码、配置或日志信息时优先使用，无需先读取整个文件。只读。

目录搜索默认跳过常见缓存、依赖和构建目录，并最多扫描 2000 个文件。
matches 返回匹配行、绝对路径和行号；单行最多搜索前 65536 个字符、返回前 1000 字符。next_offset 非空时传回
offset 继续。忽略大小写可在 pattern 前加 (?i)，查看上下文请用返回的路径和行号调用 Read。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `pattern` | 是 | string | Python 正则。 |
| `path` | 否 | string | 允许范围内的绝对文件或目录，留空搜索当前目录。 |
| `glob` | 否 | string | 文件模式过滤，如 **/*.py。 |
| `offset` | 否 | integer | 默认 0。 |
| `limit` | 否 | integer | 默认及上限 50。 |

## LS · 列出目录

- 风险：**low**（低） · 基础工具

列出目录的直接子项；浏览目录或确认路径时使用。只读。

目录排在文件前；entry 包含 name、绝对路径 path 和 is_dir；敏感项不会返回。
next_offset 非空时传回 offset 继续。项目超过 2000 个时请改用 Glob。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `path` | 否 | string | 绝对目录，留空使用当前目录。 |
| `offset` | 否 | integer | 默认 0。 |
| `limit` | 否 | integer | 默认及上限 50。 |

## Bash · 执行命令

- 风险：**high**（高） · 基础工具

执行 shell 命令（sh -c）。high 风险，需 Key 显式授权。

前台最多等 20s（低于工具全局超时），未完成自动转后台并返回 task_id；用 BashStatus 查询结果，用 BashStop 停止。
后台最长 30 分钟，超则强杀。run_in_background=true 立即后台。输出受 50KB 上限（头+尾截断）。
极少数灾难命令（rm -rf 关键路径 / mkfs / dd 覆写块设备 / 关机重启 / fork 炸弹）被拦拒绝。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `command` | 是 | string | shell 命令串，必填。 |
| `description` | 否 | string | 命令用途说明，仅进审计日志，不影响执行。 |
| `timeout` | 否 | integer | 前台愿意等待的秒数上限，默认 20，服务端封顶 20。 |
| `run_in_background` | 否 | boolean | true 时跳过前台等待，立即后台返回 task_id。 |

## BashStatus · 查询命令状态

- 风险：**low**（低） · 基础工具

查询后台任务的状态、输出与最终结果。low 只读。

task_id 由接入统一后台任务管理器的工具返回；此处只读其状态，绝不新起进程。
wait=true 时最多等 timeout 秒（默认上限 20s）再返回；任务完成时返回完整输出并清理。
运行中返回当前已捕获输出；未知 task_id 返回错误。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `task_id` | 是 | string | 后台任务标识，必填。 |
| `wait` | 否 | boolean | true 时阻塞等待任务结束（受前台 20s 上限）。 |
| `timeout` | 否 | integer | wait=true 时的等待秒数，0 表示用默认上限。 |

## BashStop · 终止后台任务

- 风险：**medium**（中） · 基础工具

终止或停止追踪后台任务。medium 风险。

适用于所有统一 task_id 的后台任务。子进程任务会被真实终止；函数线程任务无法强杀，
仅标记为 stopped，后台操作仍可能执行完成。未知 task_id 幂等返回 stopped。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `task_id` | 是 | string | 后台任务标识，必填。 |
