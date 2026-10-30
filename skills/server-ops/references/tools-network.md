# 网络 工具

共 3 个工具。

## WebFetch · 抓取网页

- 风险：**low**（低） · 基础工具

获取公开网页内容，供客户端依据 prompt 阅读、提取或分析。只读，不提交表单、不携带认证信息，也不执行网页脚本。

返回受限 Markdown 和 prompt，由调用方完成分析。响应超过 32KB 时拒绝返回。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `url` | 是 | string | 完整 http 或 https 地址。 |
| `prompt` | 是 | string | 描述希望从网页中得到的信息。 |

## ServerIP · 获取服务器IP

- 风险：**low**（低）

获取服务器的内网与公网 IP。只读。
data.internal 为内网 IPv4 列表（各网卡，已排除 loopback，多网卡时含多个）；
data.external 为公网 IP，查询失败时为 None。

## Upload · 上传

- 风险：**medium**（中）

上传客户端本地文件；调用方必须能在客户端本机执行 curl，否则无法用本工具上传。

首次调用传 file_name，执行返回的 next_action 中对应平台命令，只替换 <LOCAL_FILE>。
命令已固定服务器公钥，应原样执行。命令失败或结果不确定时，按返回的 on_failure 处理，不要重跑旧命令。
不要自行获取 offset、分片或构造 PUT/PATCH。ready=true 表示完成；成功后将返回文件绝对路径，可直接使用 path。
仅上传已经生成完毕且不再写入的本地文件。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `file_name` | 否 | string | 首次调用时传本地文件名，不传路径或文件内容。 |
| `size` | 否 | integer/null | 可选文件字节数，用于大小校验。 |
| `sha256` | 否 | string | 可选的预期 SHA256；传入时校验完整内容，未传时只返回实际摘要，expected_sha256_matched=null。 |
| `file_id` | 否 | string | 恢复上传时传首次调用返回的值。 |
