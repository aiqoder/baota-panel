# 软件 工具

共 3 个工具。

## SoftwareList · 获取软件列表

- 风险：**low**（低）

获取宝塔软件商店清单及安装状态。只读。

data.software 每项含 name、title、version(当前已装版本，未装为空)、ps、setup、task(安装任务状态)、
versions(可选版本)。total 取自分页信息，未知时为 None。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `search` | 否 | string | 按名称搜索。 |
| `page` | 否 | integer | 页码，从 1 起。 |
| `page_size` | 否 | integer | 每页数量，默认 20、最大 100。 |

## SoftwareInstall · 安装软件

- 风险：**medium**（中）

提交软件安装（异步）。中风险。立即返回，用 SoftwareList 查看安装进度。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `name` | 是 | string | 软件名（nginx、mysql、php-7.4 等）。 |
| `version` | 否 | string | 安装版本，留空时取 SoftwareList 返回的第一个版本（稳定版）。 |
| `type` | 否 | string | 安装方式，默认 1。 |

## SoftwareUninstall · 卸载软件

- 风险：**high**（高）

提交软件卸载（面板同步执行）。高风险：移除已装软件，调用前必须确认。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `name` | 是 | string | 软件名，同 SoftwareInstall。 |
| `version` | 否 | string | 卸载版本，同 SoftwareInstall。 |
| `type` | 否 | string | 保留兼容，卸载方式由面板内部确定。 |
