# HTML 工具

共 4 个工具。

## HtmlProjectInfo · 查看HTML项目

- 风险：**low**（低）

查看面板管理的 Html(静态)项目。只读。

site_name 留空返回全部项目列表（data.sites 每项含 name/path/status/ps/type_id/ssl 剩余天数，支持
search 按站点名/备注模糊搜索 + 分页）；给出时返回单项目详情：站点字段 + 域名列表 + SSL 状态 +
运行目录 + nginx/apache/rewrite 配置文件与日志文件路径（config_file/apache_config_file/rewrite_file/
log_files）——**配置文件内容用文件读取工具按路径自行查看**。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 否 | string | 项目站点名（主域名），留空返回列表。 |
| `search` | 否 | string | 列表模式按站点名/备注模糊搜索。 |
| `page` | 否 | integer | 列表模式页码，从 1 开始。 |
| `page_size` | 否 | integer | 列表模式每页数量，默认 20、最大 100。 |

## HtmlProjectCreate · 创建HTML项目

- 风险：**medium**（中）

创建 Html(静态)项目（中风险：写入 nginx/apache 配置、非 80 端口放行防火墙并重载服务）。

一个 Html 项目 = 一个面板站点（project_type=html），按主域名生成站点名，可带多域名与端口（域名形如
'example.com' 或 'example.com:8080'，非 80 端口会成为监听端口）。path 为网站根目录绝对路径（可指向
已有前端目录，目录不存在会自动创建）。创建即生效，成功后用 HtmlProjectInfo 确认站点名。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `domains` | 否 | array/null | 域名列表（可带 :port），首项为主域名，必填。 |
| `path` | 否 | string | 网站根目录绝对路径（如 /www/wwwroot/demo.example.com），必填。 |
| `ps` | 否 | string | 项目备注。 |
| `type_id` | 否 | integer | 项目分类 ID，默认 0。 |

## HtmlProjectModify · 修改HTML项目

- 风险：**medium**（中）

修改 Html(静态)项目（中风险：有副作用）。

action 说明：
- remark: 改项目备注（remark）。
- start/stop: 启用/停止站点（静态站无重启概念）。
- add_domain: 增加绑定域名（domains 列表，可带 :port；面板同步 nginx/apache 配置与 domain 表）。
- remove_domain: 删除绑定域名（domain，可带 :port；至少保留一个）。
- change_path: 修改网站根目录（path 绝对路径，**目标目录必须已存在**）。
- set_run_path: 设置运行目录（run_path 为根目录下的相对子目录，如 /dist，'/' 或空=根目录）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 项目站点名，必填。 |
| `action` | 否 | string | remark/start/stop/add_domain/remove_domain/change_path/set_run_path，默认 remark。 |
| `remark` | 否 | string | remark 时的备注。 |
| `domains` | 否 | array/null | add_domain 的域名列表。 |
| `domain` | 否 | string | remove_domain 的域名（可带 :port）。 |
| `path` | 否 | string | change_path 的目标网站根目录（绝对路径，须已存在）。 |
| `run_path` | 否 | string | set_run_path 的相对子目录（如 /dist）。 |

## HtmlProjectDelete · 删除HTML项目

- 风险：**high**（高）

删除 Html(静态)项目（高风险、不可逆，调用前必须确认）。

删除 nginx/apache/rewrite 配置、放行记录与面板站点/域名记录；**不删除 /www/wwwroot 站点目录**
（如需删除目录请用文件系统工具另行处理）。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `site_name` | 是 | string | 项目站点名（先用 HtmlProjectInfo 核对）。 |
