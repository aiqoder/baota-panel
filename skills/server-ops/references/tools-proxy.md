# 反向代理 工具

共 5 个工具。

## ProxyProjectCreate · 创建反代项目

- 风险：**medium**（中）

创建反向代理项目（中风险：写入 nginx 配置、放行防火墙端口并重载服务）。

一个反代项目 = 一个面板站点（project_type=proxy），按主域名生成站点名，可带多域名与端口
（域名形如 'example.com' 或 'example.com:8080'，非 80 端口会成为监听端口）。proxy_pass 为目标
上游（http/https 或 unix socket），proxy_path 为前缀（默认 /）。创建即生效，成功后用
ProxyProjectInfo 确认站点名。

**安全提示**：若 proxy_pass 指向本机 bt_agent_mcp 服务自身端口（127.0.0.1:<resolve_port()>，
默认 8765），返回 data.warning 会给出风险说明（可能把 MCP 暴露给该反代域名并绕过来源 IP 白名单）。
确需经反代暴露 MCP 时，请在该反代 conf 设置 `proxy_set_header X-Real-IP $remote_addr;` 并把真实
客户端 IP 加入白名单。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `domains` | 否 | array/null | 域名列表（可带 :port），必填。 |
| `proxy_pass` | 否 | string | 代理目标，如 http://127.0.0.1:8080、https://api.example.com 或 /tmp/app.sock，必填。 |
| `proxy_path` | 否 | string | 代理前缀，默认 /。 |
| `proxy_host` | 否 | string | 转发 Host 头，默认 $http_host。 |
| `proxy_type` | 否 | string | http 或 unix，默认 http。 |
| `remark` | 否 | string | 备注。 |

## ProxyProjectInfo · 查看反代项目

- 风险：**low**（低）

查看反向代理项目。只读。

site_name 留空返回全部项目列表（data.sites 每项含 name/path/status/ps/ssl 天数/proxy_pass/healthy，
支持 search 模糊搜索 + 分页）；给出时返回单项目详情：站点字段 + 配置摘要（域名列表/监听端口/HTTPS
端口/SSL 与强制 HTTPS 状态/IP 黑白名单/URL 规则 proxy_info 精简：proxy_path/proxy_pass/proxy_host/
websocket/超时/备注）+ nginx 配置与日志文件路径（config_file/proxy_config_file/log_files）——
**配置文件内容用文件读取工具按路径自行查看**。**若某条 URL 规则指向本机 bt_agent_mcp 自身端口，
返回 data.warning 会给出风险提示**（来源 IP 白名单可能被绕过，仅剩 API Key 鉴权）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 否 | string | 反代项目站点名，留空返回列表。 |
| `search` | 否 | string | 列表模式按站点名模糊搜索。 |
| `page` | 否 | integer | 列表模式页码，从 1 开始。 |
| `page_size` | 否 | integer | 列表模式每页数量，默认 20、最大 100。 |

## ProxyProjectModify · 修改反代项目

- 风险：**medium**（中）

修改反代项目（中风险：有副作用）。

action 说明：
- remark: 改项目备注（remark）。
- start/stop: 启用/停止反代站点（停止后返回停机页）。
- add_domain: 增加绑定域名（domains，可带 :port；面板会同步 nginx 配置与反代 JSON）。
- remove_domain: 删除绑定域名（domains，至少保留一个）。
- force_https: 开启/关闭强制 HTTPS 跳转（force_https true=开、false=关）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 反代项目站点名，必填。 |
| `action` | 否 | string | remark/start/stop/add_domain/remove_domain/force_https，默认 remark。 |
| `remark` | 否 | string | remark 时的备注。 |
| `domains` | 否 | array/null | add_domain/remove_domain 的域名列表。 |
| `force_https` | 否 | boolean/null | force_https 时是否开启强制 HTTPS。 |

## ProxyWriteConfig · 修改反代配置

- 风险：**medium**（中）

直接编辑反代项目的 nginx 配置文件（中风险：改错可能导致站点异常，保存后请用 Bash `nginx -t` 验证）。

编辑起点：先用 ProxyProjectInfo 拿 config_file 路径，用文件读取工具 Read 当前配置，修改后把**完整
conf 全文**回传本工具。面板写 conf 后会解析并自动同步反向代理 JSON（proxy_info/域名/端口等）。
若配置有误导致站点异常，可用面板历史版本回滚或 Read 基线恢复后重新保存。

**安全提示**：若 conf 里某条 proxy_pass 指向本机 bt_agent_mcp 服务自身端口（127.0.0.1:<resolve_port()>，
默认 8765），返回 data.warning 会给出风险说明（可能把 MCP 暴露给该反代域名并绕过来源 IP 白名单）；
确需如此请在对应 location 设置 `proxy_set_header X-Real-IP $remote_addr;` 并把真实客户端 IP 加入白名单。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 反代项目站点名，必填。 |
| `conf_data` | 否 | string | 完整 nginx 配置文件内容（覆盖保存），必填。 |

## ProxyProjectDelete · 删除反代项目

- 风险：**high**（高）

删除反向代理项目（高风险、不可逆，调用前必须确认）。

删除 nginx 配置/日志/反代 JSON 目录与面板站点/域名记录；remove_path=true 时连同
/www/wwwroot/<name> 站点目录一并删除。反代 JSON 与 nginx 配置删除后不可恢复。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 反代项目站点名（先用 ProxyProjectInfo 核对）。 |
| `remove_path` | 否 | boolean | 是否同时删除站点根目录，默认 false。 |
