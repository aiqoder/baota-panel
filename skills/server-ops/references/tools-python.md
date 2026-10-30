# Python 工具

共 8 个工具。

## PythonVersion · 管理Python版本

- 风险：**medium**（中）

查看/浏览/移除本机 Python 解释器版本（中风险：remove 有副作用，list/online 只读）。

action=list 返回 data.sdk（all/streamline/pypy，每项 version/type/installed/install_command）、
data.installed 已装版本与 data.default_python。
action=online 返回云端可安装版本（data.versions 本地分页 data.total；is_all=false 只留每小版本最新
streamline；is_pypy=true 看 PyPy；每项 install_command 可直接交 Bash 后台执行）。
action=remove 移除已装版本（multi_remove_env，被项目占用会拒绝）。
**安装勿用本工具**：优先预编译（下载解压即用，快），无预编译包/特殊参数回落源码编译（慢）。用 Bash
后台执行 install_command（run_in_background=true）→ BashStatus 轮询 → 完成后 PythonEnv list 确认。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 否 | string | list/online/remove，默认 list。 |
| `version` | 否 | string | remove 的版本号（如 3.12.3）。 |
| `refresh` | 否 | boolean | list/online 强制刷新云端版本缓存。 |
| `is_all` | 否 | boolean | online 显示全部版本（含同小版本多个补丁版）。 |
| `is_pypy` | 否 | boolean | online 查 PyPy 版本。 |
| `page` | 否 | integer | online 页码，从 1 起。 |
| `page_size` | 否 | integer | online 每页条数，默认 20，上限 100。 |

## PythonEnv · 管理虚拟环境与包

- 风险：**medium**（中）

管理面板 Python 虚拟环境与包（pip）（中风险：create/remove/set_default/package 有副作用）。

action=list 返回 data.env_list（每项 bin_path/version/env_type/source/can_create/can_remove/projects
占用项目）与 data.default_python、data.source_priority。
action=create 基于系统(system)型 Python 建虚拟环境（venv_name+python_bin），落 /www/server/pyporject_evn/<name>。
**源优先级**（list 返回 source/source_priority）：① panel_installed 面板安装版本（推荐）→② system 系统
Python→③ panel_pyenv 面板自带 pyenv（精简打包，不适合普通用户，会被拒绝）。**已规避面板 create_venv_sync
假成功缺陷**（走 create_venv + 磁盘校验，不传 call_log）。
action=remove 移除虚拟环境（被项目使用/conda/非面板路径会拒绝）；set_default 设置命令行默认 Python
（path=python_bin；空串关闭）；package 在虚拟环境做 pip 管理（python_bin+package_action
install/uninstall/list；install 可带 package_version/pip_source；list 返回已装包）。慢，日志尾部回传。
建 Python 项目前必须先有可用虚拟环境（Create 要求 can_use_directly）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 否 | string | list/create/remove/set_default/package，默认 list。 |
| `venv_name` | 否 | string | create 的虚拟环境名（唯一）。 |
| `python_bin` | 否 | string | create 源环境 / package 目标环境的 python 路径。 |
| `ps` | 否 | string | create 的环境备注。 |
| `path` | 否 | string | remove/set_default 的 python_bin。 |
| `package_action` | 否 | string | package 的 install/uninstall/list，默认 install。 |
| `package_name` | 否 | string | package install/uninstall 的包名。 |
| `package_version` | 否 | string | package install 的版本约束（可选）。 |
| `pip_source` | 否 | string | package install 的 pip 源 URL（可选，默认阿里云镜像）。 |

## PythonProjectCreate · 分析并创建Python项目

- 风险：**medium**（中）

把本机 Python 项目目录部署成面板可管理项目（中风险：创建即注册并进入环境准备）。

