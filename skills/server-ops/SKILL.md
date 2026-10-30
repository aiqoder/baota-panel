---
name: server-ops
description: >
  通过 SSH 直连服务器做真实运维操作。默认走通用通道（执行命令/脚本、传文件、查系统与磁盘/内存/负载、
  看服务与日志、配防火墙、管进程与定时任务）；当探测到目标机装了宝塔面板时，自动优先使用面板的
  98 个 bt_agent_mcp 运维工具（建站、部署 Java/Node/Python/Go/HTML 项目、SSL/反代、数据库、Docker、
  软件与系统服务）。当用户要求对某台服务器执行操作、排查故障、部署上线、查看服务器状态时使用。
  触发词：服务器运维、SSH 执行命令、部署项目、建站、SSL、数据库、Docker、防火墙、看日志、装/查/删东西、
  宝塔、bt-mcp。飞牛 NAS / fnOS 不走本技能，改用 fnos。
version: 2.1.0
---

# 服务器运维（通用通道 + 宝塔面板工具集）

你通过 SSH 登录用户配置的服务器，**真实执行**运维操作并如实汇报。
同一套脚本同时支持两类目标机：

- **普通 Linux 服务器** → 用 `ops` 通用通道（命令/脚本/文件/系统信息）
- **宝塔面板服务器** → 探测到后优先用 `ops bt` 调用面板的 98 个工具

## 本机依赖：零 Python

`ops` 是随包分发的 **POSIX sh** 脚本，配包内 `skills/server-ops/bin/` 的 sshpass 工作。
本机**不需要安装任何 Python 包**：

- SSH 协议由系统自带 `ssh` / `scp` 完成（Windows 10+ 启用「OpenSSH 客户端」即可）；
- 需要密码认证的目标机，由包内 sshpass 在伪终端里自动应答口令提示；
- 密码只经环境变量 `BT_PANELS` 注入，不出现在命令行参数或日志里。

**每个 shell_exec 都是新进程，每条命令都要写全路径**（macOS / Linux 用 `sh` 调用；
Windows 用 `cmd` 包装脚本）：

```bash
# macOS / Linux
SKILL_DIR="${CHENGZI_PACKAGE_DIR}/skills/server-ops/scripts"
REF="${CHENGZI_PACKAGE_DIR}/skills/server-ops/references"
sh "$SKILL_DIR/ops" servers
sh "$SKILL_DIR/ops" -s hk-1 exec 'uptime'
```

```powershell
# Windows (PowerShell)
$ops = "$env:CHENGZI_PACKAGE_DIR\skills\server-ops\scripts\ops.cmd"
& $ops servers
& $ops -s hk-1 exec 'uptime'
```

下文所有 `ops ...` 示例都指上面这条完整命令（`sh "$SKILL_DIR/ops" ...`）。

## 第一步永远是分清目标机类型

```bash
sh "$SKILL_DIR/ops" detect                # 单台/默认
sh "$SKILL_DIR/ops" -s <别名> detect       # 指定目标
sh "$SKILL_DIR/ops" -s <别名> detect --json
```

判定：目标机上 `bt` 命令可用，或存在 `/www/server/panel` → 宝塔服务器。

| 探测结果 mode | 用什么 |
| --- | --- |
| `baota` | 优先 `ops bt` 面板工具集 |
| `baota-no-mcp` | 用 `ops exec/script` 通用命令；可顺带提示用户安装 bt_agent_mcp 插件 |
| `generic` | 用 `ops exec/script` 通用命令/脚本 |

不确定某台机是什么，先 `detect`；不要凭「应该是宝塔」猜测。
探测全是只读，不改远端状态；同一会话里结果可复用，不必每步重探。

## 路径与脚本

```bash
SKILL_DIR="${CHENGZI_PACKAGE_DIR}/skills/server-ops/scripts"
REF="${CHENGZI_PACKAGE_DIR}/skills/server-ops/references"
ls "$SKILL_DIR" "$REF"
```

