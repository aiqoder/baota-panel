# NodeJS 工具

共 6 个工具。

## NodeVersion · 管理Node版本

- 风险：**medium**（中）

检测/浏览/安装 Node 版本与全局模块（中风险：install/module 有副作用，list/online 只读）。

action=list 返回 data.versions（已装版本 + 各版本 npm/yarn/pnpm/pm2 是否存在）、
data.plugin_installed（插件是否已装，缺则无法在线安装）与 data.default_version。
action=online 返回可安装版本（data.total 本地分页；每项含 version/lts/security/installed
(setup==1 已装)/is_default；lts_only=true 只看稳定版；从新到旧排序），选好后用于 install。
action=install 装指定版本（如 v20.15.0），install_pm2/install_yarn 可顺带补全局模块（pm2 类型需要）。
action=module 给已装版本全局装 npm 模块（modules 逐个）。**pm2 类型项目启动依赖该版本已全局装 pm2**。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 否 | string | list/online/install/module，默认 list。 |
| `version` | 否 | string | install/module 的版本号（如 v20.15.0）。 |
| `install_pm2` | 否 | boolean | install 顺带装该版本 pm2。 |
| `install_yarn` | 否 | boolean | install 顺带装该版本 yarn。 |
| `lts_only` | 否 | boolean | online 只看稳定版（LTS）。 |
| `page` | 否 | integer | online 页码，从 1 起。 |
| `page_size` | 否 | integer | online 每页条数，默认 20，上限 100。 |
| `modules` | 否 | array/null | module 要装的模块名列表（如 ['pm2']）。 |

## NodeProjectCreate · 分析并创建Node项目

- 风险：**medium**（中）

把本机 Node 项目目录部署成面板可管理项目（nodejs/general/pm2，中风险：创建即注册并自动启动）。

analyze_only=true 只读分析（scripts/engines/依赖/node_modules/端口启发），不创建。
**nodejs_version 三类型均必填**（须已安装）；绑外网（domains）必须给 port；install_deps=true 先装依赖。
pm2 类型自动确保该版本已全局装 pm2（缺则调插件装，data.pm2_auto_installed 标记）。
nodejs 类型 env 注入面板有缺陷（存了不生效），要环境变量用 general。成功 data.project 含 run/listen。
参数按类型：nodejs 用 project_script；general 用 project_file+project_args；pm2 用 project_file+cluster/watch/max_memory_limit。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_type` | 否 | string | nodejs/general/pm2，默认 nodejs。 |
| `project_name` | 否 | string | 项目名，必填。 |
| `project_cwd` | 否 | string | 项目目录，必填。 |
| `project_script` | 否 | string | nodejs 类型启动脚本。 |
| `project_file` | 否 | string | general/pm2 启动文件路径。 |
| `project_args` | 否 | string | general/pm2 启动参数。 |
| `nodejs_version` | 否 | string | node 版本（如 v20.15.0），三类型必填。 |
| `pkg_manager` | 否 | string | npm/yarn/pnpm，默认 npm。 |
| `run_user` | 否 | string | 运行用户，默认 www。 |
| `port` | 否 | integer | 端口，绑外网必给。 |
| `domains` | 否 | array/null | '域名' 或 '域名:端口'。 |
| `env` | 否 | string | 每行 key=value；nodejs 注入缺陷用 general。 |
| `cluster` | 否 | integer | pm2 实例数，默认 1。 |
| `watch` | 否 | boolean | pm2 自动重载。 |
| `max_memory_limit` | 否 | integer | 内存上限 MB，0 用默认。 |
| `install_deps` | 否 | boolean | 先装依赖。 |
| `release_firewall` | 否 | boolean | 放行端口防火墙。 |
| `is_power_on` | 否 | boolean | 开机自启，默认 true。 |
| `ps` | 否 | string | 备注。 |
| `analyze_only` | 否 | boolean | true 只分析。 |

## NodeProjectInfo · 查看Node项目

- 风险：**low**（低）

查看面板管理的 Node 项目。只读。

project_name 留空返回全部项目列表（含运行态 run/listen）；给出时返回单项目详情：
project_config（类型/目录/脚本/node 版本/端口/域名/绑定状态）、run/pid、listen、ssl、
log_files（应用 + pm2 + nginx 日志路径，供文件读取工具查看）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 否 | string | 项目名，留空返回列表。 |

## NodeProjectControl · 控制Node项目进程

- 风险：**medium**（中）

启动/停止/重启 Node 项目进程（中风险：会中断或拉起服务，执行前说明影响）。

自动识别项目类型（nodejs/general/pm2）分发到对应子模型；已运行时启动/未运行时停止按面板语义返回。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（取自 NodeProjectInfo）。 |
| `action` | 否 | string | start/stop/restart，默认 restart。 |

## NodeProjectModify · 修改Node项目

- 风险：**medium**（中）

修改 Node 项目配置与域名（中风险：config 改后自动重启生效，pm2 重建 ecosystem）。

action=config 改启动脚本/文件/参数/node 版本/包管理器/端口/环境变量/运行用户/内存/开机自启/备注
（未传字段保留现值；改端口后已绑域名自动重写反代）。
action=add_domain/remove_domain 绑/删域名（至少保留一个）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名，必填。 |
| `action` | 否 | string | config/add_domain/remove_domain，默认 config。 |
| `project_script` | 否 | string | config 改 nodejs 类型启动脚本。 |
| `project_file` | 否 | string | config 改 general/pm2 类型启动文件。 |
| `project_args` | 否 | string | config 改启动参数。 |
| `nodejs_version` | 否 | string | config 切换 node 版本（须已安装）。 |
| `pkg_manager` | 否 | string | config 改 npm/yarn/pnpm。 |
| `port` | 否 | integer | config 改端口（0 不修改）。 |
| `env` | 否 | string | config 改环境变量（每行 key=value；nodejs 注入缺陷见创建工具）。 |
| `run_user` | 否 | string | config 改运行用户。 |
| `max_memory_limit` | 否 | integer | config 改内存上限 MB（0 不修改）。 |
| `is_power_on` | 否 | boolean/null | config 改开机自启。 |
| `ps` | 否 | string | config 改备注。 |
| `watch` | 否 | boolean/null | config 改 pm2 自动重载。 |
| `cluster` | 否 | integer | config 改 pm2 实例数（0 不修改）。 |
| `domains` | 否 | array/null | add_domain/remove_domain 的域名列表。 |

## NodeProjectDelete · 删除Node项目

- 风险：**high**（高）

删除 Node 项目（高风险、不可逆，调用前必须确认）。

停止进程（pm2 先 pm2 delete）、清理 pid/启动脚本/日志、删面板项目与域名记录、移除 Nginx 反代；项目目录与源码保留。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（先用 NodeProjectInfo 核对）。 |
