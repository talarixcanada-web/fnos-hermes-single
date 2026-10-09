#!/bin/bash
# =============================================================================
# docker-entrypoint.sh — fnOS Hermes 容器启动入口
# 等价 fnOS cmd/main start_process: 初始化目录 → 启动 monitor.js (unix socket)
# 数据在 /data (DATA_DIR) 持久卷; 代码在 /opt/hermes (APP_DIR) 只读
# =============================================================================
set -e

APP_DIR="${APP_DIR:-/opt/hermes}"
DATA_DIR="${DATA_DIR:-/data}"
VAR_DIR="${VAR_DIR:-/var/hermes}"
LOG_FILE="${VAR_DIR}/hermes.log"
SOCKET_PATH="${MONITOR_SOCKET_PATH:-${VAR_DIR}/hermes-agent.sock}"
PROMPTS_SRC="${APP_DIR}/config/prompts"
SEED_VENV="/opt/venv-seed"

log_msg() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"; }

mkdir -p "${DATA_DIR}" "${VAR_DIR}"

# ── venv seed: /data/venv 缺失时从镜像层复制(硬链接优先, 跨fs回退全复制) ──
if [ ! -x "${DATA_DIR}/venv/bin/hermes" ]; then
    if [ -d "${SEED_VENV}/bin" ]; then
        log_msg "Seeding venv from ${SEED_VENV} ..."
        mkdir -p "${DATA_DIR}"
        rm -rf "${DATA_DIR}/venv"
        mkdir -p "${DATA_DIR}/venv"
        # cp -al 跨文件系统(/opt 镜像层 -> /data 卷)会 EXDEV 失败且已建空目标;
        # 用 src/. dst/ 内容复制避免嵌套成 /data/venv/venv-seed/
        if cp -al "${SEED_VENV}/." "${DATA_DIR}/venv/" 2>/dev/null; then
            log_msg "venv seeded (hardlink)"
        else
            rm -rf "${DATA_DIR}/venv"
            mkdir -p "${DATA_DIR}/venv"
            cp -a "${SEED_VENV}/." "${DATA_DIR}/venv/"
            log_msg "venv seeded (full copy)"
        fi
    else
        log_msg "ERROR: no seed venv at ${SEED_VENV}, cannot start"
        exit 1
    fi
fi

# ── 部署 prompts: skills 始终覆盖(跟随版本, 同 fnOS upgrade_callback);
#    SOUL/AGENTS/config.yaml 缺失才复制(用户定制保留) ──
if [ -d "${PROMPTS_SRC}" ]; then
    if [ -d "${PROMPTS_SRC}/skills" ]; then
        mkdir -p "${DATA_DIR}/skills"
        cp -a "${PROMPTS_SRC}/skills/." "${DATA_DIR}/skills/"
        log_msg "skills deployed (overlay)"
    fi
    for f in SOUL.md AGENTS.md; do
        if [ -f "${PROMPTS_SRC}/${f}" ] && [ ! -f "${DATA_DIR}/${f}" ]; then
            cp "${PROMPTS_SRC}/${f}" "${DATA_DIR}/${f}"
            log_msg "${f} deployed (first boot)"
        fi
    done
    if [ -f "${PROMPTS_SRC}/config.yaml" ] && [ ! -f "${DATA_DIR}/config.yaml" ]; then
        cp "${PROMPTS_SRC}/config.yaml" "${DATA_DIR}/config.yaml"
        log_msg "config.yaml deployed (first boot)"
    fi
fi

# ── 确保运行用户对数据目录可写 ──
if command -v chown >/dev/null 2>&1 && [ "$(id -u)" = "0" ]; then
    chown -R hermes:hermes "${DATA_DIR}" "${VAR_DIR}" 2>/dev/null || true
fi

# ── 清理旧 socket, 启动 monitor.js ──
rm -f "${SOCKET_PATH}"
mkdir -p "$(dirname "${SOCKET_PATH}")"

log_msg "Starting Hermes Agent monitor (socket=${SOCKET_PATH}) ..."

export HOME="${DATA_DIR}"
export HERMES_HOME="${DATA_DIR}"

# monitor.js 环境: 与 fnOS cmd/main 一致 + 容器路径(BASE_PATH 留空=直连)
exec env \
    HOME="${DATA_DIR}" \
    HERMES_HOME="${DATA_DIR}" \
    APP_DIR="${APP_DIR}" \
    DATA_DIR="${DATA_DIR}" \
    VAR_DIR="${VAR_DIR}" \
    MONITOR_SOCKET_PATH="${SOCKET_PATH}" \
    BASE_PATH="" \
    UI_PORT="${UI_PORT:-8650}" \
    GATEWAY_PORT="${GATEWAY_PORT:-8742}" \
    DASHBOARD_PORT="${DASHBOARD_PORT:-9219}" \
    PATH="${DATA_DIR}/venv/bin:/usr/local/bin:/usr/bin:/bin" \
    node "${APP_DIR}/server/monitor.js" >> "${LOG_FILE}" 2>&1
