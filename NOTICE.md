# NOTICE — 来源、许可与修改声明

本文件逐项声明本发行物（`fnos-hermes-dist-slim-0.21.2.tar.gz` 镜像及其本仓库配套文件）
所包含的第三方组件、各自许可，以及本项目对它们的修改。

---

## 0. 本项目

| 项 | 值 |
|---|---|
| 名称 | fnOS Hermes 单机版（Docker 打包） |
| 版本 | 0.21.2-dist-slim |
| 许可 | GNU GPL v3.0（全文见 [`LICENSE`](LICENSE)） |
| 性质 | **第三方二次打包**，与 Nous Research、飞牛（fnOS）均无隶属关系 |
| 作者对自有部分（Dockerfile、入口脚本、安装脚本、文档）持有版权 | |

---

## 1. Hermes Agent 内核（MIT）

| 项 | 值 |
|---|---|
| 上游 | https://github.com/NousResearch/hermes-agent |
| 版本 | v0.21.2 |
| 许可 | MIT — Copyright (c) 2025 Nous Research |
| 位于镜像 | `/opt/hermes/hermes-src` |
| 许可全文 | [`licenses/MIT-hermes-NousResearch.txt`](licenses/MIT-hermes-NousResearch.txt) |

MIT 条件：**保留版权与许可声明**。许可原文已随镜像分发（`/opt/hermes/hermes-src/LICENSE`），
并在此仓库保留副本。

---

## 2. Octop（MIT）

| 项 | 值 |
|---|---|
| 上游 | https://github.com/TencentCloud/Octop |
| 许可 | MIT — Copyright (c) 2026 Octop |
| 许可全文 | [`licenses/MIT-Octop.txt`](licenses/MIT-Octop.txt) |

**为什么必须列**：第 3 节的 fnOS 增值层在实现上沿用了 Octop 的设计与素材，代码内注释实取包括
`融合来源：Octop tool_guard`、`连接器（OCTOP 风格：catalog + 真实 callTool）`、
`对齐 Octop probe_channel`；`i18n` 内更含 Octop 的内置人格库（"小办 (Auto)" 等）。
按 MIT 条款，**Octop 的版权声明必须一并保留**，故列出。

---

## 3. fnOS 增值层（GPL-3.0，本发行物的主要 copyleft 组件）

| 项 | 值 |
|---|---|
| 上游 | https://github.com/veenyi/fnos-hermes-agent （tag `v0.21.149`） |
| 更上游 | https://github.com/iranee/fnos-hermes-agent （`veenyi` 为 fork） |
| 许可 | GNU GPL v3.0 |
| 位于镜像 | `/opt/hermes/{server,ui,config,bin,manifest}` |
| 对应源码 | 本仓库 [`source/opt-hermes/`](source/opt-hermes/)（**已含本项目修改**） |

### 修改声明（GPL-3.0 §5(a)）

本项目对该层作了下列修改。修改后的完整源码见 [`source/opt-hermes/`](source/opt-hermes/)，
与上游 tag `v0.21.149` 的逐文件比对见 [`source/MODIFICATIONS.md`](source/MODIFICATIONS.md)。

| 文件 | 修改 |
|---|---|
| `server/monitor.js` | 日志与笔记时间戳由**硬编码 UTC+8（北京时区）**改为跟随进程 `TZ` 环境变量（共 19 行） |
| `ui/index.html` | `<base href>` 由 `/app/hermes-agent/`（fnOS 反代子路径）改为 `/`（独立部署）（1 行） |
| `config/bootstrap/hermes-version.env` | 版本标记 `0.20.0` → `0.21.0`（2 行） |
| `manifest` | 版本/校验字段调整，行尾 CRLF → LF |
| `server/preview_conv.py`、`server/pty_bridge.py` | **仅行尾 CRLF → LF，内容未改** |
| `ui/_check.js`、`ui/_check_6.js`、`ui/_dup_test.js` | 上游不含的遗留调试文件（随镜像一并分发） |
| `server/monitor.js`、`ui/index.html` 等 | 另有行尾统一处理（CRLF → LF） |

> 说明：`hermes-src`（第 1 节，MIT）不属 GPL 组件，其对应源码请见上游 Nous 仓库；
> 本仓库的 `source/` 只覆盖 GPL 组件，以避免把 MIT 上游源码重复打包。

---

## 4. 其它随附第三方组件

| 组件 | 许可 | 位置 |
|---|---|---|
| `ws`（Node WebSocket 库） | MIT | 镜像 `/opt/hermes/server/_vendor/ws`（许可副本 [`licenses/MIT-ws.txt`](licenses/MIT-ws.txt)） |
| `marked` v13.0.3 | MIT — Copyright (c) 2011-2024 Christopher Jeffrey | 镜像 `/opt/hermes/ui/scripts/marked.min.js`（许可头内嵌于文件首行） |
| `trim-cli`（飞牛 fnOS 官方 CLI，含 x64/arm64 二进制） | 随上游 fnOS 层分发 | 镜像 `/opt/hermes/config/prompts/skills/trim-cli/` |
| Debian 基础镜像、Node.js、Python 及其 PyPI 依赖、Playwright 等 | 各自的许可 | 镜像内各运行环境 |

**诚实边界**：镜像内含数百个第三方依赖（Node/Python 生态），本文件列出的是**直接纳入本项目源码树
或构成主要来源**的组件；其余依赖的许可证随各上游发行物提供，本项目不对其逐一重新声明。

---

## 5. 免责声明

软件按「现状」提供，不附带任何明示或暗示的保证。本项目不对 Hermes Agent、
fnOS 增值层、Octop 或任何第三方组件的安全性、稳定性、合规性作任何担保。

---

# NOTICE (English summary)

This distribution bundles several third-party components:

- **Hermes Agent core** — © Nous Research, MIT — `/opt/hermes/hermes-src`
- **Octop** — © 2026 Octop, MIT (design/personas/tool-guards reused by the fnOS layer)
- **fnOS layer** — GPL-3.0, upstream `veenyi/fnos-hermes-agent` (fork of `iranee/fnos-hermes-agent`),
  tag `v0.21.149`. **Modified by this project** (timezone de-hardcoding, base-href rewrite,
  version bump, line-ending normalisation). Modified corresponding source: `source/opt-hermes/`;
  per-file diff vs upstream: `source/MODIFICATIONS.md`.
- Other bundled components: `ws` (MIT), `marked` (MIT), `trim-cli`, and the Debian/Node/Python
  dependency set — under their respective upstream licences.

This is a **third-party repackaging**, not an official release by Nous Research, and is not
affiliated with Nous Research or FeiNiu (fnOS). Provided "as is", without warranty.
