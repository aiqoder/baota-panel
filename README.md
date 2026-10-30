# 服务器与飞牛 NAS 助手

Every Code 智能体安装包。通过 SSH 管理普通 Linux 和宝塔面板，通过随包的 `trim-cli` 以 OAuth 管理飞牛 fnOS。

当前版本见 [`manifest.yaml`](manifest.yaml) 的 `version`。

## 安装

1. 在 [Releases](https://github.com/aiqoder/baota-panel/releases) 下载 `baota-panel-<版本>.cpk`。
2. 在 Every Code 顶栏安装该文件。同 id 只能安装不低于当前版本的包。
3. 在设置页填写环境变量：

| 变量 | 作用 |
| --- | --- |
| `BT_PANELS` | 服务器清单。每行一台，列依次为别名、主机、SSH 端口、用户、密码。端口留空为 22，用户留空为 root，密码留空则使用本机私钥。 |
| `FNOS_HOST` | 飞牛 NAS 主机。留空为本机。 |
| `FNOS_PORT` | NAS 端口。留空时本机 5666，远程 IP 5667，域名 443。 |
| `FNOS_SCHEME` | `auto`、`http` 或 `https`。留空为 `auto`。 |

服务器走技能 `server-ops`，飞牛 NAS 走技能 `fnos`。

## 本地打包

需要 Node.js。输出文件名固定为 `<id>-<version>.cpk`：

```bash
node .github/scripts/cpkpack.js -check -src .
node .github/scripts/cpkpack.js -src . -out dist -ext cpk
```

打包前把 `manifest.yaml` 的 `version` 升高。安装包压缩后不超过 32MB，解压后不超过 64MB。

## 自动打包

工作流 [`.github/workflows/package.yml`](.github/workflows/package.yml)：

- 推送到 `main`，或在 Actions 页手动运行：校验并打包，安装包挂在该次运行的 Artifact。
- 拉取请求：只校验包源。
- 推送标签 `v<version>`：打包并发布到 Release。标签必须与 `manifest.yaml` 的 `version` 一致，例如版本 `1.5.0` 对应标签 `v1.5.0`。
