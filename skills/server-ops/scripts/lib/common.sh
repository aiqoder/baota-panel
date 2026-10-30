#!/bin/sh
# common.sh — 服务器清单解析 / 目标选择 / sshpass 调用封装
#
# 纯 POSIX sh，无 Python 依赖。由 ops 引用，不单独执行。
#
# 服务器清单来自环境变量（依次尝试 BT_PANELS、OPS_SERVERS、SERVERS）：
# 每行一台，字段用 | 分隔：
#
#     别名 | 主机 | 端口 | 用户 | 密码
#
# 省略规则：端口=22、用户=root、密码留空或写 - → 本机 SSH 私钥认证。
# 空行与 # 行忽略；行内「 # 备注」会被截掉；整段写成一行时用 ; 分隔。

OPS_CONNECT_TIMEOUT=${OPS_CONNECT_TIMEOUT:-15}
OPS_SSH_CMD=${OPS_SSH_CMD:-ssh}
OPS_SCP_CMD=${OPS_SCP_CMD:-scp}

ops_die() {
  printf '%s\n' "$1" >&2
  exit "${2:-3}"
}

# 读取环境变量（变量名为内部常量，无注入风险）
ops_env() {
  eval "printf '%s' \"\${$1:-}\""
}

# 当前平台对应的 sshpass 可执行文件路径；不支持时返回 1
ops_platform_bin() {
  _bin_dir=$1
  _os=$(uname -s 2>/dev/null || echo unknown)
  _arch=$(uname -m 2>/dev/null || echo unknown)
  case "$_os:$_arch" in
    Darwin:arm64) _f=sshpass-darwin-arm64 ;;
    Darwin:x86_64) _f=sshpass-darwin-amd64 ;;
    Linux:x86_64|Linux:amd64) _f=sshpass-linux-amd64 ;;
    Linux:aarch64|Linux:arm64) _f=sshpass-linux-arm64 ;;
    *) return 1 ;;
  esac
  _p="$_bin_dir/$_f"
  [ -f "$_p" ] || return 1
  [ -x "$_p" ] || chmod +x "$_p" 2>/dev/null || true
  [ -x "$_p" ] || return 1
  printf '%s' "$_p"
}

ops_require_sshpass() {
  _b=$(ops_platform_bin "$OPS_BIN_DIR") || ops_die "错误：找不到当前平台（$(uname -s)/$(uname -m)）对应的 sshpass 二进制，请确认 skills/server-ops/bin/ 内容完整。" 4
  printf '%s' "$_b"
}

# 读取原始清单文本
ops_raw_servers() {
  for _v in BT_PANELS OPS_SERVERS SERVERS; do
    _val=$(ops_env "$_v")
    if [ -n "$_val" ]; then
      printf '%s' "$_val"
      return 0
    fi
  done
  return 1
}

