#!/bin/bash
# ── 行尾自检（刻意放最前）：本文件若被 Windows 换成 CRLF，bash 会在 set -euo pipefail 那行
#    报 `set: pipefail: invalid option name`、看不清根因。末尾注释是必需的。
head -c 400 "$0" | LC_ALL=C grep -q $'\r' && { echo "✗ 本安装脚本带 Windows 行尾(CRLF)。先执行：  sed -i 's/\r$//' \"$0\"   然后重跑。"; exit 1; } # ← 末尾注释必需
# ============================================================================
# fnOS Hermes 单机版（dist-slim 0.21.2）一键安装 —— Linux + Docker
#   镜像：fnos-hermes:0.21.2-dist-slim
#   包：  fnos-hermes-dist-slim-0.21.2.tar.gz
#
# ⚠️ 安全提示（务必先读 README）：本版本【不含登录/鉴权】，
#    8650 面板一旦对外可达 = 任何人都能打开面板并驱动这个 agent。
#    默认只监听 127.0.0.1（仅本机可访问）。要让局域网/公网访问，
#    必须自己加一层反向代理 + 认证，并显式加 --expose。
#
# 用法：
#   sudo bash install-hermes-single-0.21.2.sh                 # 只绑本机 127.0.0.1
#   sudo bash install-hermes-single-0.21.2.sh --expose        # 绑所有网卡（风险自负）
#   sudo bash install-hermes-single-0.21.2.sh --port 8650     # 改本机端口
#   sudo bash install-hermes-single-0.21.2.sh --pkg /path/fnos-hermes-dist-slim-0.21.2.tar.gz
#   sudo bash install-hermes-single-0.21.2.sh --name hermes2 --port 18650   # 并存第二个实例
#
# 幂等：重复执行会把旧容器改名保留（回滚点），数据卷不动。
# ============================================================================
set -euo pipefail

PKG_DEFAULT="fnos-hermes-dist-slim-0.21.2.tar.gz"
IMG="fnos-hermes:0.21.2-dist-slim"
NAME="hermes"
DATA_VOL="hermes-data"
VAR_VOL="hermes-var"
PORT=8650
BIND="127.0.0.1"
EXPECT_SHA="456e9264c3267ec22f1c8cb3f91dafc052f2cf5d469e274e3d94c00d473a98c5"

while [ $# -gt 0 ]; do
  case "$1" in
    --expose) BIND="0.0.0.0"; shift;;
    --port) PORT="$2"; shift 2;;
    --pkg) PKG_DEFAULT="$2"; shift 2;;
    --name) NAME="$2"; shift 2;;
    --sha) EXPECT_SHA="$2"; shift 2;;
    -h|--help) sed -n '2,25p' "$0"; exit 0;;
    *) echo "未知参数：$1"; exit 2;;
  esac
done

say() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

