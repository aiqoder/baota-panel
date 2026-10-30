# 通用运维（非宝塔服务器）

目标服务器**没有**宝塔面板时，用 `ops` 的通用通道直接经 SSH 执行操作。
这是本技能的默认能力，所有 Linux 服务器都可用；宝塔工具集只是探测到面板后的「加成」。

## 本机依赖：零 Python

`ops` 是随包分发的 **POSIX sh** 脚本，配合包内 `skills/server-ops/bin/` 里的 sshpass
二进制工作，**本机不需要 Python**：

- SSH 协议由系统自带的 `ssh` / `scp` 完成（macOS / Linux 默认有；Windows 10+ 启用「OpenSSH 客户端」即可）；
- 需要密码认证的机器，由包内 sshpass 在伪终端里自动应答用户名密码提示；
- 密码只经环境变量 `BT_PANELS` 传入，不出现在命令行参数或日志里。

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

下文所有 `ops ...` 示例都指上面这条完整命令。

## 分流：先探测，再选通道

```bash
sh "$SKILL_DIR/ops" detect              # 单台（只配一台时）
sh "$SKILL_DIR/ops" -s hk-1 detect      # 指定别名
sh "$SKILL_DIR/ops" -s hk-1 detect --json
```

输出 `mode` 决定后续走哪条路：

| mode | 含义 | 用什么 |
| --- | --- | --- |
| `baota` | 宝塔面板 + bt_agent_mcp 就绪 | `ops bt` 面板工具集（优先） |
| `baota-no-mcp` | 有宝塔但缺 MCP 插件 | `ops exec/script` 通用命令；可提示用户装插件 |
| `generic` | 普通 Linux 服务器 | `ops exec/script` 通用命令/脚本 |

判定依据：`bt` 命令存在，或 `/www/server/panel` 目录存在 → 视为宝塔服务器。
探测全部是只读操作，不改动远端任何状态。

## ops 的子命令

```bash
# 1) 执行命令（退出码原样透传）
sh "$SKILL_DIR/ops" -s hk-1 exec 'systemctl status nginx --no-pager'
sh "$SKILL_DIR/ops" -s hk-1 exec 'df -h && free -m'

# 2) 提权执行（需前台确认；非交互场景显式 --yes）
sh "$SKILL_DIR/ops" -s hk-1 --yes sudo 'apt-get install -y jq'

# 3) 执行本地脚本（路径，或 - 从 stdin 读）
sh "$SKILL_DIR/ops" -s hk-1 script ./deploy.sh
cat ./setup.sh | sh "$SKILL_DIR/ops" -s hk-1 script -

# 4) 上传 / 下载
sh "$SKILL_DIR/ops" -s hk-1 put ./app.tar.gz /tmp/app.tar.gz
sh "$SKILL_DIR/ops" -s hk-1 get /var/log/nginx/error.log ./logs/

# 5) 系统信息（JSON）
sh "$SKILL_DIR/ops" -s hk-1 sysinfo

# 6) 能力探测（系统信息 + 是否宝塔）
sh "$SKILL_DIR/ops" -s hk-1 probe
```

`exec` 的命令会交给远端登录 shell 执行，登录环境变量（PATH 等）齐全，管道/重定向都可直接写。

> 注意：`script` 是通过把脚本内容内联进远端命令执行的（sshpass 不转发 stdin 给远端脚本），
> 因此脚本里不要依赖标准输入；需要读取远端已有数据时，直接在脚本里用命令获取。

## 系统信息字段

`sysinfo` / `probe` 返回的字段（全部来自 `/proc` 与常见命令，**不依赖远端 Python**）：

| 字段 | 说明 |
| --- | --- |
| `hostname` / `os` / `kernel` / `arch` | 主机名、发行版、内核、架构 |
| `cpu_cores` / `cpu_model` / `load` | 核数、型号、1/5/15 分钟负载 |
| `uptime_seconds` | 运行时长（秒） |
| `mem_total_mb` / `mem_available_mb` / `swap_total_mb` | 内存与交换分区（MB） |
| `disk_root` / `disks` | 根分区使用率；`disks` 为「挂载点\|类型\|可用\|使用率」 |
| `ipv4` / `public_ip` | 内网 IP；公网 IP（联网时） |
| `init` / `virt` | init 系统（systemd/openrc）、虚拟化类型 |
| `firewall` | ufw / firewalld / nftables / iptables / none |
| `selinux` | SELinux 状态（有 `getenforce` 时） |
| `docker_version` / `docker_running` / `docker_containers` | Docker 情况 |

## 常见运维配方

```bash
# 看服务状态与最近日志
sh "$SKILL_DIR/ops" -s hk-1 exec 'systemctl status myapp --no-pager -l'
sh "$SKILL_DIR/ops" -s hk-1 exec 'journalctl -u myapp -n 200 --no-pager'

# 磁盘与水位的快速巡检
sh "$SKILL_DIR/ops" -s hk-1 exec 'df -hT; echo ---; du -sh /var/log/* 2>/dev/null | sort -h | tail'

# 端口占用
sh "$SKILL_DIR/ops" -s hk-1 exec 'ss -lntp'

# 防火墙放行一个端口（提权，先确认）
sh "$SKILL_DIR/ops" -s hk-1 --yes sudo 'ufw allow 8080/tcp'

# 打包目录并拉回本地
sh "$SKILL_DIR/ops" -s hk-1 exec 'tar czf /tmp/backup.tgz -C /srv app'
sh "$SKILL_DIR/ops" -s hk-1 get /tmp/backup.tgz ./
```

## 安全边界

- **提权要确认**：`sudo` 默认要求前台确认；非交互环境需显式 `--yes`。生产环境的
  删除、改防火墙、卸载、重启服务等动作，务必先向用户说明影响范围并取得明确同意。
- **命令是特权身份**：SSH 用户即目标机的实际权限（常为 root），不做额外沙箱，别试探边界。
- **凭据保密**：密码只在环境变量里，不要 `echo`/`env` 打印，不要写进命令参数或日志。
- **大输出**：长日志先 `tail`/`grep` 收敛，避免一次拉回几十 MB。
- **幂等优先**：启动、放行、安装类操作先看现状，避免重复执行。

## 常见问题

- 提示 `未找到 ssh 客户端`
  → Windows 需启用「OpenSSH 客户端」（设置 → 应用 → 可选功能）；macOS/Linux 装 `openssh-client`。
- 提示 `不支持的平台` / 缺少 sshpass 二进制
  → 运行 `sh "$SKILL_DIR/ops" servers` 查看当前平台与口令注入状态；确认 `skills/server-ops/bin/` 内容完整。
- `Permission denied (publickey,password)`
  → 用户或密码不对。`servers` 核对这一行的 `用户@主机:端口`。
- 提示 `请用 --server <别名> 指定目标`
  → 配了多台但没指定。先跑 `ops servers` 看别名。
