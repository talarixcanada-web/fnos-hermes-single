# 构建说明 / Build notes

本目录记录 `fnos-hermes:0.21.2-dist-slim` 镜像的构建方式 ——
即 GPL-3.0 意义上的「用于控制编译与安装的脚本」。

## 文件

| 文件 | 说明 |
|---|---|
| `Dockerfile` | 构建定义（与镜像内 `/opt/hermes/Dockerfile` 一致） |
| `docker-entrypoint.sh` | 容器入口（与镜像内 `/opt/hermes/docker-entrypoint.sh` 一致） |
| `build.sh` | 组装构建上下文并执行构建 |

## 前置

1. **Nous 内核源码**（MIT）：把上游 `NousResearch/hermes-agent` 的 v0.21.2 内容
   放到构建上下文的 `hermes-src/` 目录（即镜像内 `/opt/hermes/hermes-src`）。
2. **fnOS 增值层源码**（GPL-3.0）：即本仓库 `source/opt-hermes/` 的内容，放在构建上下文根。

## 构建

```bash
# 组装上下文：<ctx>/ = source/opt-hermes/ 的内容 + hermes-src/
# 然后：
docker build -f build/Dockerfile -t fnos-hermes:0.21.2-dist-slim .

# 导出为单文件 tar.gz（与 Release 资产同格式）
docker save fnos-hermes:0.21.2-dist-slim | gzip -9 > fnos-hermes-dist-slim-0.21.2.tar.gz
```

## 说明

- Dockerfile 里的 `RUN` 守卫（vite `base` 相对路径检查、TUI 预构建包检查）是**刻意**设置的
  构建期断言：不满足即 fail build，避免产出反代下白屏/「Chat unavailable」的镜像。
- 构建期会联网（apt / npm / PyPI），需要能访问公网。
- 构建产物与 Release 资产**不是逐字节可复现的**（apt/PyPI 上游会变），
  请以 `SHA256SUMS` 里公布的哈希为准校验你下载到的包。
