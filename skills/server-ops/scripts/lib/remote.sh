#!/bin/sh
# remote.sh — 生成在「远端」执行的命令字符串（不涉及本机依赖）
#
# 由于 sshpass 不转发 stdin，所有远端脚本都以 heredoc 形式嵌入命令字符串内。
# 由 ops 引用，不单独执行。
#
# 可配置（默认值见下，可在客户端用同名环境变量覆盖）：
#   OPS_BT_PLUGIN_DIR  宝塔 MCP 插件目录
#   OPS_BT_PANEL_DIR   宝塔面板目录
#   OPS_BT_PY          面板 Python 解释器
#   OPS_BT_DOC         插件安装指引

OPS_BT_PLUGIN_DIR=${OPS_BT_PLUGIN_DIR:-/www/server/panel/plugin/bt_agent_mcp}
OPS_BT_PANEL_DIR=${OPS_BT_PANEL_DIR:-/www/server/panel}
OPS_BT_PY=${OPS_BT_PY:-/www/server/panel/pyenv/bin/python3}
OPS_BT_DOC=${OPS_BT_DOC:-https://docs.bt.cn/ai-ops/mcp/installation}

# 远端系统信息采集：纯 POSIX shell + /proc，输出单行 JSON
ops_remote_sysinfo_cmd() {
  cat <<'OPS_SYSINFO_EOF'
sh <<'OPS_SYSINFO_SH'
_san() { printf '%s' "$1" | tr -d '"\\' | tr '\n' ' '; }

HOSTNAME_V=$(_san "$(hostname 2>/dev/null)")
OS_V=""
if [ -r /etc/os-release ]; then
  OS_V=$(_san "$(. /etc/os-release 2>/dev/null; printf '%s' "$PRETTY_NAME")")
elif [ -r /etc/redhat-release ]; then
  OS_V=$(_san "$(cat /etc/redhat-release 2>/dev/null)")
fi
KERNEL_V=$(_san "$(uname -r 2>/dev/null)")
ARCH_V=$(_san "$(uname -m 2>/dev/null)")
CPU_V=$( (nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null) | head -n1)
case "$CPU_V" in ''|*[!0-9]*) CPU_V=0 ;; esac
CPU_MODEL=$(_san "$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2-)")
LOAD_V=$(_san "$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)")
UPTIME_S=$(_san "$(cut -d' ' -f1 /proc/uptime 2>/dev/null | cut -d. -f1)")
case "$UPTIME_S" in ''|*[!0-9]*) UPTIME_S=0 ;; esac

MEM_TOTAL_MB=0; MEM_AVAIL_MB=0; SWAP_MB=0
if [ -r /proc/meminfo ]; then
  MEM_TOTAL_MB=$(awk '/^MemTotal:/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
  MEM_AVAIL_MB=$(awk '/^MemAvailable:/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
  SWAP_MB=$(awk '/^SwapTotal:/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
fi
case "$MEM_TOTAL_MB" in ''|*[!0-9]*) MEM_TOTAL_MB=0 ;; esac
case "$MEM_AVAIL_MB" in ''|*[!0-9]*) MEM_AVAIL_MB=0 ;; esac
case "$SWAP_MB" in ''|*[!0-9]*) SWAP_MB=0 ;; esac

DISK_ROOT=$(_san "$(df -h / 2>/dev/null | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')")
DISK_LIST=$(_san "$(df -hT -x tmpfs -x devtmpfs -x overlay 2>/dev/null | awk 'NR>1{printf "%s|%s|%s|%s\n", $NF, $2, $4, $6}' | head -n 20)")
IPV4=$(_san "$(hostname -I 2>/dev/null | awk '{print $1}')")
PUBLIC_IP=$(_san "$(curl -fsS --max-time 4 https://ipinfo.io/ip 2>/dev/null || curl -fsS --max-time 4 https://api.ipify.org 2>/dev/null)")

INIT_V=""
if [ -d /run/systemd/system ]; then INIT_V="systemd"
elif command -v openrc >/dev/null 2>&1; then INIT_V="openrc"
else INIT_V=$(_san "$(cat /proc/1/comm 2>/dev/null)"); fi

