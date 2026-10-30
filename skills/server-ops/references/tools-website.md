# 网站 工具

共 15 个工具。

## SiteList · 获取网站列表

- 风险：**low**（低）

获取宝塔面板管理的网站列表。只读，仅面板原生站点。

data.sites 每项含 name、domains、ports、status、ps、project_type、path、php_version、ssl；
php_version 仅对 PHP 类站点（PHP/phpmod/wp2）有值，其他语言恒为空串；
ssl 为证书状态（enabled、days_left、not_after、issuer、san_domains，未部署时 enabled 为 False）。
name 是站点唯一标识，作为其他网站工具的站点参数。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `search` | 否 | string | 按站点名模糊搜索。 |
| `page` | 否 | integer | 页码，从 1 开始。 |
| `page_size` | 否 | integer | 每页数量，默认 20、最大 50。 |

## SiteGetConfig · 获取网站配置

- 风险：**low**（低）

获取指定网站当前生效的 webserver 配置文件内容。只读。

data 含 webserver（nginx/apache）、config_path、content（配置全文）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |

## SiteLogs · 获取网站访问日志

- 风险：**low**（低）

获取指定网站的访问日志（原始文本，末尾片段）。只读。网站打不开/报错/502/500 等排查先看本工具。

已对 URL 中的凭据参数（token/key/password 等）脱敏。仅访问日志；错误日志需另查 webserver 的 error log。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |

## SiteTraffic · 获取网站流量

- 风险：**low**（低）

获取指定网站的访问流量统计（UV/PV、请求数、流量趋势等）。只读。

返回单站流量数据；全站排名与总览用 TrafficAnalysis。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |

## SiteCreate · 创建网站

- 风险：**medium**（中）

创建网站并绑定 PHP 版本。中风险，有副作用。

php_version 为空时自动绑定已装版本（面板默认优先）。成功时 data 含 site_id、path、php_version、nginx_config。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `domain` | 是 | string | 域名或 IP，不含端口。 |
| `site_path` | 是 | string | 网站目录绝对路径。 |
| `port` | 否 | string | 站点端口，默认 80。 |
| `php_version` | 否 | string | PHP 版本号（如 "82"），留空自动绑定。 |

## SiteDelete · 删除网站

- 风险：**high**（高）

删除宝塔面板中的网站。高风险、不可逆，调用前必须向用户确认。删前用 SiteList 核对避免误删。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |
| `delete_path` | 否 | boolean | True 连网站目录一并删（默认），False 仅删站点记录保留文件。 |
| `ftp` | 否 | boolean | True 同时删除关联 FTP（默认 False）。 |
| `database` | 否 | boolean | True 同时删除关联数据库（默认 False）。 |
| `confirm` | 否 | boolean | 首次调用必须为 false，仅建立确认记录且不会执行。收到 waiting_confirm 后必须停止并询问用户。只有收到一条后续用户消息明确同意，才可使用完全相同的业务参数设置为 true。 |

## OneClickDeploy · 一键部署应用

- 风险：**medium**（中）

一键部署 CMS 应用。中风险，有副作用。需先用 SiteCreate 建站。

WordPress 自动补全：绑定 PHP、建库、生成 wp-config.php 并模拟安装向导。可重入：已安装时跳过。
成功时 data 含 admin_username、admin_password、success_url、db_name、db_user、db_password、auto_installed。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |
| `app` | 是 | string | 应用标识，如 wordpress、discuz、discuzx、typecho、dedecms。 |

## TrafficAnalysis · 获取全站流量分析

- 风险：**low**（低）

获取全部网站的流量分析聚合数据。只读。
返回全站聚合：三日总览、当日 Top5 站点（按流量降序）、近 7 日趋势；各段含流量/请求数/UV/PV。
字段以实际返回为准。单站明细用 SiteStats。

## SiteCertList · 获取证书库列表

- 风险：**low**（低）

获取面板证书库中的证书列表（本地导入 + Let's Encrypt + 云证书）。只读。

data.certs 每项含 id、hash、subject、dns（覆盖域名）、not_after、endtime（剩余天数）、
cloud_id（-1 为本地证书）、use_for_site（已部署到的站点 id 列表）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `search` | 否 | string | 按证书名称(subject)模糊搜索。 |
| `status_filter` | 否 | string | all/valid/expiring/expired/expired_long 之一：全部/未过期/15天内到期/已过期/过期1年以上。 |
| `force_refresh` | 否 | boolean | 是否强制刷新证书库（与宝塔云端同步），默认 false。 |

## SiteSSLDeploy · 部署SSL证书

- 风险：**medium**（中）

部署证书到网站：将证书库中已有证书（ssl_hash）或直接提供的证书（PEM 内容/文件）部署到指定网站。

中风险：写入站点证书目录并更新 webserver 配置。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |
| `ssl_hash` | 否 | string | 证书库中的证书 hash（SiteCertList 查询），与证书内容/文件来源互斥。 |
| `certificate` | 否 | string | PEM 证书内容（含证书链），与 private_key 成对提供。 |
| `private_key` | 否 | string | PEM 私钥内容。 |
| `cert_file` | 否 | string | 证书文件绝对路径（服务器本地），与 key_file 成对提供。 |
| `key_file` | 否 | string | 私钥文件绝对路径。 |

## SiteSSLApply · 申请SSL证书

- 风险：**medium**（中）

为站点配置/启用 HTTPS：申请并部署 SSL 证书（Let's Encrypt）。中风险：会写站点目录并重载 web 服务。

同步执行，耗时几十秒到数分钟。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList。 |
| `domains` | 是 | array | 要签发的域名列表。 |
| `validation` | 否 | string | 验证方式，仅支持 http。 |

## DomainManage · 网站域名管理

- 风险：**high**（高）

管理网站绑定域名：添加或删除。高风险，删除不可逆，调用前须向用户确认。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |
| `operation` | 是 | string | add 或 remove。 |
| `domains` | 是 | string | 域名列表，逗号分隔，单个可带 :port（不带端口默认 80）；remove 支持批量删除。 |

## SiteConfig · 配置网站

- 风险：**medium**（中）

配置网站：切换 PHP 版本 / 设置运行目录 / 配置默认首页 / 配置伪静态 / 重载配置。中风险，有副作用。

action 说明：
- php_version: value 填版本号（如 "82"），已安装版本用 SoftwareList 查询，当前版本见 SiteList 的 php_version；
- run_path: value 填相对路径（如 "/public"），空串表示站点根目录；
- index: value 填逗号分隔的默认文档（如 "index.php,index.html"）；
- rewrite: value 填伪静态规则全文；
- reload: value 忽略，重载 webserver 配置（php_version/run_path/index 修改后面板已自动重载，本 action 用于手动改配置文件后）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |
| `action` | 是 | string | 配置项，php_version/run_path/index/rewrite/reload 之一。 |
| `value` | 否 | string | 配置值，reload 时忽略。 |

## SiteControl · 启停网站

- 风险：**medium**（中）

启动/停止网站。中风险，有副作用（修改 webserver 配置并重载服务）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |
| `action` | 是 | string | start/stop 之一。 |

## SiteBackup · 备份网站

- 风险：**medium**（中）

备份站点（含文件、配置、SSL、关联数据库）。中风险：占用磁盘与 IO。

该操作可能进入后台并返回 task_id；用 BashStatus 查询状态与结果，用 BashStop 停止任务。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 站点名，取自 SiteList 返回的 name。 |