**统一用 `sh` 调用（Windows 用同名 `.cmd`）：**

| 命令 | 用途 | 适用 |
| --- | --- | --- |
| `ops detect` | 探测系统信息 + 是否宝塔，给出建议通道 | 所有 |
| `ops exec/script/put/get/sysinfo/probe` | 通用执行：命令 / 脚本 / 上传下载 / 系统信息 | 所有 |
| `ops sudo` | 提权执行（默认需确认） | 所有 |
| `ops bt` | 调用宝塔面板工具（核心入口） | 仅宝塔 |
| `ops bt-tools` | 列出服务器上当前注册的面板工具 | 仅宝塔 |
| `ops servers` | 查看已配置服务器清单与连接方式 | 所有 |
| `lib/` | 公共库（清单解析、连接封装、远端负载） | 不直接执行 |

## 多台服务器（服务器清单）

用户在桌面端设置页以**表格**逐行填写「服务器清单」（环境变量 `BT_PANELS`，数量不限），
列固定为：**别名 | 主机 | 端口 | 用户 | 密码**。

- 平台按「列用 `|` 拼接、行用换行」注入；脚本按同一规则解析（兼容旧粘贴格式）。
- 主机必填；端口留空 = 22，用户留空 = root。
- 密码留空（或写 `-`）→ 该台改用本机 SSH 私钥认证（`~/.ssh` 默认密钥）。
- 别名留空 → 用主机名代替。

**先看配了什么**（不连网、不打印密码）：

```bash
sh "$SKILL_DIR/ops" servers
```

选目标机统一用 `--server`（简写 `-s`），参数是**别名**（也可用编号 1、2、3…）：

- 只配了一台 → 自动选中，可直接调用。
- 配了多台 → 必须 `-s <别名>` 指定，否则报错并列出清单。
- 支持唯一前缀：`-s hk` 在只有 `hk-1` 时等价于 `-s hk-1`。

## 通道 A：通用执行（所有服务器）

```bash
# 执行命令（退出码原样透传）
sh "$SKILL_DIR/ops" -s hk-1 exec 'systemctl status nginx --no-pager'
sh "$SKILL_DIR/ops" -s hk-1 exec 'df -h; free -m; uptime'

# 提权（默认要确认；非交互脚本里显式 --yes）
sh "$SKILL_DIR/ops" -s hk-1 --yes sudo 'apt-get install -y jq'

# 执行本地脚本 / 传文件
sh "$SKILL_DIR/ops" -s hk-1 script ./deploy.sh
cat ./setup.sh | sh "$SKILL_DIR/ops" -s hk-1 script -
sh "$SKILL_DIR/ops" -s hk-1 put ./app.tar.gz /tmp/app.tar.gz
sh "$SKILL_DIR/ops" -s hk-1 get /var/log/nginx/error.log ./logs/

# 系统信息 / 能力探测
sh "$SKILL_DIR/ops" -s hk-1 sysinfo
sh "$SKILL_DIR/ops" -s hk-1 probe
```

命令交给远端登录 shell 执行，登录环境齐全，管道重定向可直接写。
详细配方与系统信息字段见 `$REF/generic-ops.md`。

## 通道 B：宝塔面板工具集（仅宝塔服务器）

统一入口：`ops bt [--server <别名|编号>] <ToolId> '{"参数":"值"}'`，内部完成：
SSH（sshpass 口令注入或私钥）→ 服务器 → 面板解释器 → 注册 Registry →
`reg.call(tool_id, args)` → 打印 JSON。

```bash
# 无参数工具
sh "$SKILL_DIR/ops" -s hk-1 bt DatabaseList
sh "$SKILL_DIR/ops" -s hk-1 bt SystemInfo

# 带参数
sh "$SKILL_DIR/ops" -s hk-1 bt DatabaseList '{"search":"shop"}'
sh "$SKILL_DIR/ops" -s hk-1 bt ServiceStatus '{"service_names":["nginx","mysql"]}'
sh "$SKILL_DIR/ops" -s hk-1 bt SiteCreate '{"domain":"a.com","site_path":"/www/wwwroot/a"}'
```

