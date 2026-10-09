# fnOS Hermes 单机版 · Docker 镜像（dist-slim 0.21.2）

**一句话**：把「飞牛 fnOS 应用商店里的 Hermes Agent」打包成一个单文件 Docker 镜像，
在任意 Linux 主机上用一条命令跑起来 —— 自带图形 WebUI、职业技能库、多平台消息网关。

> English: [`README.en.md`](README.en.md)

---

## ⚠️ 先读这一段（安全）

**本版本不含登录/鉴权（dist-slim = 精简发行版）。**
面板端口一旦被局域网或公网访问到，**任何人都能打开面板、驱动这个 AI agent 执行命令**。

- 安装脚本**默认只监听 `127.0.0.1`**（仅本机可访问）。
- 需要局域网/公网访问时，**必须自己在前面加一层反向代理 + HTTPS + 认证**（Nginx / Caddy + Basic Auth / Authelia 等），再显式加 `--expose`。
- **不要**把面板端口直接暴露到公网。

详见 [`SECURITY.md`](SECURITY.md)。

---

## 这是什么

| 项 | 值 |
|---|---|
| 镜像名 | `fnos-hermes:0.21.2-dist-slim` |
| 镜像包 | `fnos-hermes-dist-slim-0.21.2.tar.gz`（约 811 MiB） |
| 内置内核 | Hermes Agent v0.21.2（[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)，MIT） |
| fnOS 增值层 | 基于 fnOS 应用包（v0.21.149），GPL-3.0，来源与改动见 [`NOTICE.md`](NOTICE.md) |
| 面板端口 | `8650`（WebUI） |
| 其它端口 | `8742`（消息网关）、`9219`（Dashboard） |
| 数据卷 | `/data`（配置/会话/技能）、`/var/hermes`（日志/运行时） |
| 运行用户 | `hermes`（uid 10000，非 root） |

跑起来之后，打开面板 → 填自己的模型 API Key（及需要的消息平台凭证）即可对话。**镜像内不含任何密钥。**

---

## 一键安装（推荐）

前提：一台 Linux 主机（Ubuntu / Debian 等），已装 Docker。

**三步拉取（Release 直链，无需登录）：**

```bash
# 1. 下载安装脚本 + 镜像包 + 校验文件（约 811 MiB）
curl -LO https://github.com/talarixcanada-web/fnos-hermes-single/releases/download/v0.21.2-dist-slim/install-hermes-single-0.21.2.sh
curl -LO https://github.com/talarixcanada-web/fnos-hermes-single/releases/download/v0.21.2-dist-slim/fnos-hermes-dist-slim-0.21.2.tar.gz
curl -LO https://github.com/talarixcanada-web/fnos-hermes-single/releases/download/v0.21.2-dist-slim/SHA256SUMS

# 2. 运行安装脚本（默认只绑 127.0.0.1，最安全）
sudo bash install-hermes-single-0.21.2.sh

# 3. 打开面板
#    http://127.0.0.1:8650/
```

脚本会：检查 Docker → 校验镜像包 SHA256 → 导入镜像 → 建数据卷 → 启动容器 → 等首启完成 → 自检面板 HTTP 200。
重复执行是**幂等**的：旧容器会被改名保留作为回滚点，数据卷不动。

常用参数：

```bash
sudo bash install-hermes-single-0.21.2.sh --expose          # 绑所有网卡（⚠️ 无鉴权，风险自负）
sudo bash install-hermes-single-0.21.2.sh --port 8650       # 改本机映射端口
sudo bash install-hermes-single-0.21.2.sh --pkg /path/fnos-hermes-dist-slim-0.21.2.tar.gz
```

---

## 手动安装（不想用脚本）

```bash
docker load -i fnos-hermes-dist-slim-0.21.2.tar.gz

docker volume create hermes-data
docker volume create hermes-var

docker run -d --name hermes --restart unless-stopped \
  -p 127.0.0.1:8650:8650 \
  -v hermes-data:/data -v hermes-var:/var/hermes \
  -e TZ="$(cat /etc/timezone 2>/dev/null || echo UTC)" \
  fnos-hermes:0.21.2-dist-slim
```

然后访问 `http://127.0.0.1:8650/`。

> 首次启动需要把预装的 Python 运行环境"展开"到 `/data/venv`（镜像里已预装，无需联网），
> 视磁盘速度约 **30–90 秒**，期间面板打不开是正常的。

---

## 首次使用

1. 打开 `http://127.0.0.1:8650/`，进入面板。
2. 到「模型 / Models」页，填入**你自己的**模型 API Key（OpenAI / Anthropic / DeepSeek / Kimi 等，取决于你用的 provider）。
3. 需要消息平台（Telegram / 微信 / 飞书 / QQ 等）就在面板里绑定自己的 bot 凭证。
4. 镜像**不含任何密钥**，一切凭证都由你自己填、存在你自己的数据卷里。

---

## 系统要求

- Linux x86_64（amd64 镜像）
- Docker（19.03+ 即可，实测 Docker 29.x 正常）
- 磁盘：镜像 ~811 MiB + 首次展开运行环境约 1 GiB + 数据增长
- 内存：建议 ≥ 2 GiB

---

## 数据、备份与卸载

```bash
# 数据在哪
docker volume inspect hermes-data     # → Mountpoint
docker volume inspect hermes-var

# 备份（直接打包数据卷）
docker run --rm -v hermes-data:/data -v "$PWD":/backup alpine \
  tar czf /backup/hermes-data-$(date +%F).tar.gz -C /data .

# 停止 / 启动 / 看日志
docker stop hermes
docker start hermes
docker logs hermes --tail 100

# 卸载（容器删掉，数据保留）
docker rm -f hermes

# 连数据一起删（不可恢复）
docker rm -f hermes && docker volume rm hermes-data hermes-var
```

---

## 许可与来源

本仓库以 **GPL-3.0** 发布（完整文本见 [`LICENSE`](LICENSE)）。

- **Hermes Agent 内核**：© Nous Research，MIT 许可（[上游](https://github.com/NousResearch/hermes-agent)）。
- **fnOS 增值层**（`server/`、`ui/`、`config/` 等）：来自 fnOS 应用包 v0.21.149，GPL-3.0。
- **本仓库的 Docker 化改造**（Dockerfile、入口脚本、安装脚本、文档）：本项目作者，GPL-3.0。

对应源码（含本项目对 GPL 组件的修改）在本仓库 [`source/`](source/) 目录中，随本仓库一并提供。
逐项声明见 [`NOTICE.md`](NOTICE.md)。

---

## 免责声明

本项目是**第三方二次打包**，**不是** Nous Research 官方发行版，与 Nous Research、飞牛（fnOS）均无隶属关系。
软件按「现状」提供，不附带任何明示或暗示的保证。使用者自行评估并承担部署与使用风险，
尤其是**在未自建鉴权层的前提下把面板暴露到网络**所带来的后果。
