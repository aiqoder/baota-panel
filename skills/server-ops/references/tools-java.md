# Java 工具

共 6 个工具。

## JavaJdk · 管理JDK

- 风险：**medium**（中）

管理本机 JDK（中风险：install/add_local 有副作用，list 只读）。

action=list 返回 data.jdks（每项 name/path/operation/is_current；
operation: 0 未装 / 1 已装 / 2 系统自带 / 3 安装中）。
action=install 异步安装指定版本（提交面板任务队列），用 list 轮询 operation 3→1 确认完成。
action=add_local 登记本机已有但未被面板收录的 JDK 路径。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 否 | string | list/install/add_local，默认 list。 |
| `version` | 否 | string | install 的版本号（如 jdk-17.0.8，可先用 list 确认）。 |
| `jdk_path` | 否 | string | add_local 的 JDK 可执行文件路径（如 .../bin/java）。 |

## JavaProjectCreate · 分析并创建Java项目

- 风险：**medium**（中）

把本机 jar 部署成面板可管理 Java 项目（中风险：创建即注册并自动启动）。

analyze_only=true 只读分析（端口/生效配置/隐患），不创建；创建时复用分析补全缺失参数。
传 domains 时自动建 Nginx 反代（best-effort，失败 data.proxy_created=false，用
JavaProjectModify add_proxy 补，否则域名 403）。
缺省：port=jar 分析值、jdk_path=已装 JDK、project_cmd 自动拼装。成功 data 含上述参数 + analysis。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 否 | string | 项目名（面板内唯一），必填。 |
| `jar_path` | 否 | string | jar 绝对路径，必填。 |
| `jdk_path` | 否 | string | JDK 根路径，可带 /bin/java；缺省自动选。 |
| `port` | 否 | integer | 应用端口，缺省用 jar 分析值。 |
| `run_user` | 否 | string | 运行用户，默认 www。 |
| `project_cmd` | 否 | string | 完整启动命令，缺省自动拼装。 |
| `domains` | 否 | array/null | 域名列表，'域名' 或 '域名:端口'。 |
| `ps` | 否 | string | 备注。 |
| `analyze_only` | 否 | boolean | true 只分析。 |
| `release_firewall` | 否 | boolean | 是否放行端口防火墙。 |
| `proxy_path` | 否 | string | 反代路由前缀，默认 '/'；置空只绑域名。 |

## JavaProjectInfo · 查看Java项目

- 风险：**low**（低）

查看面板管理的 Java 项目。只读。

project_name 留空返回全部项目列表（含运行态 pid/listen）；给出时返回单项目详情：
project_config（jar/JDK/启动命令/日志/域名/绑定状态）、pid、监听端口、ssl、log_files
（应用日志 + nginx 访问/错误日志路径，供文件读取工具查看）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 否 | string | 项目名，留空返回列表。 |

## JavaProjectControl · 控制Java项目进程

- 风险：**medium**（中）

启动/停止/重启 Java 项目进程（中风险：会中断或拉起服务，执行前说明影响）。

已运行时启动/未运行时停止按面板语义返回（不视为错误）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（取自 JavaProjectInfo）。 |
| `action` | 否 | string | start/stop/restart，默认 restart。 |

## JavaProjectModify · 修改Java项目

- 风险：**medium**（中）

修改 Java 项目配置与域名（中风险：config 改后不会自动重启，下次重启才生效）。

action=config 改运行用户/JDK/jar/启动命令/守护状态（未传字段保留现值；改端口=改 project_cmd 的 --server.port=）。
add_domain/remove_domain 绑/删域名（至少保留一个）；bind_extranet/unbind_extranet 开关外网映射
（只开外网不建反代，需再 add_proxy 才转发到应用）；add_proxy 新增反代（proxy_port 必填，代理到
127.0.0.1:<proxy_port>，proxy_dir 默认 '/'）；remove_proxy 按 proxy_id 删；proxy_list 只读列反代。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名，必填。 |
| `action` | 否 | string | config/add_domain/remove_domain/bind_extranet/unbind_extranet/ add_proxy/remove_proxy/proxy_list，默认 config。 |
| `run_user` | 否 | string | config 改运行用户。 |
| `project_jdk` | 否 | string | config 改 JDK 路径。 |
| `project_jar` | 否 | string | config 改 jar 路径（须与 project_cmd 一致）。 |
| `project_cmd` | 否 | string | config 改启动命令。 |
| `daemon_status` | 否 | boolean/null | config 开关守护（崩溃自动拉起）。 |
| `ps` | 否 | string | config 改备注（缺省保留现值）。 |
| `domains` | 否 | array/null | add_domain/remove_domain 的域名列表。 |
| `proxy_port` | 否 | integer | add_proxy 目标端口（应用端口）。 |
| `proxy_dir` | 否 | string | add_proxy 路由前缀，默认 '/'。 |
| `proxy_id` | 否 | string | remove_proxy 要删的反代 id（proxy_list 获取）。 |

## JavaProjectDelete · 删除Java项目

- 风险：**high**（高）

删除 Java 项目（高风险、不可逆，调用前必须确认）。

停止并移除守护进程、清理 pid/启动脚本/环境变量/日志、删面板项目与域名记录、移除 Nginx 反代；jar 源文件保留。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（先用 JavaProjectInfo 核对）。 |
