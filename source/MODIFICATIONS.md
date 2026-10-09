# MODIFICATIONS — 本发行物对 GPL 组件的修改

**上游**：`https://github.com/veenyi/fnos-hermes-agent`，tag `v0.21.149`（GPL-3.0）
**比对对象**：本镜像内 `/opt/hermes` 的实测内容（见同目录 `opt-hermes/`）
**比对日期**：2026-10-09

GPL-3.0 §5(a) 要求的「显著声明」即本文件；完整修改后源码见 `opt-hermes/`。

## 逐文件比对结果

| 文件 | 状态 | 上游 sha256(前16) | 镜像 sha256(前16) |
|---|---|---|---|
| `config/bootstrap/hermes-version.env` | 内容改动 | `89558fbbcc9efcc5` | `c33bd7250568c0df` |
| `manifest` | 内容改动 | `51862080b2341dd2` | `895e5373ba402d4b` |
| `package.json` | 相同 | `95c36e2182e127ec` | `95c36e2182e127ec` |
| `server/monitor.js` | 内容改动 | `f31bac9aa7c0cd24` | `440cd8505a68e69c` |
| `server/preview_conv.py` | 仅行尾差异 (CRLF→LF) | `1e7e40a8771d90ba` | `a8786e8dcfcaf588` |
| `server/pty_bridge.py` | 仅行尾差异 (CRLF→LF) | `e280b33317acc6aa` | `31a57ae8242c819b` |
| `ui/index.html` | 内容改动 | `c51707b49971bc12` | `e15cae2b4f21438c` |

**差异合计**：7 个文件。

## 镜像中存在、上游 tag 不含的文件

- `ui/_check.js`
- `ui/_check_6.js`
- `ui/_dup_test.js`
