# 工具速查表（全部 98 个）

按分类列出 `tool_id`、中文名与风险等级。详细参数见对应 `tools-<领域>.md`。

## 基础

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `Read` | 读取文件 | low |
| `Edit` | 精确修改文件 | high |
| `Write` | 写入文件 | high |
| `Glob` | 查找文件 | low |
| `Grep` | 搜索文件内容 | low |
| `LS` | 列出目录 | low |
| `Bash` | 执行命令 | high |
| `BashStatus` | 查询命令状态 | low |
| `BashStop` | 终止后台任务 | medium |

## 网站

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `SiteList` | 获取网站列表 | low |
| `SiteGetConfig` | 获取网站配置 | low |
| `SiteLogs` | 获取网站访问日志 | low |
| `SiteTraffic` | 获取网站流量 | low |
| `SiteCreate` | 创建网站 | medium |
| `SiteDelete` | 删除网站 | high |
| `OneClickDeploy` | 一键部署应用 | medium |
| `TrafficAnalysis` | 获取全站流量分析 | low |
| `SiteCertList` | 获取证书库列表 | low |
| `SiteSSLDeploy` | 部署SSL证书 | medium |
| `SiteSSLApply` | 申请SSL证书 | medium |
| `DomainManage` | 网站域名管理 | high |
| `SiteConfig` | 配置网站 | medium |
| `SiteControl` | 启停网站 | medium |
| `SiteBackup` | 备份网站 | medium |

## 网络

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `WebFetch` | 抓取网页 | low |
| `ServerIP` | 获取服务器IP | low |
| `Upload` | 上传 | medium |

## 数据库

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `DatabaseList` | 获取数据库列表 | low |
| `DatabaseCreate` | 创建数据库 | medium |
| `DatabaseDelete` | 删除数据库 | high |
| `DatabaseBackup` | 备份数据库 | medium |
| `MysqlQuery` | MySql查询 | low |
| `MysqlExecute` | MySql写操作 | high |

## 服务

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `ServiceStatus` | 获取服务状态 | low |
| `ServiceControl` | 启停服务 | medium |

## Docker

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `ContainerList` | 容器列表 | low |
| `ContainerLogs` | 容器日志 | low |
| `ContainerInspect` | 容器详情 | low |
| `ComposeList` | 编排项目列表 | low |
| `ImageList` | 镜像列表 | low |
| `VolumeList` | 存储卷列表 | low |
| `NetworkList` | 网络列表 | low |
| `ContainerControl` | 容器启停 | medium |
| `ContainerDelete` | 删除容器 | high |
| `ImagePull` | 拉取镜像 | medium |

## 系统

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `SystemInfo` | 获取系统信息 | low |

## 软件

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `SoftwareList` | 获取软件列表 | low |
| `SoftwareInstall` | 安装软件 | medium |
| `SoftwareUninstall` | 卸载软件 | high |

## 防火墙

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `FirewallStatus` | 获取防火墙状态 | low |
| `FirewallPortList` | 获取端口规则列表 | low |
| `FirewallIpList` | 获取IP规则列表 | low |
| `FirewallPortSet` | 设置端口规则 | high |
| `FirewallIpSet` | 设置IP规则 | high |

## Java

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `JavaJdk` | 管理JDK | medium |
| `JavaProjectCreate` | 分析并创建Java项目 | medium |
| `JavaProjectInfo` | 查看Java项目 | low |
| `JavaProjectControl` | 控制Java项目进程 | medium |
| `JavaProjectModify` | 修改Java项目 | medium |
| `JavaProjectDelete` | 删除Java项目 | high |

## NodeJS

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `NodeVersion` | 管理Node版本 | medium |
| `NodeProjectCreate` | 分析并创建Node项目 | medium |
| `NodeProjectInfo` | 查看Node项目 | low |
| `NodeProjectControl` | 控制Node项目进程 | medium |
| `NodeProjectModify` | 修改Node项目 | medium |
| `NodeProjectDelete` | 删除Node项目 | high |

## Python

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `PythonVersion` | 管理Python版本 | medium |
| `PythonEnv` | 管理虚拟环境与包 | medium |
| `PythonProjectCreate` | 分析并创建Python项目 | medium |
| `PythonProjectInfo` | 查看Python项目 | low |
| `PythonProjectControl` | 控制Python项目进程 | medium |
| `PythonProjectService` | 管理项目关联进程 | medium |
| `PythonProjectModify` | 修改Python项目 | medium |
| `PythonProjectDelete` | 删除Python项目 | high |

## Go

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `GoVersion` | 管理Go环境 | medium |
| `GoProjectCreate` | 创建Go项目 | medium |
| `GoProjectInfo` | 查看Go项目 | low |
| `GoProjectControl` | 控制Go项目进程 | medium |
| `GoProjectModify` | 修改Go项目 | medium |
| `GoProjectDelete` | 删除Go项目 | high |

## 反向代理

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `ProxyProjectCreate` | 创建反代项目 | medium |
| `ProxyProjectInfo` | 查看反代项目 | low |
| `ProxyProjectModify` | 修改反代项目 | medium |
| `ProxyWriteConfig` | 修改反代配置 | medium |
| `ProxyProjectDelete` | 删除反代项目 | high |

## HTML

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `HtmlProjectInfo` | 查看HTML项目 | low |
| `HtmlProjectCreate` | 创建HTML项目 | medium |
| `HtmlProjectModify` | 修改HTML项目 | medium |
| `HtmlProjectDelete` | 删除HTML项目 | high |

## SSH

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `SSHInfo` | 查看SSH | low |
| `SSHConfig` | 配置SSH | high |
| `SSHIntrusion` | 查看异常登录 | low |

## 安全

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `SecurityCheck` | 安全检查 | low |

## 计划任务

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `GetCrontab` | 获取计划任务列表 | low |
| `ManageCrontab` | 计划任务管理 | high |

## 通知

| tool_id | 中文名 | 风险 |
| --- | --- | --- |
| `GetChannel` | 获取通知通道列表 | low |
| `ManageChannel` | 通知通道管理 | high |
| `SendMessage` | 发送消息 | medium |
