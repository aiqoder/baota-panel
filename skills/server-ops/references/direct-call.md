# 宝塔直调原理与模板

> 本文件只处理「目标服务器装了宝塔面板」时的面板工具直调。
> 普通 Linux 服务器请走 `ops exec/script`（见 `references/generic-ops.md`）。

## 原理

`bt_agent_mcp` 的工具函数是普通 Python 函数，通过 `@register_tool` 收集进 `ToolRegistry`。
只需在**服务器上**以面板解释器运行一段引导代码，即可像 MCP 服务那样调用它们：

```
导入 operations（触发注册）
  → 建 ToolRegistry 并 register_all
  → set_request_context(auth_type="btai")   # 关键：跳过 confirm 二次确认闸
  → reg.call(tool_id, args)                 # 等价于 MCP 的 tools/call
```

底层即 `bt_agent_mcp_tools/registry.py:ToolRegistry.call`：JSON Schema 校验参数 →
（confirm 门控）→ `tool.handler(**args)` → 各 `operations/*.py` 函数。

本地（桌面端这台机器）**不需要 Python**：`ops` 只用 `ssh` 把引导代码送进服务器，
服务器端复用面板自带的 `/www/server/panel/pyenv/bin/python3`。

## 常规路径：直接用 ops bt

绝大多数情况**不需要**手写内联 Python，用技能自带脚本即可：

```bash
SKILL_DIR="${CHENGZI_PACKAGE_DIR}/skills/server-ops/scripts"
sh "$SKILL_DIR/ops" -s hk-1 bt DatabaseList '{"search":""}'
sh "$SKILL_DIR/ops" -s hk-1 bt-tools            # 列出当前注册的工具
sh "$SKILL_DIR/ops" -s hk-1 bt-tools database   # 按关键字过滤
```

脚本内部已处理：服务器清单解析与选择、**sshpass 口令注入 / 私钥认证**、
参数 base64 编码、远端 Python 引导、宝塔缺失时的退出码与提示。

## 内联模板（不依赖 ops bt）

仅在需要自定义远端逻辑时使用。核心是把「引导脚本」以 base64 送进远端，避免多层引号转义：

```bash
# 1) 准备远端 Python 引导脚本（原样照抄，改 tool_id 与 args 即可）
cat > /tmp/bt_boot.py <<'PY'
import sys, json, os, base64
PLUGIN = "/www/server/panel/plugin/bt_agent_mcp"
PANEL  = "/www/server/panel"
sys.path[0:0] = [PLUGIN, PANEL + "/class", PANEL]
import operations
from bt_agent_mcp_tools.registry import ToolRegistry, register_all
from bt_agent_mcp_tools.request_context import set_request_context, reset_request_context
reg = ToolRegistry(); register_all(reg)
tokens = set_request_context(key_id="local", auth_type="btai")
try:
    args = json.loads(base64.b64decode(os.environ["BT_ARGS_B64"]).decode("utf-8"))
    print(json.dumps(reg.call(os.environ["BT_TOOL_ID"], args), ensure_ascii=False))
finally:
    reset_request_context(tokens)
PY

# 2) base64 编码后内联进远端命令（sshpass 不转发 stdin，所以走内联）
B64=$(base64 < /tmp/bt_boot.py | tr -d '\n')
ARGS=$(printf '%s' '{"search":""}' | base64 | tr -d '\n')
sh "$SKILL_DIR/ops" -s hk-1 exec "
  BT_TOOL_ID='DatabaseList' BT_ARGS_B64='$ARGS' \
  /www/server/panel/pyenv/bin/python3 -c \"\$(echo '$B64' | base64 -d)\"
"
```

要点：
- **必须用内联的方式送脚本**（`python3 -c "$(echo <b64> | base64 -d)"`），因为 sshpass
  **不转发 stdin**，`python3 - ` 这类读 stdin 的写法会挂住。
- `sys.path[0:0]` 顺序（插件 → class → panel）与 `run_server.py` 一致。
- 参数含中文/特殊字符时，用 base64 传递最稳（`ops bt` 已内置）。
- 清单里密码留空/写 `-` 的机器走私钥认证，需要本机 `~/.ssh` 已配置对应密钥。
- **不设 `auth_type="btai"` 时，`confirm=true` 工具会返回 `waiting_confirm` 且不执行**；
  跨进程无法完成两阶段确认，故特权直调统一置为 `btai`。
- 日常请直接用 `ops bt`，不必手写上面的模板。

## 直接调用单个函数（绕过 Registry）

仅适合快速验证，会跳过 schema 校验与统一返回包装：

```python
import sys
plugin = "/www/server/panel/plugin/bt_agent_mcp"
sys.path[0:0] = [plugin, "/www/server/panel/class", "/www/server/panel"]
from operations.database import DatabaseList
print(DatabaseList(search=""))
```

## 与 MCP 通道的关键差异

| 维度 | MCP 通道（HTTP `/mcp`） | 本地直调（本技能） |
| --- | --- | --- |
| 鉴权 | 需 Bearer API Key，受 `tool_ids` 白名单限制 | 无，root 直接调 |
| IP 白名单 / 限流 | `_McpGate` 强制 | 绕过 |
| `confirm=true` 二次确认 | 由 `ConfirmGate` 拦截 | 置 `auth_type="btai"` 后**不拦截**，直接执行 |
| `basic_tool` | 视客户端能力提供 | 可直接调 |
| 外层超时 | `run_with_timeout` 兜底 | 无，仅工具自身超时 |
| 审计 | `audit.jsonl` | 不写（未走服务） |

> 因此：**高风险管理责任完全落在你身上**——必须遵守 SKILL.md 的「规则 1」自觉确认。

## 常见问题

- 普通服务器跑 `ops bt` 报「未找到宝塔 MCP 插件目录」（退出码 5）
  → 该机没装宝塔或没装 MCP 插件。先 `sh "$SKILL_DIR/ops" -s <别名> detect`；若是普通
  Linux 服务器，改用 `ops exec/script` 完成操作。
- 提示 `没有可用的服务器`
  → 服务器清单为空。到桌面端该软件设置页的「服务器清单」里按行填。
- `ModuleNotFoundError: No module named 'operations'`
  → 没把插件目录加进 `sys.path`，或用了系统 `python3`。用模板里的路径与面板解释器。
  若提示「未找到宝塔 MCP 插件目录」，说明服务器尚未安装插件：按
  https://docs.bt.cn/ai-ops/mcp/installation 安装「宝塔 MCP 服务」。
- `ModuleNotFoundError: No module named 'public'`
  → 解释器不对，必须 `/www/server/panel/pyenv/bin/python3`。
  也可能是面板 Python 未升级到文档要求版本，见同上安装指引。
- 一直没有输出 / 卡住
  → 首次连接在等主机指纹确认，或远端命令在等 stdin。`ops` 已设
  `StrictHostKeyChecking=accept-new` 自动接受首次指纹；仍卡则检查命令是否在等 stdin
  （sshpass 不转发 stdin）。可用 `sh "$SKILL_DIR/ops" servers` 看客户端状态。
- `Permission denied (publickey,password)`
  → 用户或密码不对。用 `ops servers` 核对这一行的 `用户@主机:端口`（宝塔常为 `root`）。
- 提示 `请用 --server <别名> 指定目标`
  → 配了多台但没指定。`sh "$SKILL_DIR/ops" servers` 看别名，再 `-s 别名`。
- 提示 `服务器清单第 N 行...端口不是数字`
  → 该行字段顺序写错了。格式固定为 `别名 | 主机 | 端口 | 用户 | 密码`，端口留空即 22。
