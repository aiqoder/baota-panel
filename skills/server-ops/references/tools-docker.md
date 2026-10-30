# Docker 工具

共 10 个工具。

## ContainerList · 容器列表

- 风险：**low**（低）

获取容器列表（状态、IP、端口映射）。只读，不改变任何状态。

未安装或未运行时 data.installed=false 且 data.service_status 说明原因。
data.container_list 每项含 id、name（面板显示名）、status、image、ip、ports、cpu_usage。

## ContainerLogs · 容器日志

- 风险：**low**（低）

获取容器日志（尾部 lines 行）。只读。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `container` | 是 | string | 容器名（面板显示名/真实名/ID）。 |
| `lines` | 否 | integer | 取尾部行数，上限 1000。 |

## ContainerInspect · 容器详情

- 风险：**low**（低）

查看容器详情（状态、镜像、重启策略、挂载、端口、网络）。只读。

用于排查异常：挂载是否在、端口映射、重启策略、健康状态等。环境变量可能含密码等敏感值，刻意不返回。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `container` | 是 | string | 容器名（面板显示名/真实名/ID）。 |

## ComposeList · 编排项目列表

- 风险：**low**（低）

获取 docker-compose 项目列表（含模板与运行状态）。只读。

data.project_list 每项含 id、name、remark、status、path、containers。

## ImageList · 镜像列表

- 风险：**low**（低）

获取镜像列表（名称/标签/大小）。只读。

data.images_list 每项含 id、name、tags、size（字节）；installed/service_status 说明 Docker 状态。

## VolumeList · 存储卷列表

- 风险：**low**（低）

获取存储卷列表（名称、驱动、挂载点、使用容器）。只读。

data.volume 每项含 Name、Driver、Mountpoint、container（使用该卷的容器名）。

## NetworkList · 网络列表

- 风险：**low**（低）

获取 docker 网络列表（名称、驱动、子网、网关）。只读。

data.network 每项含 id、name、driver、subnet、gateway。

## ContainerControl · 容器启停

- 风险：**medium**（中）

启动/停止/重启容器。中风险：会改变容器运行状态，调用前须向用户确认。
返回操作后的容器状态。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `container` | 是 | string | 容器名（面板显示名/真实名/ID）。 |
| `action` | 是 | string | 操作，仅支持 start/stop/restart。 |

## ContainerDelete · 删除容器

- 风险：**high**（高）

删除容器（强制，同步清理宝塔 name_map 与监控统计）。高风险：容器及数据不可恢复，调用前必须确认。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `container` | 是 | string | 容器名（面板显示名/真实名/ID）。 |

## ImagePull · 拉取镜像

- 风险：**medium**（中）

拉取镜像。中风险。

该操作可能进入后台并返回 task_id；用 BashStatus 查询状态与结果，用 BashStop 停止任务。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `image` | 是 | string | 镜像名，如 nginx:latest，可带仓库地址（如 registry.example.com/ns/img:tag）。 |
| `registry` | 否 | string | 私有仓库地址，默认空即 Docker Hub。 |
| `username` | 否 | string | 私有仓库用户名，与 password 成对填写。 |
| `password` | 否 | string | 私有仓库密码，仅经 stdin 传入，不进审计。 |