# 解析清单，输出 TSV：name \t host \t port \t user \t pass
# 需修正的格式问题写 stderr 并以 3 退出。
ops_parse_servers() {
  _raw=$(ops_raw_servers) || return 1
  printf '%s' "$_raw" | awk '
    { gsub(/\\n/, "\n"); if (index($0, "\n") == 0) gsub(/;/, "\n"); printf "%s\n", $0 }
  ' | awk '
    function trim(s) { gsub(/^[ \t\r]+/, "", s); gsub(/[ \t\r]+$/, "", s); return s }
    BEGIN { bad = 0 }
    {
      line = $0
      i = index(line, " #")
      if (i > 0) line = substr(line, 1, i - 1)
      line = trim(line)
      if (line == "" || substr(line, 1, 1) == "#") next

      if (index(line, "|") > 0) {
        n = split(line, f, "|")
        for (k = 1; k <= n; k++) f[k] = trim(f[k])
      } else {
        n = split(line, f, /[ \t]+/)
      }

      name = f[1]
      if (n == 1)      { host = name;   port = "";    user = "";     pass = "" }
      else if (n == 2) { host = f[2];   port = "";    user = "";     pass = "" }
      else if (n == 3) { host = f[2];   port = f[3];  user = "";     pass = "" }
      else if (n == 4) { host = f[2];   port = f[3];  user = f[4];   pass = "" }
      else {
        host = f[2]; port = f[3]; user = f[4]; pass = f[5]
        for (k = 6; k <= n; k++) pass = pass "|" f[k]
      }
      host = trim(host); port = trim(port); user = trim(user); pass = trim(pass)

      if (host == "") {
        printf("错误：服务器清单第 %d 行缺少主机。格式：别名 | 主机 | 端口 | 用户 | 密码\n", NR) > "/dev/stderr"
        bad = 1; next
      }
      if (name == "") name = host
      if (port == "") port = "22"
      if (user == "") user = "root"
      if (pass == "-") pass = ""

      if (port !~ /^[0-9]+$/) {
        printf("错误：服务器清单第 %d 行「%s」的端口不是数字（读到 \"%s\"）。\n", NR, name, port) > "/dev/stderr"
        printf("      格式是：别名 | 主机 | 端口 | 用户 | 密码；端口留空即 22。\n") > "/dev/stderr"
        bad = 1; next
      }
      if (port + 0 < 1 || port + 0 > 65535) {
        printf("错误：服务器清单第 %d 行端口超出范围：%s\n", NR, port) > "/dev/stderr"
        bad = 1; next
      }
      key = tolower(name)
      if (key in seen) {
        printf("错误：服务器清单里别名「%s」重复（第 %d 行）。别名要唯一。\n", name, NR) > "/dev/stderr"
        bad = 1; next
      }
      seen[key] = 1
      printf "%s\t%s\t%s\t%s\t%s\n", name, host, port, user, pass
    }
    END { if (bad) exit 3 }
  '
}

# 解析目标服务器：输出 idx \t name \t host \t port \t user \t pass
# 失败码：3=清单为空/选择失败，4=清单格式错
ops_resolve() {
  _want=$1
  _raw=$(ops_raw_servers) || ops_die "错误：没有可用的服务器。请到桌面端该软件的设置页，在「服务器清单」里填写：
      每行一台 → 别名 | 主机 | 端口 | 用户 | 密码" 3
  _list=$(ops_parse_servers) || ops_die "错误：服务器清单有格式问题（见上面的提示），请修正后重试。" 3
  [ -n "$_list" ] || ops_die "错误：没有可用的服务器。请到桌面端该软件的设置页，在「服务器清单」里填写：
      每行一台 → 别名 | 主机 | 端口 | 用户 | 密码" 3

  if [ -z "$_want" ]; then
    _want=${BT_PANEL_DEFAULT:-}
  fi

  printf '%s\n' "$_list" | awk -F'\t' -v want="$_want" '
    function emit(i) { printf "%d\t%s\t%s\t%s\t%s\t%s\n", i, name[i], host[i], port[i], user[i], pass[i] }
    function listing() {
      for (i = 1; i <= n; i++) printf("  %s\t%s@%s:%s\n", name[i], user[i], host[i], port[i]) > "/dev/stderr"
    }
    { n++; name[n] = $1; host[n] = $2; port[n] = $3; user[n] = $4; pass[n] = $5 }
    END {
      if (want == "") {
        if (n == 1) { emit(1); exit 0 }
        printf("错误：配置了 %d 台服务器，请用 --server <别名> 指定目标。\n", n) > "/dev/stderr"
        printf("可用服务器：\n") > "/dev/stderr"
        listing(); exit 3
      }
      lw = tolower(want)
      for (i = 1; i <= n; i++) if (tolower(name[i]) == lw) { emit(i); exit 0 }
      if (want ~ /^[0-9]+$/) {
        k = want + 0
        if (k >= 1 && k <= n) { emit(k); exit 0 }
      }
      hits = 0; hi = 0
      for (i = 1; i <= n; i++) if (index(tolower(name[i]), lw) == 1) { hits++; hi = i }
      if (hits == 1) { emit(hi); exit 0 }
      if (hits > 1) {
        printf("错误：--server %s 匹配到多台服务器，请写全别名：\n", want) > "/dev/stderr"
        for (i = 1; i <= n; i++) if (index(tolower(name[i]), lw) == 1) printf("  %s\n", name[i]) > "/dev/stderr"
        exit 3
      }
      printf("错误：找不到服务器「%s」。可用服务器：\n", want) > "/dev/stderr"
      listing(); exit 3
    }
  '
}