say "0/6 环境预检"
command -v docker >/dev/null 2>&1 || { echo "✗ 没装 Docker。Ubuntu/Debian: sudo apt install docker.io ；或按官方文档装 docker-ce。"; exit 1; }
docker info >/dev/null 2>&1 || { echo "✗ 当前用户连不上 Docker（试试 sudo，或把用户加入 docker 组后重新登录）。"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
PKG="$PKG_DEFAULT"
[ -f "$PKG" ] || PKG="$HERE/$PKG_DEFAULT"
[ -f "$PKG" ] || { echo "✗ 找不到安装包 $PKG_DEFAULT（请与脚本放同一目录，或用 --pkg 指定路径）。"; exit 1; }
echo "✓ Docker $(docker --version | awk '{print $3}')／安装包 $(basename "$PKG") $(stat -c %s "$PKG") 字节"

say "1/6 校验安装包（损坏的包一定装不上，先拦下）"
gzip -t "$PKG" && echo "  ✓ 压缩流完整"
echo -n "  实际 SHA256："; ACTUAL="$(sha256sum "$PKG" | awk '{print $1}')"; echo "$ACTUAL"
if [ -n "$EXPECT_SHA" ]; then
  if [ "$ACTUAL" = "$EXPECT_SHA" ]; then
    echo "  ✓ 与预期一致"
  else
    echo "✗ SHA256 不匹配：预期 $EXPECT_SHA"
    echo "  实际 $ACTUAL —— 包可能损坏或被篡改，已停止。"
    exit 1
  fi
else
  echo "  （未提供预期值；请自行与 Release 页面公布的 SHA256 比对）"
fi

say "2/6 导入镜像"
docker load -i "$PKG" | tail -2
docker image inspect "$IMG" >/dev/null || { echo "✗ 导入后找不到 $IMG"; exit 1; }
echo "  ✓ 镜像就绪：$IMG（$(docker image inspect -f '{{.Size}}' "$IMG" | awk '{printf "%.2f GB", $1/1024/1024/1024}')）"

say "3/6 处理同名旧容器（改名保留 = 回滚点，数据卷不动）"
if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  BAK="$NAME-old-$(date +%Y%m%d-%H%M%S)"
  docker stop "$NAME" >/dev/null 2>&1 || true
  docker rename "$NAME" "$BAK"
  echo "  旧容器已改名为 $BAK（回滚：docker rm -f $NAME && docker rename $BAK $NAME && docker start $NAME）"
else
  echo "  无同名容器"
fi

say "4/6 建数据卷并启动"
docker volume create "$DATA_VOL" >/dev/null
docker volume create "$VAR_VOL"  >/dev/null
docker run -d --name "$NAME" --restart unless-stopped \
  -p "$BIND:$PORT:8650" \
  -v "$DATA_VOL:/data" -v "$VAR_VOL:/var/hermes" \
  -e TZ="$(cat /etc/timezone 2>/dev/null || echo UTC)" \
  -e DATA_DIR=/data -e VAR_DIR=/var/hermes -e APP_DIR=/opt/hermes \
  -e UI_PORT=8650 -e GATEWAY_PORT=8742 -e DASHBOARD_PORT=9219 \
  -e PYTHONDONTWRITEBYTECODE=1 -e PYTHONUNBUFFERED=1 \
  --cap-drop ALL --security-opt no-new-privileges --pids-limit 2048 \
  --log-opt max-size=10m --log-opt max-file=3 \
  "$IMG" >/dev/null
echo "  ✓ 容器已创建（面板端口绑定 $BIND:$PORT → 容器 8650）"

say "5/6 等首启完成（首次要展开运行环境，30–90 秒）"
for i in $(seq 1 40); do
  st="$(docker inspect -f '{{.State.Status}}' "$NAME" 2>/dev/null || echo missing)"
  [ "$st" = "missing" ] && { echo "✗ 容器没了，看 docker logs $NAME"; exit 1; }
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)"
  [ "$code" = "200" ] && break
  printf '  等待中… status=%s http=%s（%ds）\n' "$st" "${code:-无}" $((i*5)); sleep 5
done

say "6/6 验收"
code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)"
printf '  面板 HTTP 状态：%s（期望 200）\n' "${code:-无}"
docker logs "$NAME" 2>&1 | tail -5 | sed 's/^/  /'

HOSTIP="$(hostname -I 2>/dev/null | awk '{print $1}')"
cat <<EOF

────────────────────────────────────────────────────────────
安装完成。
  面板地址（仅本机）：http://127.0.0.1:$PORT/
$( [ "$BIND" = "0.0.0.0" ] && echo "  面板地址（局域网）：http://${HOSTIP:-<本机IP>}:$PORT/   ⚠️ 无鉴权，风险自负" )
  数据卷：docker volume inspect $DATA_VOL

⚠️ 安全须知（本版本无登录/鉴权）：
  1. 端口默认只绑 127.0.0.1。要对外，请自己在前面加反向代理 + HTTPS + 认证。
  2. 不要把这个端口直接暴露到公网。
  3. 进面板后第一件事：在「模型」页填你自己的模型 API Key（不填面板能开，但对话不可用）。

常用运维：
  看日志   docker logs $NAME --tail 100
  重启     docker restart $NAME
  停止     docker stop $NAME
回滚：docker rm -f $NAME && docker rename ${NAME}-old-* $NAME && docker start $NAME
────────────────────────────────────────────────────────────
EOF