输出即工具返回值（统一信封 `{"status":...,"msg":...,"data":...}`），可直接 `| jq`。

全部 98 个工具按领域整理，**完整参数/类型/风险**见 `$REF/`：

| 领域 | 工具数 | 文档 |
| --- | --- | --- |
| 基础(文件/命令) | 9 | references/tools-basics.md |
| 网站/SSL | 15 | references/tools-website.md |
| 数据库 | 6 | references/tools-database.md |
| Docker | 10 | references/tools-docker.md |
| 反向代理 | 5 | references/tools-proxy.md |
| 防火墙 | 5 | references/tools-firewall.md |
| 软件 | 3 | references/tools-software.md |
| 系统服务 | 2 | references/tools-service.md |
| 系统信息 | 1 | references/tools-system.md |
| 安全 | 1 | references/tools-security.md |
| Java 项目 | 6 | references/tools-java.md |
| NodeJS 项目 | 6 | references/tools-nodejs.md |
| Python 项目 | 8 | references/tools-python.md |
| Go 项目 | 6 | references/tools-go.md |
| HTML 项目 | 4 | references/tools-html.md |
| SSH | 3 | references/tools-ssh.md |
| 计划任务 | 2 | references/tools-crontab.md |
| 通知 | 3 | references/tools-notify.md |
| 网络 | 3 | references/tools-network.md |
| 速查表 | 98 | references/cheatsheet.md |

读取方式：`cat "$REF/tools-database.md"`。
不确定某工具是否存在（版本差异）→ 先跑 `sh "$SKILL_DIR/ops" -s hk-1 bt-tools <关键字>` 现查。
宝塔缺失 MCP 插件时 `ops bt` 退出码 5，此时改用通道 A。

## 四条必须牢记的规则

1. **高风险操作必须先取得用户明确同意再执行。** 含：删站（`SiteDelete`）、删库（`DatabaseDelete`）、
   写 SQL（`MysqlExecute`）、删项目、改防火墙、卸载软件、以及通用通道里的 `rm -rf`、`mkfs`、
   分区/磁盘、关机重启、`docker rm/prune`、批量 kill 等。先在对话里说明影响范围，得到明确同意再动手；
   含糊的「你看着办」不算同意。
2. **先查后改，先只读后写入。** 站点/项目/域名/端口/进程，先用只读方式确认现状，不要凭记忆猜。
3. **异步任务要轮询。** 宝塔耗时工具会返回 `data.task_id` + `status="running"`（如 `DatabaseBackup`、
   `GoVersion install`、`ImagePull`、软件安装）。用 `ops bt <别名> BashStatus '{"task_id":"...","wait":true}'`
   取结果，`BashStop` 终止。后台任务最长约 30 分钟。
4. **凭据保密。** 密码只在环境变量里，不要 `echo`/`env` 打印、不要写进命令参数或日志。

## 特权调用的边界

| 项 | 行为 |
| --- | --- |
| 宝塔 `confirm=true` 工具 | 直调**不触发**二次确认闸，直接执行 → 靠你自己遵守规则 1 |
| 宝塔 `basic_tool` 工具 | 可直调；`Read/Edit/Write` 受 `filesystem.py` 敏感路径限制（如 `/etc` 被拒） |
| IP 白名单 / 限流 / API Key | **全部绕过**——你就是 root 级别特权调用 |
| 返回值/超时 | 宝塔工具有 50KB 裁剪；通用通道无裁剪，但长输出请自行收敛 |
| 平台注入变量 | `BT_PANELS` 由桌面端在运行时注入，脚本只读这个变量 |

## 执行流程

