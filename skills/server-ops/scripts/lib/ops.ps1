# ops.ps1 — Windows 实现（与 POSIX 版 ops 行为对齐）
# 由 ops.cmd 调用，也可直接：powershell -NoProfile -File ops.ps1 ...
#
# 用法：
#   ops.ps1 servers
#   ops.ps1 [-s 别名] exec '<命令>'
#   ops.ps1 [-s 别名] [--yes] sudo '<命令>'
#   ops.ps1 [-s 别名] script <本地脚本>
#   ops.ps1 [-s 别名] put <本地> <远端路径>
#   ops.ps1 [-s 别名] get <远端路径> <本地目录>
#   ops.ps1 [-s 别名] sysinfo|probe|detect [--json]|bt <ToolId> [json]|bt-tools [关键字]

[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

$LibDir  = Split-Path -Parent $PSCommandPath
$BinDir  = Join-Path (Split-Path -Parent $LibDir) 'bin'
$ConnectTimeout = if ($env:OPS_CONNECT_TIMEOUT) { $env:OPS_CONNECT_TIMEOUT } else { 15 }

$BtPlugin = if ($env:OPS_BT_PLUGIN_DIR) { $env:OPS_BT_PLUGIN_DIR } else { '/www/server/panel/plugin/bt_agent_mcp' }
$BtPanel  = if ($env:OPS_BT_PANEL_DIR)  { $env:OPS_BT_PANEL_DIR }  else { '/www/server/panel' }
$BtPy     = if ($env:OPS_BT_PY)         { $env:OPS_BT_PY }         else { '/www/server/panel/pyenv/bin/python3' }
$BtDoc    = if ($env:OPS_BT_DOC)        { $env:OPS_BT_DOC }        else { 'https://docs.bt.cn/ai-ops/mcp/installation' }

function Fail([string]$msg, [int]$code = 3) {
  [Console]::Error.WriteLine($msg)
  exit $code
}

function Get-SshpassBin {
  $arch = $env:PROCESSOR_ARCHITECTURE
  if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
  $name = if ($arch -eq 'ARM64') { 'sshpass-windows-arm64.exe' } else { 'sshpass-windows-amd64.exe' }
  $p = Join-Path $BinDir $name
  if (-not (Test-Path $p)) { Fail "错误：找不到当前平台的 sshpass 二进制：$p`n请确认 skills/server-ops/bin/ 内容完整。" 4 }
  return $p
}

function Get-RawServers {
  foreach ($v in @('BT_PANELS', 'OPS_SERVERS', 'SERVERS')) {
    $val = [Environment]::GetEnvironmentVariable($v)
    if ($val) { return $val }
  }
  return $null
}

function Parse-Servers {
  $raw = Get-RawServers
  if (-not $raw) { return @() }
  $raw = $raw -replace '\\n', "`n"
  if ($raw.IndexOf("`n") -lt 0) { $raw = $raw -replace ';', "`n" }
  $out = @()
  $n = 0
  foreach ($line in ($raw -split "`r?`n")) {
    $n++
    $l = $line
    $hi = $l.IndexOf(' #')
    if ($hi -ge 0) { $l = $l.Substring(0, $hi) }
    $l = $l.Trim()
    if (-not $l -or $l.StartsWith('#')) { continue }

    if ($l.Contains('|')) {
      $f = @($l -split '\|' | ForEach-Object { $_.Trim() })
    } else {
      $f = @($l -split '\s+' | Where-Object { $_ -ne '' })
    }

    $alias = $f[0]
    if ($f.Count -ge 2) { $host_ = $f[1] } else { $host_ = $alias }
    if ($f.Count -ge 3) { $port = $f[2] }  else { $port = '' }
    if ($f.Count -ge 4) { $user = $f[3] }  else { $user = '' }
    $pass = ''
    if ($f.Count -ge 5) { $pass = (($f[4..($f.Count - 1)] | ForEach-Object { $_ }) -join '|').Trim() }

    $host_ = ([string]$host_).Trim()
    if (-not $host_) { Fail "错误：服务器清单第 $n 行缺少主机。格式：别名 | 主机 | 端口 | 用户 | 密码" 3 }
    if (-not $alias) { $alias = $host_ }
    if (-not $port)  { $port = '22' }
    if (-not $user)  { $user = 'root' }
    if ($pass -eq '-') { $pass = '' }
    if ($port -notmatch '^\d+$' -or [int]$port -lt 1 -or [int]$port -gt 65535) {
      Fail "错误：服务器清单第 $n 行「$alias」的端口不是合法端口（读到 `"$port`"）。格式：别名 | 主机 | 端口 | 用户 | 密码；端口留空即 22。" 3
    }
    $out += [pscustomobject]@{ name = $alias; host = $host_; port = $port; user = $user; pass = $pass }
  }
  return $out
}

function Resolve-Server([string]$want) {
  $list = @(Parse-Servers)
  if ($list.Count -eq 0) {
    Fail "错误：没有可用的服务器。请到桌面端该软件的设置页，在「服务器清单」里填写：`n      每行一台 → 别名 | 主机 | 端口 | 用户 | 密码" 3
  }
  if (-not $want) { $want = $env:BT_PANEL_DEFAULT }
  if (-not $want) {
    if ($list.Count -eq 1) { return $list[0] }
    $names = ($list | ForEach-Object { '  ' + $_.name + ' (' + $_.user + '@' + $_.host + ':' + $_.port + ')' }) -join "`n"
    Fail "错误：配置了 $($list.Count) 台服务器，请用 -s <别名> 指定目标。`n可用服务器：`n$names" 3
  }
  $hit = @($list | Where-Object { $_.name -eq $want })
  if ($hit.Count -eq 0) { $hit = @($list | Where-Object { $_.name.ToLower() -eq $want.ToLower() }) }
  if ($hit.Count -eq 0 -and $want -match '^\d+$') {
    $k = [int]$want
    if ($k -ge 1 -and $k -le $list.Count) { return $list[$k - 1] }
  }
  if ($hit.Count -eq 0) {
    $hit = @($list | Where-Object { $_.name.ToLower().StartsWith($want.ToLower()) })
  }
  if ($hit.Count -eq 1) { return $hit[0] }
  $names = ($list | ForEach-Object { '  ' + $_.name }) -join "`n"
  if ($hit.Count -gt 1) { Fail "错误：-s $want 匹配到多台服务器，请写全别名：`n$names" 3 }
  Fail "错误：找不到服务器「$want」。可用服务器：`n$names" 3
}

# 去掉 sshpass 注入到 stdout 的口令提示行
function Clean-Output([string]$text) {
  if (-not $text) { return '' }
  $lines = $text -split "`r?`n"
  $kept = $lines | Where-Object { $_ -notmatch "^[^ ]+@[^ ]+'s password:\s*$" }
  return ($kept -join "`n")
}

function Invoke-Remote {
  param($Srv, [string]$RemoteCmd)
  $sbin = Get-SshpassBin
  $opts = @(
    '-p', $Srv.port,
    '-o', 'StrictHostKeyChecking=accept-new',
    '-o', "ConnectTimeout=$ConnectTimeout",
    '-o', 'LogLevel=ERROR',
    '-o', 'ServerAliveInterval=15',
    '-o', 'ServerAliveCountMax=8'
  )
  $target = "$($Srv.user)@$($Srv.host)"
  if ($Srv.pass) {
    $opts += @('-o', 'PubkeyAuthentication=no',
               '-o', 'PreferredAuthentications=password,keyboard-interactive',
               '-o', 'NumberOfPasswordPrompts=1')
    $env:SSHPASS = $Srv.pass
    try {
      $text = (& $sbin '-e' '--' 'ssh' @opts $target $RemoteCmd | Out-String)
    } finally {
      Remove-Item Env:SSHPASS -ErrorAction SilentlyContinue
    }
  } else {
    $text = (& ssh @opts $target $RemoteCmd | Out-String)
  }
  $code = $LASTEXITCODE
  [Console]::Out.Write((Clean-Output $text))
  return $code
}

function Invoke-RemoteSudo {
  param($Srv, [string]$RemoteCmd)
  $quoted = "'" + ($RemoteCmd -replace "'", "'\''") + "'"
  return Invoke-Remote -Srv $Srv -RemoteCmd "sudo -n sh -c $quoted"
}

function Copy-RemoteFile {
  param($Srv, [string]$Local, [string]$Remote, [switch]$Get)
  $sbin = Get-SshpassBin
  $opts = @('-P', $Srv.port,
            '-o', 'StrictHostKeyChecking=accept-new',
            '-o', "ConnectTimeout=$ConnectTimeout",
            '-o', 'LogLevel=ERROR')
  $target = "$($Srv.user)@$($Srv.host)"
  if ($Srv.pass) {
    $env:SSHPASS = $Srv.pass
    try {
      if ($Get) { & $sbin '-e' '--' 'scp' @opts "${target}:$Remote" $Local }
      else      { & $sbin '-e' '--' 'scp' @opts $Local "${target}:$Remote" }
    } finally {
      Remove-Item Env:SSHPASS -ErrorAction SilentlyContinue
    }
  } else {
    if ($Get) { & scp @opts "${target}:$Remote" $Local }
    else      { & scp @opts $Local "${target}:$Remote" }
  }
  return $LASTEXITCODE
}

# ---------- 远端负载 ----------

function Get-SysinfoCmd {
  return @'
sh <<'OPS_SYSINFO_SH'
_san() { printf '%s' "$1" | tr -d '"\\' | tr '\n' ' '; }
HOSTNAME_V=$(_san "$(hostname 2>/dev/null)")
OS_V=""
if [ -r /etc/os-release ]; then OS_V=$(_san "$(. /etc/os-release 2>/dev/null; printf '%s' "$PRETTY_NAME")"); fi
KERNEL_V=$(_san "$(uname -r 2>/dev/null)")
ARCH_V=$(_san "$(uname -m 2>/dev/null)")
CPU_V=$( (nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null) | head -n1)
case "$CPU_V" in ''|*[!0-9]*) CPU_V=0 ;; esac
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
KVM_V=$(_san "$( (systemd-detect-virt 2>/dev/null || echo unknown) | head -n1)")
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
'@
}

function Get-ProbeCmd {
  return @"
sh <<'OPS_PROBE_SH'
echo "bt_cli=0"; command -v bt >/dev/null 2>&1 && echo "bt_cli=1"
echo "panel_dir=0"; [ -d '$BtPanel' ] && echo "panel_dir=1"
echo "plugin_dir=0"; [ -d '$BtPlugin' ] && echo "plugin_dir=1"
echo "panel_py=0"; [ -x '$BtPy' ] && echo "panel_py=1"
echo "sh=1"
echo "bash=0"; command -v bash >/dev/null 2>&1 && echo "bash=1"
echo "curl=0"; command -v curl >/dev/null 2>&1 && echo "curl=1"
echo "python=0"; command -v python3 >/dev/null 2>&1 && echo "python=1"
echo "docker=0"; command -v docker >/dev/null 2>&1 && echo "docker=1"
echo "systemd=0"; [ -d /run/systemd/system ] && echo "systemd=1"
echo "os="
sed -n 's/^PRETTY_NAME="\(.*\)"/\1/p' /etc/os-release 2>/dev/null | head -n1
OPS_PROBE_SH
"@
}

# 远端 Python 引导：经 heredoc 送入远端解释器（sshpass 不转发本地 stdin，故此处在远端自建管道）
function Get-BtCallCmd([string]$ToolId, [string]$ArgsB64) {
  $py = @'
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
'@
  return @"
if [ ! -d '$BtPlugin' ]; then
  echo "错误：服务器上未找到宝塔 MCP 插件目录：$BtPlugin" >&2
  echo "说明：需要先安装「宝塔 MCP 服务」插件，才能使用宝塔面板工具集。" >&2
  echo "安装指引：$BtDoc" >&2
  exit 5
fi
if [ ! -x '$BtPy' ]; then
  echo "错误：服务器上未找到面板 Python 解释器：$BtPy" >&2
  echo "安装指引：$BtDoc" >&2
  exit 5
fi
OPS_TOOL_ID='$ToolId' OPS_ARGS_B64='$ArgsB64' OPS_PLUGIN='$BtPlugin' OPS_PANEL='$BtPanel' exec '$BtPy' <<'OPS_PY_EOF'
$py
OPS_PY_EOF
"@
}

function Get-BtListCmd {
  $py = @'
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
'@
  return @"
if [ ! -d '$BtPlugin' ]; then
  echo "错误：服务器上未找到宝塔 MCP 插件目录：$BtPlugin" >&2
  echo "安装指引：$BtDoc" >&2
  exit 5
fi
if [ ! -x '$BtPy' ]; then
  echo "错误：服务器上未找到面板 Python 解释器：$BtPy" >&2
  exit 5
fi
OPS_PLUGIN='$BtPlugin' OPS_PANEL='$BtPanel' exec '$BtPy' <<'OPS_PYLIST_EOF'
$py
OPS_PYLIST_EOF
"@
}

# ---------- 参数解析 ----------

if ($null -eq $Rest) { $Rest = @() }

$server = ''
$yes = $false
$i = 0
$keepParsing = $true
while ($i -lt $Rest.Count -and $keepParsing) {
  $a = [string]$Rest[$i]
  if ($a -eq '-s' -or $a -eq '--server') {
    if ($i + 1 -ge $Rest.Count) { Fail '错误：-s/--server 后面需要跟别名。' 2 }
    $server = [string]$Rest[$i + 1]; $i += 2
  } elseif ($a -eq '--yes' -or $a -eq '-y') {
    $yes = $true; $i += 1
  } elseif ($a -eq '--') {
    $i += 1; $keepParsing = $false
  } elseif ($a.StartsWith('-')) {
    Fail "错误：未知选项 $a（可用：-s/--server、--yes/-y、--）" 2
  } else {
    $keepParsing = $false
  }
}

$argv = @()
for ($k = $i; $k -lt $Rest.Count; $k++) { $argv += [string]$Rest[$k] }

if ($argv.Count -eq 0) {
  Fail '用法：ops.cmd [-s 别名] <子命令> [参数...]  子命令：servers|exec|sudo|script|put|get|sysinfo|probe|detect|bt|bt-tools' 2
}
$action = $argv[0]
$aparams = @()
if ($argv.Count -gt 1) { $aparams = $argv[1..($argv.Count - 1)] }

if ($action -eq 'servers') {
  Write-Output '== 已配置的服务器 =='
  $list = @(Parse-Servers)
  if ($list.Count -eq 0) {
    Write-Output '（未配置服务器清单：请在桌面端该软件的设置页填写「服务器清单」）'
  } else {
    foreach ($s in $list) {
      $auth = if ($s.pass) { '密码认证' } else { '私钥认证' }
      Write-Output ("{0}`t{1}@{2}:{3}`t{4}" -f $s.name, $s.user, $s.host, $s.port, $auth)
    }
  }
  Write-Output ''
  Write-Output '== SSH 客户端 =='
  $sshCmd = Get-Command ssh -ErrorAction SilentlyContinue
  if ($sshCmd) { Write-Output $sshCmd.Source }
  else { Write-Output '未找到 ssh 客户端：请在 Windows 可选功能里启用「OpenSSH 客户端」。' }
  Write-Output ''
  Write-Output '== 口令注入 =='
  $bin = $null
  try { $bin = Get-SshpassBin } catch { $bin = $null }
  if ($bin) { Write-Output ("sshpass（{0}）" -f $bin) }
  else { Write-Output '不可用：缺少当前平台的 sshpass 二进制' }
  exit 0
}

$srv = Resolve-Server $server
$authText = if ($srv.pass) { '密码认证' } else { '私钥认证' }
[Console]::Error.WriteLine("# 目标：{0} {1}@{2}:{3} {4}" -f $srv.name, $srv.user, $srv.host, $srv.port, $authText)

switch ($action) {
  'exec' {
    if ($aparams.Count -lt 1) { Fail '错误：exec 需要一条命令。' 2 }
    exit (Invoke-Remote -Srv $srv -RemoteCmd $aparams[0])
  }
  'sudo' {
    if ($aparams.Count -lt 1) { Fail '错误：sudo 需要一条命令。' 2 }
    if (-not $yes) {
      Fail "错误：该操作需要在终端确认。请加 --yes 明确确认后在授权范围内执行。" 1
    }
    exit (Invoke-RemoteSudo -Srv $srv -RemoteCmd $aparams[0])
  }
  'script' {
    if ($aparams.Count -lt 1) { Fail '错误：script 需要一个本地脚本路径。' 2 }
    $p = $aparams[0]
    if (-not (Test-Path -LiteralPath $p)) { Fail "错误：找不到本地脚本 $p" 2 }
    $body = Get-Content -Raw -LiteralPath $p
    $tag = '__OPS_SCRIPT_EOF__'
    $cmd = "sh <<'$tag'`n$body`n$tag"
    exit (Invoke-Remote -Srv $srv -RemoteCmd $cmd)
  }
  'put' {
    if ($aparams.Count -lt 2) { Fail '错误：put 需要 <本地文件> <远端路径>。' 2 }
    if (-not (Test-Path -LiteralPath $aparams[0])) { Fail "错误：找不到本地文件 $($aparams[0])" 2 }
    $rc = Copy-RemoteFile -Srv $srv -Local $aparams[0] -Remote $aparams[1]
    if ($rc -eq 0) { Write-Output ("已上传：{0} → {1}:{2}" -f $aparams[0], $srv.host, $aparams[1]) }
    exit $rc
  }
  'get' {
    if ($aparams.Count -lt 2) { Fail '错误：get 需要 <远端路径> <本地目录>。' 2 }
    if (-not (Test-Path -LiteralPath $aparams[1])) {
      New-Item -ItemType Directory -Force -Path $aparams[1] | Out-Null
    }
    $rc = Copy-RemoteFile -Srv $srv -Remote $aparams[0] -Local ($aparams[1].TrimEnd('\') + '\') -Get
    if ($rc -eq 0) { Write-Output ("已下载：{0}:{1} → {2}" -f $srv.host, $aparams[0], $aparams[1]) }
    exit $rc
  }
  'sysinfo' { exit (Invoke-Remote -Srv $srv -RemoteCmd (Get-SysinfoCmd)) }
  'probe' {
    $cmd = (Get-SysinfoCmd) + "`necho '__OPS_PROBE__'`n" + (Get-ProbeCmd)
    exit (Invoke-Remote -Srv $srv -RemoteCmd $cmd)
  }
  'detect' {
    $cmd = (Get-SysinfoCmd) + "`necho '__OPS_PROBE__'`n" + (Get-ProbeCmd)
    $sbin = Get-SshpassBin
    $opts = @('-p', $srv.port, '-o', 'StrictHostKeyChecking=accept-new',
              '-o', "ConnectTimeout=$ConnectTimeout", '-o', 'LogLevel=ERROR')
    $target = "$($srv.user)@$($srv.host)"
    if ($srv.pass) {
      $opts += @('-o', 'PubkeyAuthentication=no',
                 '-o', 'PreferredAuthentications=password,keyboard-interactive',
                 '-o', 'NumberOfPasswordPrompts=1')
      $env:SSHPASS = $srv.pass
      try { $raw = (& $sbin '-e' '--' 'ssh' @opts $target $cmd | Out-String) }
      finally { Remove-Item Env:SSHPASS -ErrorAction SilentlyContinue }
    } else {
      $raw = (& ssh @opts $target $cmd | Out-String)
    }
    $probe = Clean-Output $raw

    function ProbeVal([string]$key) {
      $v = ''
      foreach ($ln in ($probe -split "`r?`n")) {
        if ($ln -match ("^" + [regex]::Escape($key) + "=(.*)$")) { $v = $Matches[1] }
      }
      return $v
    }
    $sysText = ($probe -split "__OPS_PROBE__")[0].TrimEnd()
    $btCli = ProbeVal 'bt_cli'; $panelD = ProbeVal 'panel_dir'
    $pluginD = ProbeVal 'plugin_dir'; $panelPy = ProbeVal 'panel_py'
    $isBt = ($btCli -eq '1' -or $panelD -eq '1')
    $ready = ($pluginD -eq '1' -and $panelPy -eq '1')
    if ($isBt -and $ready) { $mode = 'baota'; $adv = '用 ops bt 调用宝塔面板工具集（98 个运维工具）' }
    elseif ($isBt) { $mode = 'baota-no-mcp'; $adv = '检测到宝塔面板但缺少 bt_agent_mcp 插件：可提示安装，当前用 ops exec 通用命令' }
    else { $mode = 'generic'; $adv = '用 ops exec/script 通用命令方式运维' }

    if ($aparams.Count -ge 1 -and $aparams[0] -eq '--json') {
      $sysJson = ($sysText -replace '\s+', ' ')
      Write-Output '{'
      Write-Output ("  `"server`": {`"host`": `"$($srv.host)`", `"port`": `"$($srv.port)`", `"user`": `"$($srv.user)`"},")
      Write-Output ("  `"system`": $sysJson,")
      Write-Output ("  `"baota`": {`"bt_cli`": $($btCli -eq '1'), `"panel_dir`": $($panelD -eq '1'), `"plugin_dir`": $($pluginD -eq '1'), `"panel_py`": $($panelPy -eq '1'), `"baota`": $isBt, `"mcp_ready`": $ready},")
      Write-Output ("  `"mode`": `"$mode`",")
      Write-Output ("  `"advice`": `"$adv`"")
      Write-Output '}'
      exit 0
    }
    Write-Output ("== 目标 {0}@{1}:{2} ==" -f $srv.user, $srv.host, $srv.port)
    switch ($mode) {
      'baota'        { Write-Output '  类型：宝塔面板服务器（bt_agent_mcp 已就绪）' }
      'baota-no-mcp' { Write-Output '  类型：宝塔面板服务器（未检测到 bt_agent_mcp 插件）' }
      default        { Write-Output '  类型：普通 Linux 服务器' }
    }
    $osV = ''; $archV = ''; $cpuV = ''; $memV = ''; $loadV = ''
    if ($sysText -match '"os":\s*"([^"]*)"') { $osV = $Matches[1] }
    if ($sysText -match '"arch":\s*"([^"]*)"') { $archV = $Matches[1] }
    if ($sysText -match '"cpu_cores":\s*(\d+)') { $cpuV = $Matches[1] }
    if ($sysText -match '"mem_total_mb":\s*(\d+)') { $memV = $Matches[1] }
    if ($sysText -match '"load":\s*"([^"]*)"') { $loadV = $Matches[1] }
    Write-Output ("  系统：{0} {1}｜{2}C/{3}MB｜负载 {4}" -f $osV, $archV, $cpuV, $memV, $loadV)
    Write-Output ("  建议：{0}" -f $adv)
    exit 0
  }
  'bt' {
    if ($aparams.Count -lt 1) { Fail '错误：bt 需要 <ToolId> [JSON 参数]。' 2 }
    $json = '{}'
    if ($aparams.Count -ge 2 -and $aparams[1]) { $json = $aparams[1] }
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
    exit (Invoke-Remote -Srv $srv -RemoteCmd (Get-BtCallCmd $aparams[0] $b64))
  }
  'bt-tools' {
    $rc = Invoke-Remote -Srv $srv -RemoteCmd (Get-BtListCmd)
    exit $rc
  }
  default { Fail "错误：未知子命令 $action" 2 }
}
