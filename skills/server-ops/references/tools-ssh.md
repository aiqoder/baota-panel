# SSH 工具

共 3 个工具。

## SSHInfo · 查看SSH

- 风险：**low**（低）

查看 SSH 服务状态与登录配置。只读。

data 含 sshd_status 与 config（root 登录方式、密码/密钥登录开关、密钥类型）。

## SSHConfig · 配置SSH

- 风险：**high**（高）

管理 SSH 密钥认证或重启 sshd。中风险：生成密钥时保留密码认证（双通道），关闭密钥时自动恢复密码。

action 说明：
- key: value 填密钥类型（ed25519/ecdsa/rsa），生成密钥对并启用密钥认证，保留密码认证；
- key_off: value 忽略，关闭密钥认证并恢复密码认证；
- restart: value 忽略，重启 sshd。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 是 | string | key/key_off/restart 之一。 |
| `value` | 否 | string | 密钥类型（仅 key 时需要）。 |

## SSHIntrusion · 查看异常登录

- 风险：**low**（低）

查看 SSH 异常登录统计（爆破情况）。只读。

data.intrusion 含累计与今日的登录失败/成功次数，用于判断是否遭受爆破攻击。