DOCKER_V=$(_san "$(docker --version 2>/dev/null)")
DOCKER_RUNNING=0; DOCKER_CONTAINERS=0
if command -v docker >/dev/null 2>&1; then
  docker info >/dev/null 2>&1 && DOCKER_RUNNING=1
  DOCKER_CONTAINERS=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
fi
case "$DOCKER_CONTAINERS" in ''|*[!0-9]*) DOCKER_CONTAINERS=0 ;; esac

KVM_V=$( (systemd-detect-virt 2>/dev/null || echo unknown) | head -n1)
KVM_V=$(_san "$KVM_V")
TIMEZONE=$(_san "$(cat /etc/timezone 2>/dev/null || date +%Z 2>/dev/null)")

FIREWALL_V="none"
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then FIREWALL_V="ufw"
elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state 2>/dev/null | grep -q running; then FIREWALL_V="firewalld"
elif command -v nft >/dev/null 2>&1 && nft list ruleset 2>/dev/null | grep -q .; then FIREWALL_V="nftables"
elif command -v iptables >/dev/null 2>&1 && iptables -S 2>/dev/null | grep -qv '^-P .* ACCEPT$'; then FIREWALL_V="iptables"
fi

SELINUX_V=""
command -v getenforce >/dev/null 2>&1 && SELINUX_V=$(_san "$(getenforce 2>/dev/null)")

printf '{\n'
printf '  "hostname": "%s",\n' "$HOSTNAME_V"
printf '  "os": "%s",\n' "$OS_V"
printf '  "kernel": "%s",\n' "$KERNEL_V"
printf '  "arch": "%s",\n' "$ARCH_V"
printf '  "cpu_cores": %s,\n' "$CPU_V"
printf '  "cpu_model": "%s",\n' "$CPU_MODEL"
printf '  "load": "%s",\n' "$LOAD_V"
printf '  "uptime_seconds": %s,\n' "$UPTIME_S"
printf '  "mem_total_mb": %s,\n' "$MEM_TOTAL_MB"
printf '  "mem_available_mb": %s,\n' "$MEM_AVAIL_MB"
printf '  "swap_total_mb": %s,\n' "$SWAP_MB"
printf '  "disk_root": "%s",\n' "$DISK_ROOT"
printf '  "disks": "%s",\n' "$DISK_LIST"
printf '  "ipv4": "%s",\n' "$IPV4"
printf '  "public_ip": "%s",\n' "$PUBLIC_IP"
printf '  "init": "%s",\n' "$INIT_V"
printf '  "virt": "%s",\n' "$KVM_V"
printf '  "timezone": "%s",\n' "$TIMEZONE"
printf '  "firewall": "%s",\n' "$FIREWALL_V"
printf '  "selinux": "%s",\n' "$SELINUX_V"
printf '  "docker_version": "%s",\n' "$DOCKER_V"
printf '  "docker_running": %s,\n' "$DOCKER_RUNNING"
printf '  "docker_containers": %s\n' "$DOCKER_CONTAINERS"
printf '}\n'
OPS_SYSINFO_SH
OPS_SYSINFO_EOF
}

# 远端能力探测：只读判断是否宝塔、插件与面板 Python 是否就绪
# 输出 key=value 若干行
ops_remote_probe_cmd() {
  cat <<OPS_PROBE_EOF
sh <<'OPS_PROBE_SH'
echo "bt_cli=0"
command -v bt >/dev/null 2>&1 && echo "bt_cli=1"
echo "panel_dir=0"
[ -d '$OPS_BT_PANEL_DIR' ] && echo "panel_dir=1"
echo "plugin_dir=0"
[ -d '$OPS_BT_PLUGIN_DIR' ] && echo "plugin_dir=1"
echo "panel_py=0"
[ -x '$OPS_BT_PY' ] && echo "panel_py=1"
echo "sh=1"
echo "bash=0"
command -v bash >/dev/null 2>&1 && echo "bash=1"
echo "curl=0"
command -v curl >/dev/null 2>&1 && echo "curl=1"
echo "python=0"
command -v python3 >/dev/null 2>&1 && echo "python=1"
echo "docker=0"
command -v docker >/dev/null 2>&1 && echo "docker=1"
echo "systemd=0"
[ -d /run/systemd/system ] && echo "systemd=1"
echo "os="
sed -n 's/^PRETTY_NAME="\\(.*\\)"/\\1/p' /etc/os-release 2>/dev/null | head -n1
OPS_PROBE_SH
OPS_PROBE_EOF
}

