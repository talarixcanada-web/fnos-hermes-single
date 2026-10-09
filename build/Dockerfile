# syntax=docker/dockerfile:1
# =============================================================================
# fnOS Hermes Agent (fpk v0.21.149 内核 v0.21.2(tag v2026.9.11, 官方 hermes-src)) → 通用 Docker 镜像
# 克隆自飞牛 fnOS 应用包 fnos-hermes-agent_v0.21.149.fpk
# 保留: Web UI / 专家市场 / 全部预制 skills / multiplex 多 profile / monitor.js
#
# 布局:
#   /opt/hermes   APP_DIR  只读代码(hermes-src/server/ui/config/bin + manifest)
#   /data         DATA_DIR 数据卷(可 bind-mount / 命名卷) 首次启动自动 seed
#   /var/hermes   VAR_DIR  运行时(日志/pid/token)
#   /opt/venv-seed         预装 venv(镜像层), 首启无 /data/venv 时复制
# =============================================================================

# ---- 阶段 1: uv(含 python3.13) ----
FROM ghcr.io/astral-sh/uv:0.11.6-python3.13-trixie AS uv_source

# ---- 阶段 2: node 26 ----
FROM node:26-bookworm-slim AS node_source

# ---- 阶段 3: 运行时 ----
FROM debian:13-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PLAYWRIGHT_BROWSERS_PATH=/opt/hermes/.playwright

# 系统依赖(官方 Dockerfile 同款 + python3 + unzip)
RUN apt-get -o Acquire::Retries=3 update && \
    apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
        ca-certificates curl iputils-ping python3 python-is-python3 ripgrep \
        ffmpeg gcc g++ make cmake python3-dev python3-venv libffi-dev \
        libatomic1 procps git openssh-client xz-utils unzip && \
    rm -rf /var/lib/apt/lists/*

# uv + node
COPY --from=uv_source  /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/
COPY --from=node_source /usr/local/bin/node /usr/local/bin/
COPY --from=node_source /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN chmod 0755 /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/node && \
    ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# 飞牛增值层布局: 代码 → /opt/hermes
WORKDIR /opt/hermes
COPY . .

# ── Python venv 预装到 /opt/venv-seed(镜像层, seed 用) ──
# [all] 内核必需; +messaging 预装 telegram/discord/slack 使容器离线可绑 bot
RUN uv venv /opt/venv-seed --python /usr/bin/python3 && \
    uv pip install --python /opt/venv-seed/bin/python3 \
        -e "/opt/hermes/hermes-src[all,messaging]" && \
    ln -sf /usr/local/bin/uv /opt/venv-seed/bin/uv && \
    chmod +x /opt/hermes/bin/hermes /opt/hermes/bin/monitor-api /opt/hermes/docker-entrypoint.sh

# ── 预构建 dashboard Web UI(vite outDir=../hermes_cli/web_dist)──
# 官方源码发行不带 web_dist; monitor.js 检测到 web_dist 才设 HERMES_WEB_DIST
# 直接 serve 静态产物, 否则 dashboard 触发 npm build(容器内只读失败)
# node_modules 用完即删, 控制镜像体积
WORKDIR /opt/hermes/hermes-src/web
RUN npm install --no-audit --no-fund && \
    npm run build && \
    rm -rf /opt/hermes/hermes-src/web/node_modules

# ── REVERSE-PROXY-SAFE BASE GUARD ─────────────────────────────────
# vite 产物必须用相对引用 ./assets/*（vite.config.ts base: "./"）。
# 若回归成绝对 /assets/*，在反代子路径（/proxy/dashboard/）下懒加载
# chunk 会 404 → dashboard 白屏；此处直接 fail build，杜绝静默回归。
RUN IDX=/opt/hermes/hermes-src/hermes_cli/web_dist/index.html; \
    if grep -qE '(src|href)="/assets/' "$IDX"; then \
        echo "FATAL: web_dist/index.html uses absolute /assets/* -- vite base is not './' (reverse-proxy blank-page bug)"; \
        exit 1; \
    fi; \
    grep -qE '(src|href)="\./assets/' "$IDX" || { \
        echo "FATAL: web_dist/index.html has no ./assets/* references -- unexpected build output"; \
        exit 1; \
    }; \
    echo "OK: web_dist uses relative ./assets/* -- reverse-proxy safe"; \
    grep -oE '(src|href)="\./assets/[^"]*"' "$IDX" | head -4

#
# ── 预构建 TUI: 嵌入式 /chat 终端(PTY WebSocket)─────────────────
# dashboard 的 /chat 需要 hermes_cli/tui_dist/entry.js。自带该预构建包,
# `_make_tui_argv()` 就直接 node 跑 bundle; 缺失则回退运行期 npm install,
# 而此时进程是 hermes(uid 10000)、/opt/hermes 属 root → EACCES
# → 聊天页出现红色 "Chat unavailable: 1"(SystemExit(1))。
# node_modules 用完即删, 只保留 3.6MB 的 entry.js。
RUN cd /opt/hermes/hermes-src && \
    npm install --workspace ui-tui --no-audit --no-fund && \
    cd ui-tui && npm run build && \
    rm -rf /opt/hermes/hermes-src/hermes_cli/tui_dist && \
    cp -r dist /opt/hermes/hermes-src/hermes_cli/tui_dist && \
    cd /opt/hermes/hermes-src && \
    rm -rf node_modules ui-tui/node_modules ui-tui/packages/hermes-ink/node_modules

# ── TUI BUNDLE GUARD ─────────────────────────────────────────────
RUN TUI=/opt/hermes/hermes-src/hermes_cli/tui_dist/entry.js; \
    test -f "$TUI" || { \
        echo "FATAL: prebuilt TUI bundle missing -- dashboard /chat would show 'Chat unavailable'"; \
        exit 1; \
    }; \
    echo "OK: prebuilt TUI present -- $(du -h "$TUI" | cut -f1)"

WORKDIR /opt/hermes

# 运行用户 + 数据骨架
RUN useradd -u 10000 -m -d /data hermes && \
    mkdir -p /data /var/hermes && \
    chown -R hermes:hermes /data /var/hermes && \
    chmod 755 /opt/hermes

# 时区固化: America/Toronto(与宿主机一致, 非 fnOS 默认 Asia/Shanghai)
# /etc/localtime 软链需 root 设置(USER hermes 之前); TZ env 供 Python/Node 读取
RUN ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime && \
    echo "America/Toronto" > /etc/timezone

USER hermes
WORKDIR /data

ENV TZ=America/Toronto \
    APP_DIR=/opt/hermes \
    DATA_DIR=/data \
    VAR_DIR=/var/hermes \
    HERMES_HOME=/data \
    TRIM_APPDEST=/opt/hermes \
    TRIM_PKGHOME=/data \
    TRIM_PKGVAR=/var/hermes \
    UI_PORT=8650 \
    GATEWAY_PORT=8742 \
    DASHBOARD_PORT=9219

EXPOSE 8650 8742 9219

ENTRYPOINT ["/opt/hermes/docker-entrypoint.sh"]
