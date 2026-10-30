# Go 工具

共 6 个工具。

## GoVersion · 管理Go环境

- 风险：**medium**（中）

管理本机 Go SDK（中风险：install/use/uninstall/goproxy 有副作用，list 只读）。

action=list 返回 data.installed（已装版本）、data.available（可安装版本，**分页**：data.total/page/
page_size；每项含 install_command）、data.used（当前使用版本）与 data.goproxy（现状 + 常用源列表）。
**stable_only=true 只看每个小版本最新的稳定版**（忽略历史/补丁版，列表更短）；page/page_size 翻页
（page_size 上限 100）。可用版本较多，分页取数，避免结果超限。
action=install **不同步安装**：校验版本在可装列表后返回 install_command + install_hint，
**需用 Bash 后台执行防超时**（Bash(command=install_command, run_in_background=true) → BashStatus 轮询；
一次只装一个版本）。
action=use 切换当前使用版本（软链 /usr/local/btgo）；action=uninstall 卸载指定版本；
action=goproxy 设置 GOPROXY（如 https://goproxy.cn,direct）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 否 | string | list/install/use/uninstall/goproxy，默认 list。 |
| `version` | 否 | string | install/use/uninstall 的版本号（如 go1.22.4，可省 'go' 前缀）。 |
| `goproxy` | 否 | string | goproxy 时要设置的代理地址（list 的 data.goproxy.list 有常用源）。 |
| `stable_only` | 否 | boolean | list 只看每小版本最新稳定版（默认 false 看全部）。 |
| `page` | 否 | integer | list 页码，从 1 起。 |
| `page_size` | 否 | integer | list 每页条数，默认 20，上限 100。 |

## GoProjectCreate · 创建Go项目

- 风险：**medium**（中）

把编译好的 Go 二进制部署成面板可管理项目（中风险：创建即注册并自动启动）。

Go 是编译产物，无源码分析步骤：给二进制路径 + 端口 + 启动命令（缺省=二进制本身）直接注册。
创建即同步启动（nohup 脚本 + pid 文件，无 systemd/pm2）；成功后用 GoProjectInfo 核验 run/listen。
传 domains 自动开启外网映射（bind_extranet=1）；项目目录与二进制文件不会被删除。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 否 | string | 项目名（字母/数字/下划线，面板内唯一），必填。 |
| `project_exe` | 否 | string | Go 可执行文件绝对路径，必填。 |
| `port` | 否 | integer | 应用监听端口（10-65535），必填。 |
| `project_cmd` | 否 | string | 启动命令，缺省=project_exe。 |
| `run_user` | 否 | string | 运行用户，默认 www。 |
| `domains` | 否 | array/null | 绑定域名列表，'域名' 或 '域名:端口'（给则开启外网映射）。 |
| `env_list` | 否 | array/null | 环境变量列表，每项 {"k","v"}（如 [{"k":"PORT","v":"9000"}]；"K=V" 会被 schema 拒）。 |
| `env_file` | 否 | string | 环境变量文件绝对路径（可选）。 |
| `is_power_on` | 否 | boolean | 开机自启，默认 true。 |
| `ps` | 否 | string | 备注。 |
| `release_firewall` | 否 | boolean | 是否放行端口防火墙。 |

## GoProjectInfo · 查看Go项目

- 风险：**low**（低）

查看面板管理的 Go 项目。只读。

project_name 留空返回全部项目列表（含运行态 run/listen）；给出时返回单项目详情：
project_config（exe/启动命令/端口/运行用户/域名/环境变量）、run/listen/ssl、log_files
（应用日志 + nginx 访问/错误日志路径，供文件读取工具查看）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 否 | string | 项目名，留空返回列表。 |

## GoProjectControl · 控制Go项目进程

- 风险：**medium**（中）

启动/停止/重启 Go 项目进程（中风险：会中断或拉起服务，执行前说明影响）。

Go 进程为 nohup 脚本 + pid 文件管理（无守护）；未启动时 stop/restart 面板返回"项目未启动"，如实上报。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（取自 GoProjectInfo）。 |
| `action` | 否 | string | start/stop/restart，默认 restart。 |

## GoProjectModify · 修改Go项目

- 风险：**medium**（中）

修改 Go 项目配置与域名（中风险：config 改后自动重启生效）。

action=config 改可执行文件/启动命令/端口/运行用户/开机自启/环境变量/备注（未传字段保留现值）。
**面板 modify_project 无条件读 project_exe 与 project_ps**——本工具始终带上现值，不会漏传。
action=add_domain/remove_domain 绑/删域名（面板保证至少保留一个域名）。
action=bind_extranet/unbind_extranet 开关外网映射（需先有域名）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名，必填。 |
| `action` | 否 | string | config/add_domain/remove_domain/bind_extranet/unbind_extranet，默认 config。 |
| `project_exe` | 否 | string | config 改可执行文件绝对路径。 |
| `project_cmd` | 否 | string | config 改启动命令。 |
| `port` | 否 | integer | config 改端口（0 不修改）。 |
| `run_user` | 否 | string | config 改运行用户。 |
| `is_power_on` | 否 | boolean/null | config 改开机自启。 |
| `env_list` | 否 | array/null | config 替换环境变量列表（每项 {"k","v"}；面板仅在非空时生效）。 |
| `env_file` | 否 | string | config 改环境变量文件。 |
| `ps` | 否 | string | config 改备注。 |
| `domains` | 否 | array/null | add_domain/remove_domain 的域名列表。 |

## GoProjectDelete · 删除Go项目

- 风险：**high**（高）

删除 Go 项目（高风险、不可逆，调用前必须确认）。

停止进程、清理 pid/启动脚本/日志、删面板项目与域名记录、移除 Nginx 反代；**项目目录与二进制文件保留**。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（先用 GoProjectInfo 核对）。 |