# 调用宝塔 MCP 工具。参数：tool_id、args 的 base64
ops_remote_bt_call_cmd() {
  _tool=$1
  _b64=$2
  cat <<OPS_BTCALL_EOF
if [ ! -d '$OPS_BT_PLUGIN_DIR' ]; then
  echo "错误：服务器上未找到宝塔 MCP 插件目录：$OPS_BT_PLUGIN_DIR" >&2
  echo "说明：需要先安装「宝塔 MCP 服务」插件，才能使用宝塔面板工具集。" >&2
  echo "安装指引：$OPS_BT_DOC" >&2
  exit 5
fi
if [ ! -x '$OPS_BT_PY' ]; then
  echo "错误：服务器上未找到面板 Python 解释器：$OPS_BT_PY" >&2
  echo "说明：请确认已安装宝塔面板且 Python 版本符合要求；普通服务器请改用 ops exec。" >&2
  echo "安装指引：$OPS_BT_DOC" >&2
  exit 5
fi
OPS_TOOL_ID='$_tool' OPS_ARGS_B64='$_b64' OPS_PLUGIN='$OPS_BT_PLUGIN_DIR' OPS_PANEL='$OPS_BT_PANEL_DIR' exec '$OPS_BT_PY' <<'OPS_PY_EOF'
import os, sys, json, base64
plugin = os.environ["OPS_PLUGIN"]
panel = os.environ["OPS_PANEL"]
sys.path[0:0] = [plugin, panel + "/class", panel]
import operations
from bt_agent_mcp_tools.registry import ToolRegistry, register_all
from bt_agent_mcp_tools.request_context import set_request_context, reset_request_context
reg = ToolRegistry(); register_all(reg)
tokens = set_request_context(key_id="local", auth_type="btai")
try:
    args = json.loads(base64.b64decode(os.environ["OPS_ARGS_B64"]).decode("utf-8"))
    print(json.dumps(reg.call(os.environ["OPS_TOOL_ID"], args), ensure_ascii=False))
finally:
    reset_request_context(tokens)
OPS_PY_EOF
OPS_BTCALL_EOF
}

# 列出宝塔 MCP 已注册工具（JSONL，每行一个：id/cn/cat/risk/basic）
ops_remote_bt_list_cmd() {
  cat <<OPS_BTLIST_EOF
if [ ! -d '$OPS_BT_PLUGIN_DIR' ]; then
  echo "错误：服务器上未找到宝塔 MCP 插件目录：$OPS_BT_PLUGIN_DIR" >&2
  echo "安装指引：$OPS_BT_DOC" >&2
  exit 5
fi
if [ ! -x '$OPS_BT_PY' ]; then
  echo "错误：服务器上未找到面板 Python 解释器：$OPS_BT_PY" >&2
  exit 5
fi
OPS_PLUGIN='$OPS_BT_PLUGIN_DIR' OPS_PANEL='$OPS_BT_PANEL_DIR' exec '$OPS_BT_PY' <<'OPS_PYLIST_EOF'
import os, sys, json
plugin = os.environ["OPS_PLUGIN"]
panel = os.environ["OPS_PANEL"]
sys.path[0:0] = [plugin, panel + "/class", panel]
import operations
from bt_agent_mcp_tools.registry import ToolRegistry, register_all, tool_meta_list
reg = ToolRegistry(); register_all(reg)
for t in tool_meta_list(reg):
    print(json.dumps({"id": t["tool_id"], "cn": t["name"], "cat": t["category"],
                      "risk": t["risk_level"], "basic": t["basic_tool"]}, ensure_ascii=False))
OPS_PYLIST_EOF
OPS_BTLIST_EOF
}