# 打印清单（不联网、不暴露密码）
ops_list_servers() {
  ops_raw_servers >/dev/null 2>&1 || {
    printf '%s\n' "（未配置服务器清单：请在桌面端该软件的设置页填写「服务器清单」）"
    return 0
  }
  _list=$(ops_parse_servers) || ops_die "错误：服务器清单有格式问题（见上面的提示），请修正后重试。" 3
  [ -n "$_list" ] || { printf '%s\n' "（未配置服务器清单：请在桌面端该软件的设置页填写「服务器清单」）"; return 0; }
  printf '%s\n' "$_list" | awk -F'\t' '
    { auth = ($5 == "") ? "私钥认证" : "密码认证"; printf "%s\t%s@%s:%s\t%s\n", $1, $4, $2, $3, auth }
  '
}

# POSIX 单引号转义（把参数包成可安全传给远端 sh -c 的字符串）
ops_shq() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

ops_ssh_opts() {
  _port=$1; _pw=$2
  printf '%s' "-p $_port -o StrictHostKeyChecking=accept-new -o ConnectTimeout=$OPS_CONNECT_TIMEOUT -o LogLevel=ERROR -o ServerAliveInterval=15 -o ServerAliveCountMax=8"
  if [ "$_pw" = "1" ]; then
    printf '%s' " -o PubkeyAuthentication=no -o PreferredAuthentications=password,keyboard-interactive -o NumberOfPasswordPrompts=1"
  fi
}

ops_scp_opts() {
  _port=$1; _pw=$2
  printf '%s' "-P $_port -o StrictHostKeyChecking=accept-new -o ConnectTimeout=$OPS_CONNECT_TIMEOUT -o LogLevel=ERROR"
}

# 远端执行一条命令（命令作为单个 argv 交给远端登录 shell）
# 用法：ops_ssh_do host port user pass 'remote command'
ops_ssh_do() {
  _host=$1; _port=$2; _user=$3; _pass=$4; _cmd=$5
  _tmp=$(mktemp 2>/dev/null) || ops_die "错误：无法创建临时文件。" 1
  if [ -n "$_pass" ]; then
    SSHPASS=$_pass "$OPS_SSHPASS_BIN" -e -- "$OPS_SSH_CMD" $(ops_ssh_opts "$_port" 1) "$_user@$_host" "$_cmd" > "$_tmp"
  else
    "$OPS_SSH_CMD" $(ops_ssh_opts "$_port" 0) "$_user@$_host" "$_cmd" > "$_tmp"
  fi
  _rc=$?
  ops_clean_stream < "$_tmp"
  rm -f "$_tmp"
  return $_rc
}

ops_scp_put() {
  _host=$1; _port=$2; _user=$3; _pass=$4; _local=$5; _remote=$6
  _tmp=$(mktemp 2>/dev/null) || ops_die "错误：无法创建临时文件。" 1
  if [ -n "$_pass" ]; then
    SSHPASS=$_pass "$OPS_SSHPASS_BIN" -e -- "$OPS_SCP_CMD" $(ops_scp_opts "$_port" 1) "$_local" "$_user@$_host:$_remote" > "$_tmp"
  else
    "$OPS_SCP_CMD" $(ops_scp_opts "$_port" 0) "$_local" "$_user@$_host:$_remote" > "$_tmp"
  fi
  _rc=$?
  ops_clean_stream < "$_tmp"
  rm -f "$_tmp"
  return $_rc
}

ops_scp_get() {
  _host=$1; _port=$2; _user=$3; _pass=$4; _remote=$5; _local=$6
  _tmp=$(mktemp 2>/dev/null) || ops_die "错误：无法创建临时文件。" 1
  if [ -n "$_pass" ]; then
    SSHPASS=$_pass "$OPS_SSHPASS_BIN" -e -- "$OPS_SCP_CMD" $(ops_scp_opts "$_port" 1) "$_user@$_host:$_remote" "$_local" > "$_tmp"
  else
    "$OPS_SCP_CMD" $(ops_scp_opts "$_port" 0) "$_user@$_host:$_remote" "$_local" > "$_tmp"
  fi
  _rc=$?
  ops_clean_stream < "$_tmp"
  rm -f "$_tmp"
  return $_rc
}