analyze_only=true 只读分析（framework/runfile/xsgi/call_app/requirement/端口启发），不创建。
创建 = 面板 CreateProject 注册 → **后台异步环境准备**（装托管依赖+requirements+生成启动脚本+尝试启动）
→ 立即返回。**创建返回≠启动成功**：必须 PythonProjectInfo 轮询 prep_status 到 complete，再验 run/listen/日志。
前置：project_path 须已有可用虚拟环境 python_bin（can_use_directly，PythonEnv 建）；创建前先 analyze_only。
stype 仅 uwsgi/gunicorn/command（python 直跑用 command：project_cmd 支持占位符 {python_bin}/{rfile}/{path}/{parm}）。
uwsgi/gunicorn 需 rfile+call_app+port；command 需 project_cmd（port 可留 0）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 否 | string | 项目名，必填。 |
| `project_path` | 否 | string | 项目目录（须已存在、不含空格），必填。 |
| `python_bin` | 否 | string | 虚拟环境 python 路径，必填。 |
| `stype` | 否 | string | uwsgi/gunicorn/command，默认 uwsgi。 |
| `port` | 否 | integer | 端口，uwsgi/gunicorn 必填；command 可留 0。 |
| `xsgi` | 否 | string | wsgi/asgi，默认 wsgi。 |
| `rfile` | 否 | string | uwsgi/gunicorn 启动文件绝对路径。 |
| `call_app` | 否 | string | 可调用对象名，默认 app。 |
| `framework` | 否 | string | 框架，默认 python。 |
| `project_cmd` | 否 | string | command 启动命令，占位符由工具替换，如 "{python_bin} -u {rfile}"。 |
| `user` | 否 | string | 运行用户，默认 root。 |
| `env_list` | 否 | array/null | 环境变量列表，每项 {"k","v"}（如 [{"k":"PORT","v":"9000"}]；"K=V" 会被 schema 拒）。 |
| `env_file` | 否 | string | 环境变量文件路径（可选）。 |
| `requirement_path` | 否 | string | requirements 文件路径（可选，准备阶段自动装）。 |
| `initialize` | 否 | string | 环境准备阶段的初始化命令（可选）。 |
| `auto_run` | 否 | boolean | 开机自启，默认 false。 |
| `processes` | 否 | integer | 进程数，默认 4。 |
| `threads` | 否 | integer | 线程数，默认 2。 |
| `release_firewall` | 否 | boolean | 放行端口防火墙，默认 false。 |
| `analyze_only` | 否 | boolean | true 只分析。 |

## PythonProjectInfo · 查看Python项目

- 风险：**low**（低）

查看面板管理的 Python 项目。只读。

project_name 留空返回全部项目列表（含运行态 run/listen）；给出时返回单项目详情：
project_config（stype/目录/python_bin/端口/域名/env）、prep_status（环境准备 running/complete/failure）、
run/pids/listen/cpu/mem、python_bin/python_version、services（关联服务 pid/ports）、log_files
（应用日志 + 环境准备日志 + 关联服务日志目录）；include_packages=true 附虚拟环境已装包。
排错：prep_status=failure 读环境准备日志；run=false 读 stype 对应应用日志。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 否 | string | 项目名，留空返回列表。 |
| `include_packages` | 否 | boolean | 详情是否附带已装包列表。 |

## PythonProjectControl · 控制Python项目进程

- 风险：**medium**（中）

启动/停止/重启 Python 项目（中风险：会中断或拉起服务，执行前说明影响）。

action=start/stop/restart 走面板 StartProject/StopProject/RestartProject（主服务+关联进程一起启停），
返回"指令已执行"，**需再用 PythonProjectInfo 核验实际状态**；action=start_main/stop_main 只启/停主服务
（同步返回实际结果）。注意：环境准备中（prep_status=running）面板会拒绝启停。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（取自 PythonProjectInfo）。 |
| `action` | 否 | string | start/stop/restart/start_main/stop_main，默认 restart。 |

## PythonProjectService · 管理项目关联进程

- 风险：**medium**（中）

管理 Python 项目关联进程（如 celery worker）。中风险：启停会中断进程。

