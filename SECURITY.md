# 安全说明 / Security Notes

> 中文在下，English below.

---

## 中文

### 核心事实：本版本**没有登录、没有鉴权**

`dist-slim` 是精简发行版，面板（`8650`）**不校验任何身份**。
只要有人能访问到这个端口，他就能：打开完整的图形面板、编辑配置、驱动这个 AI agent
在容器内执行命令、读写你的数据卷。

**这不是缺陷，是本版本的定位** —— 它是给单机自用/内网实验用的精简包。
是否愿意承担风险由你自己判断，但请务必知道自己在承担什么。

### 官方安装脚本的默认行为（安全优先）

| 默认 | 说明 |
|---|---|
| 只绑 `127.0.0.1` | 面板仅本机可访问；容器内进程以非 root 用户 `hermes`(uid 10000) 运行 |
| `--cap-drop ALL` | 去掉全部 Linux capabilities |
| `--security-opt no-new-privileges` | 禁止提权 |
| `--pids-limit 2048` | 限制进程数，防 fork 炸弹 |
| 日志轮转 | `max-size=10m`，最多 3 个文件 |
| 校验 SHA256 | 导入前校验镜像包完整性 |

要用 `--expose`（绑所有网卡），请**先**把下面第 1 条做完。

### 如果你要让别人访问，至少做到

1. **前面加一层带认证的反向代理**（Nginx / Caddy + Basic Auth，或 Authelia 之类的 SSO）。
   只暴露反代端口，面板端口本身不要直接对外。
2. **上 HTTPS**（Let's Encrypt / acme.sh）。明文 HTTP 下，面板里的模型 API Key 会以明文过网。
3. **限制来源 IP**（防火墙 / 反代 allowlist），别做全公网开放。
4. 不要把这个容器和其他重要服务放在同一台无法承受失陷的主机上；
   容器里的 agent 能执行命令（虽然受 `--cap-drop` / 非 root 限制，但依然是命令执行面）。

### 已知局限（诚实清单）

- **无登录**：如上。
- **端口语义**：镜像还声明了 `8742`（消息网关）与 `9219`（Dashboard）。默认安装脚本**不映射**它们。
  如果你自己加 `-p`，请注意它们**同样没有独立鉴权**。
- **镜像内含 fnOS 增值层**（`trim-cli` 等飞牛组件）与大量第三方 Python/Node 依赖。
  它们随上游发行；上游组件的安全状况不在本项目控制范围内。
- **镜像基于 `debian:13-slim` 等上游基础镜像**。上游若有已知漏洞，本项目不会自动继承修复 —— 
  请自行定期 `docker pull` 重建或按需升级。
- **本项目是第三方二次打包，不提供任何安全保证。**

### 报告问题

发现安全问题请开 issue（不要贴任何密钥或你的私有数据）。

---

## English

### The core fact: this build has **no login and no authentication**

`dist-slim` is a slim distribution: the panel (`8650`) authenticates nobody. Anyone who can
reach that port can open the full web panel, edit configuration, drive the AI agent to run
commands inside the container, and read/write your data volume.

**This is the intended scope of this build, not a bug** — it is a slim package meant for
single-machine / lab use. You decide whether to accept the risk; just know what you are
accepting.

### What the official installer defaults to (security-first)

| Default | Effect |
|---|---|
| Binds `127.0.0.1` only | Panel reachable from the local machine; container runs as non-root `hermes` (uid 10000) |
| `--cap-drop ALL` | Drops all Linux capabilities |
| `--security-opt no-new-privileges` | Blocks privilege escalation |
| `--pids-limit 2048` | Limits process count (fork-bomb mitigation) |
| Log rotation | `max-size=10m`, 3 files |
| SHA256 verification | Verifies the image archive before loading |

To use `--expose` (bind all interfaces), do item 1 first.

### If you make it reachable by others, at minimum

1. **Put an authenticating reverse proxy in front** (Nginx / Caddy + Basic Auth, or an SSO
   such as Authelia). Expose only the proxy, never the panel port directly.
2. **Use HTTPS.** Over plain HTTP the model API keys you enter travel in cleartext.
3. **Restrict source IPs** (firewall / proxy allowlist) instead of opening it to the world.
4. Don't co-locate this container with services that cannot tolerate compromise: the agent
   inside can execute commands (mitigated by `--cap-drop` and non-root, but still).

### Known limitations (honest list)

- **No login** — as above.
- **Port semantics**: the image also declares `8742` (messaging gateway) and `9219`
  (dashboard). The default installer does **not** map them. If you add `-p` yourself, note
  they have **no separate authentication** either.
- **The image embeds a fnOS layer** (`trim-cli` and other FeiNiu components) plus a large set
  of third-party Python/Node dependencies, shipped as-is from upstream. Their security
  posture is outside this project's control.
- **The image is based on upstream base images** (`debian:13-slim`, etc.). Known upstream
  CVEs are not automatically backported here — rebuild/upgrade as needed.
- **This is a third-party repackaging and comes with no security guarantee.**

### Reporting

Open an issue (do not paste secrets or private data).
