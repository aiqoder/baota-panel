# 通知 工具

共 3 个工具。

## GetChannel · 获取通知通道列表

- 风险：**low**（低）

获取面板已配置的通知通道列表。只读。返回通道 id/type/used/title。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `refresh` | 否 | boolean | 强制刷新配置，默认 false。 |

## ManageChannel · 通知通道管理

- 风险：**high**（高）

管理通知通道：add 添加 / del 删除 / status 启停 / test 发测试消息。高风险。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `action` | 是 | string | add/del/status/test |
| `id` | 否 | string | 通道id，del/status/test必填，取自GetChannel |
| `type` | 否 | string | 通道类型：weixin(企业微信,webhook URL)/mail/feishu/dingding 可添加；wx_account(个人微信/公众号) 需面板扫码绑定；sms(短信)/webhook(自定义) 不支持 |
| `title` | 否 | string | 备注名，add必填，≤15字 |
| `data` | 否 | object | 各类型参数，按 type 填对应字段。 |

## SendMessage · 发送消息

- 风险：**medium**（中）

通过指定通知通道发送一条自由消息。通道不存在/停用时返回 available.channels。

| 参数 | 必填 | 类型 | 说明 |
| --- | --- | --- | --- |
| `channel_id` | 是 | string | 目标通道 id，取自 GetChannel。 |
| `content` | 是 | string | 消息内容。 |
| `title` | 否 | string | 消息标题，默认 宝塔面板消息推送。 |