关联进程存于 project_config.services（每条 {sid,name,command,level,log_type}），主服务是隐式 sid='main'
（用 PythonProjectControl 启停）。命令以 celery 开头自动按 CeleryService 匹配 PID。
action=list 返回全部服务（含主服务）pid/ports；add 注册（name 唯一+command 唯一，name 不能含空白/$/^/反引号）；
start/stop/restart 按 sid 启停；remove **停止并删除**（面板 remove_service 本身不停进程，本工具先 stop 再删，
避免孤儿进程）；log 查看服务日志（data.log）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名，必填。 |
| `action` | 否 | string | list/add/start/stop/restart/remove/log，默认 list。 |
| `sid` | 否 | string | start/stop/restart/remove/log 的服务 id（list 返回）。 |
| `name` | 否 | string | add 的服务名。 |
| `command` | 否 | string | add 的启动命令（如 "celery -A demo worker"）。 |
| `level` | 否 | integer | add 的启动顺序优先级，默认 11（主服务为 10）。 |
| `log_type` | 否 | string | add 的日志模式 append/error/off，默认 append。 |

## PythonProjectModify · 修改Python项目

- 风险：**medium**（中）

修改 Python 项目配置、域名与反代（中风险：config 改后停止并重启项目）。

action=config 改 stype/xsgi/rfile/call_app/project_cmd/parm、端口/用户/进程线程/开机自启/日志/环境变量
（未传字段保留现值，改后自动重启生效）。
action=add_domain 绑域名（面板对已存在域返回"已存在"=实际已绑定、非失败，本工具按逐域如实上报）。
action=remove_domain 删域名（至少保留一个）。**注意：面板移除域名会连带停止项目服务（主+协同，与是否剩
最后一个无关，已实证），本工具不自动恢复，移除后须 PythonProjectInfo 复核并在需要时手动重启。**
action=bind_extranet/unbind_extranet 开关外网映射（反代 add_proxy 需先开外网映射）。
action=add_proxy 更新/新增 path→port 反代（proxy_path+proxy_port，写 proxy_info 并重写 nginx）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名，必填。 |
| `action` | 否 | string | config/add_domain/remove_domain/bind_extranet/unbind_extranet/add_proxy，默认 config。 |
| `stype` | 否 | string | config 改 uwsgi/gunicorn/python/command。 |
| `xsgi` | 否 | string | config 改 wsgi/asgi。 |
| `rfile` | 否 | string | config 改启动文件（须在项目目录下）。 |
| `call_app` | 否 | string | config 改可调用对象名。 |
| `project_cmd` | 否 | string | config 改 command 启动命令（占位符由工具替换，如 "{python_bin} -u {rfile}"）。 |
| `parm` | 否 | string | config 改 python 直跑附加参数。 |
| `port` | 否 | integer | config 改端口（0 不修改）。 |
| `user` | 否 | string | config 改运行用户。 |
| `processes` | 否 | integer | config 改进程数（0 不修改）。 |
| `threads` | 否 | integer | config 改线程数（0 不修改）。 |
| `auto_run` | 否 | boolean/null | config 改开机自启。 |
| `logpath` | 否 | string | config 改日志目录。 |
| `loglevel` | 否 | string | config 改日志等级（gunicorn）。 |
| `is_http` | 否 | boolean/null | config 改 uwsgi 是否走 http。 |
| `env_list` | 否 | array/null | config 替换环境变量列表（每项 {"k","v"}；传 [] 清空；"K=V" 会被 schema 拒）。 |
| `env_file` | 否 | string | config 改环境变量文件。 |
| `domains` | 否 | array/null | add_domain/remove_domain 的域名列表。 |
| `proxy_path` | 否 | string | add_proxy 路由前缀，默认 /。 |
| `proxy_port` | 否 | integer | add_proxy 后端端口，必填。 |

## PythonProjectDelete · 删除Python项目

- 风险：**high**（高）

删除 Python 项目（高风险、不可逆，调用前必须确认）。

停止进程（含关联进程）、清理 pid/启动脚本/日志/nginx conf/反代、删面板项目与域名记录；项目目录与源码保留。
**删除不删除虚拟环境**：venv 与项目非强绑定（可复用/共享），面板接口逻辑即如此；如需移除用
PythonEnv(action='remove', path=<python_bin>)。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `project_name` | 是 | string | 项目名（先用 PythonProjectInfo 核对）。 |
