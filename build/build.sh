#!/bin/bash
# =============================================================================
# build.sh — 构建 fnos-hermes:0.21.2-dist-slim
#
# 上下文要求（与镜像内 /opt/hermes 一致）：
#   <ctx>/                ← 本仓库 source/opt-hermes/ 的内容（server ui config bin manifest ...）
#   <ctx>/hermes-src/     ← NousResearch/hermes-agent v0.21.2 源码（MIT，需自行从上游获取）
#
# 用法：
#   bash build.sh <构建上下文目录> [镜像tag]
# =============================================================================
set -euo pipefail
CTX="${1:?用法: bash build.sh <构建上下文目录> [镜像tag]}"
TAG="${2:-fnos-hermes:0.21.2-dist-slim}"
HERE="$(cd "$(dirname "$0")" && pwd)"

[ -d "$CTX/hermes-src" ] || { echo "✗ 缺少 $CTX/hermes-src（Nous 内核源码，见 README.md 前置）"; exit 1; }
[ -f "$CTX/docker-entrypoint.sh" ] || { echo "✗ 缺少 $CTX/docker-entrypoint.sh（应从 source/opt-hermes/ 复制）"; exit 1; }

echo "== 校验：Dockerfile 与镜像内副本是否一致 =="
diff -q "$HERE/Dockerfile" "$CTX/Dockerfile" && echo "  ✓ Dockerfile 一致"
diff -q "$HERE/docker-entrypoint.sh" "$CTX/docker-entrypoint.sh" && echo "  ✓ entrypoint 一致"

echo "== 构建 $TAG =="
docker build -f "$HERE/Dockerfile" -t "$TAG" "$CTX"

echo "== 导出单文件包 =="
docker save "$TAG" | gzip -9 > "fnos-hermes-dist-slim-$(basename "$TAG" | cut -d: -f2).tar.gz"
sha256sum fnos-hermes-dist-slim-*.tar.gz
echo "✓ 完成"