1. **定目标机**：多台时先确认 `-s` 别名（不确定就 `ops servers`）。
2. **判类型**：`ops detect` 看是不是宝塔，选通道 A 或 B。
   - 宝塔：按领域读 `$REF/tools-<领域>.md`，或 grep `$REF/cheatsheet.md` 定位 `ToolId`。
   - 通用：按 `$REF/generic-ops.md` 的配方拼命令或写脚本。
3. **核对参数/现状**：确认必填项与类型；状态不明先只读探明（如 `SiteList`、`*ProjectInfo`、`ss -lntp`）。
4. **评估风险**：命中规则 1 的动作 → 先向用户确认。
5. **执行**：`ops exec/script` 或 `ops bt`。
6. **处理结果**：宝塔 `status=false` 如实上报 `msg`，出现 `task_id` 则轮询；通用通道看退出码。
7. **汇报**：实际操作内容、关键数据、副作用与后续影响；**失败不美化**。

## 示例

**示例 1：先判断类型**

```bash
sh "$SKILL_DIR/ops" -s hk-1 detect
# mode=generic → 普通服务器，用 ops exec；mode=baota → 用 ops bt
```

**示例 2：普通服务器上查状态、拉日志**

```bash
sh "$SKILL_DIR/ops" -s new-1 exec 'uptime; df -h /; free -m'
sh "$SKILL_DIR/ops" -s new-1 exec 'journalctl -u myapp -n 200 --no-pager'
```

**示例 3：宝塔服务器上备份数据库（异步，需轮询）**

```bash
TID=$(sh "$SKILL_DIR/ops" -s hk-1 bt DatabaseBackup '{"name":"shop"}' | jq -r '.data.task_id')
sh "$SKILL_DIR/ops" -s hk-1 bt BashStatus "{\"task_id\":\"$TID\",\"wait\":true}"
```

**示例 4：宝塔服务器上部署 Go 项目**

```bash
sh "$SKILL_DIR/ops" -s hk-1 bt GoProjectInfo
sh "$SKILL_DIR/ops" -s hk-1 bt GoProjectCreate '{"project_name":"myapp","project_exe":"/www/wwwroot/myapp/app","port":9000,"run_user":"www"}'
sh "$SKILL_DIR/ops" -s hk-1 bt GoProjectInfo '{"project_name":"myapp"}'   # 核验
```

**示例 5：高风险写库（先只读，得到同意后再执行）**

```bash
# 1) 先只读确认
sh "$SKILL_DIR/ops" -s hk-1 bt MysqlQuery '{"sql":"SELECT id,name FROM orders WHERE id=%s","database":"shop","params":[42]}'
# 2) 向用户说明「将删除 orders 表 id=42 的记录」，得到明确同意后：
sh "$SKILL_DIR/ops" -s hk-1 bt MysqlExecute '{"sql":"DELETE FROM orders WHERE id=%s","database":"shop","params":[42]}'
```

## 注意事项

- **类型先行**：不清楚目标机是不是宝塔就先 `detect`，别在普通机上空试 `ops bt`。
- **异步不空等**：拿到 `task_id` 立即轮询，不要重复发起同一个耗时任务。
- **50KB 上限（仅宝塔工具）**：查日志/大表时分页或缩小范围。
- **幂等优先**：启动类/放行类操作先看状态，避免重复执行导致端口冲突或重复规则。
- **目标明确**：多台服务器时，不要凭「应该是这台」猜测，先 `ops servers` 确认别名。
- **脚本不依赖 stdin**：sshpass 不转发标准输入，`script` 是把脚本内联执行的，别写读 stdin 的逻辑。

## 参考资料

- `references/generic-ops.md` — 通用通道：ops 用法、系统信息字段、常见运维配方
- `references/direct-call.md` — 宝塔直调原理、内联模板、与 MCP 通道差异详解
- `references/cheatsheet.md` — 98 个宝塔工具速查表
- `references/tools-*.md` — 各领域宝塔工具的参数与说明
