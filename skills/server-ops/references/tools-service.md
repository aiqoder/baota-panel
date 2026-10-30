# 服务 工具

共 2 个工具。

## ServiceStatus · 获取服务状态

- 风险：**low**（低）

查询服务的安装与运行状态。只读，不改变系统状态。

不传时返回所有支持的服务（nginx、apache、mysql、redis、pure-ftpd、memcached、mongodb + 已装 php-fpm 版本）。
支持别名（httpd/apache2→apache、mysqld/mariadb/mariadbd→mysql）；yum/apt 安装的服务同样可识别。
未安装返回 status=not_installed，不误报 stopped；传入不支持的名称返回错误并列出支持范围。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `service_names` | 否 | array | 服务名列表（如 ["nginx","mysql"]），留空返回全部。支持别名，自动去重。 |

## ServiceControl · 启停服务

- 风险：**medium**（中）

启动/停止指定服务。中风险：会短暂影响该服务现有连接，调用前须向用户确认。

未安装的服务跳过（status=not_installed）。成功时 data.results 每项含 service、operated、running、status。
重启场景由模型自行组合：先 stop 再 start。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `service_names` | 是 | array | 服务名列表，别名同 ServiceStatus。 |
| `action` | 是 | string | start/stop 之一。 |
