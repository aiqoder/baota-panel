# 防火墙 工具

共 5 个工具。

## FirewallStatus · 获取防火墙状态

- 风险：**low**（低）

获取系统防火墙状态。只读。

返回 data：running 是否启用、type 类型(ufw/firewalld/iptables)、port_count 端口规则数、ping 是否响应 Ping。

## FirewallPortList · 获取端口规则列表

- 风险：**low**（低）

获取防火墙端口规则列表。只读，防火墙未启用时返回错误。

返回面板分页结构，规则项含 Port、Protocol、Address(来源)、Strategy(accept/drop)、Chain、brief。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `chain` | 否 | string | ALL/INPUT/OUTPUT。 |
| `search` | 否 | string | 按端口或备注模糊匹配。 |
| `page` | 否 | integer | 页码，从 1 起。 |
| `page_size` | 否 | integer | 每页数量，上限 100。 |

## FirewallIpList · 获取IP规则列表

- 风险：**low**（低）

获取防火墙 IP 规则列表(放行或屏蔽的 IP)。只读，防火墙未启用时返回错误。

返回面板分页结构，规则项含 Address(IP/CIDR)、Strategy(accept/drop)、Chain、Family、brief。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `chain` | 否 | string | ALL/INPUT/OUTPUT。 |
| `search` | 否 | string | 按 IP 或备注模糊匹配。 |
| `page` | 否 | integer | 页码，从 1 起。 |
| `page_size` | 否 | integer | 每页数量，上限 100。 |

## FirewallPortSet · 设置端口规则

- 风险：**high**（高）

添加或删除防火墙端口规则。高风险，调用前须向用户确认；防火墙未启用时返回错误。

删除时 protocol/address/strategy/chain 须与添加时一致，建议先 FirewallPortList 查询。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `operation` | 是 | string | add 或 remove。 |
| `port` | 是 | string | 端口或范围，如 80、8080-8090。 |
| `protocol` | 否 | string | tcp/udp/tcp/udp，默认 tcp/udp。 |
| `address` | 否 | string | 来源 IP，默认 all。 |
| `strategy` | 否 | string | accept 或 drop。 |
| `chain` | 否 | string | INPUT 或 OUTPUT。 |
| `brief` | 否 | string | 备注。 |

## FirewallIpSet · 设置IP规则

- 风险：**high**（高）

添加或删除防火墙 IP 规则(放行或屏蔽某 IP 全部访问)。高风险，调用前须向用户确认；防火墙未启用时返回错误。

删除时 strategy/chain/family 须与添加时一致，建议先 FirewallIpList 查询。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `operation` | 是 | string | add 或 remove。 |
| `address` | 是 | string | 目标 IP/CIDR（如 1.2.3.4），不支持 all。 |
| `strategy` | 否 | string | accept 或 drop，默认 drop。 |
| `chain` | 否 | string | INPUT 或 OUTPUT。 |
| `family` | 否 | string | ipv4 或 ipv6。 |
| `brief` | 否 | string | 备注。 |
