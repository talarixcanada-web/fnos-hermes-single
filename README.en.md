# Hermes Agent Single-Node Edition · Docker image (dist-slim 0.21.2)

**TL;DR** — A single-file Docker image of the *Hermes Agent* that ships inside the
fnOS (FeiNiu NAS OS) app store, so you can run it on any Linux host with one command.
It bundles the graphical WebUI, the built-in skill library and the multi-platform
messaging gateway.

> 中文说明见 [`README.md`](README.md)

---

## ⚠️ Read this first (security)

**This build has no login / no authentication** (dist-slim = slim distribution).
Once the panel port is reachable from your LAN or the Internet, **anyone can open the
panel and drive this AI agent to run commands on your machine**.

- The install script binds to `127.0.0.1` **by default** (local access only).
- To expose it, **put your own reverse proxy + HTTPS + auth in front** (Nginx / Caddy +
  Basic Auth / Authelia / …), then pass `--expose` explicitly.
- **Never** expose the panel port straight to the Internet.

See [`SECURITY.md`](SECURITY.md).

---

## What it is

| Field | Value |
|---|---|
| Image | `fnos-hermes:0.21.2-dist-slim` |
| Package | `fnos-hermes-dist-slim-0.21.2.tar.gz` (~811 MiB) |
| Core | Hermes Agent v0.21.2 ([NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent), MIT) |
| fnOS layer | derived from the fnOS app package v0.21.149, GPL-3.0 — see [`NOTICE.md`](NOTICE.md) |
| Panel port | `8650` (WebUI) |
| Other ports | `8742` (messaging gateway), `9219` (dashboard) |
| Volumes | `/data` (config / sessions / skills), `/var/hermes` (logs / runtime) |
| User | `hermes` (uid 10000, non-root) |

Bring it up, open the panel, enter **your own** model API key (and any messaging
platform credentials you want) and start chatting. **The image contains no secrets.**

---

## Install (one command)

Prerequisites: a Linux host (Ubuntu / Debian, …) with Docker.

```bash
# 1. Grab both files from this repository's Releases/root:
#      fnos-hermes-dist-slim-0.21.2.tar.gz
#      install-hermes-single-0.21.2.sh

# 2. Run the installer (binds 127.0.0.1 only — safest default)
sudo bash install-hermes-single-0.21.2.sh

# 3. Open the panel
#      http://127.0.0.1:8650/
```

The script verifies the SHA256 of the image archive, loads the image, creates the data
volumes, starts the container, waits for first boot and checks the panel returns HTTP 200.
It is **idempotent**: a pre-existing container is renamed aside as a rollback point.

Useful flags:

```bash
sudo bash install-hermes-single-0.21.2.sh --expose     # bind all interfaces (⚠️ no auth)
sudo bash install-hermes-single-0.21.2.sh --port 8650
sudo bash install-hermes-single-0.21.2.sh --pkg /path/fnos-hermes-dist-slim-0.21.2.tar.gz
```

---

## Manual install

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

Then open `http://127.0.0.1:8650/`.

> The first boot unpacks the pre-installed Python runtime into `/data/venv`
> (it is already in the image — no network needed). This takes ~30–90 s, during which
> the panel is unreachable.

---

## Requirements

- Linux x86_64 (amd64 image)
- Docker (19.03+; tested on Docker 29.x)
- Disk: ~811 MiB image + ~1 GiB unpacked runtime + your data
- RAM: 2 GiB recommended

---

## License & provenance

This repository is released under **GPL-3.0** (full text in [`LICENSE`](LICENSE)).

- **Hermes Agent core**: © Nous Research, MIT ([upstream](https://github.com/NousResearch/hermes-agent)).
- **fnOS layer** (`server/`, `ui/`, `config/`, …): from the fnOS app package v0.21.149, GPL-3.0.
- **Docker packaging in this repo** (Dockerfile, entrypoint, installer, docs): this project, GPL-3.0.

Corresponding source — including our modifications to the GPL components — is provided
in the [`source/`](source/) directory of this repository. Per-component notices:
[`NOTICE.md`](NOTICE.md).

---

## Disclaimer

This is a **third-party repackaging**. It is **not** an official release by Nous Research
and is not affiliated with Nous Research or FeiNiu (fnOS). The software is provided
"as is", without warranty of any kind. You are responsible for evaluating and accepting
the risks of running it — in particular the consequences of exposing the panel to a
network **without putting your own authentication in front of it**.
