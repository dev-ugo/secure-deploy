# SecureDeploy

Local deployment infrastructure with integrated security in the CI/CD pipeline.

## Overview

```
git push
    │
    ├── lint      → YAML and docker-compose validation
    ├── build     → Multi-stage Docker image (~8MB) pushed to ghcr.io
    └── scan      → Trivy blocks deployment if critical or high CVE detected
```

```
Browser
    │ HTTPS
    ▼
 Traefik  (reverse proxy, TLS, security headers)
    │
    ├── app.localhost       → Go application
    └── traefik.localhost   → dashboard (auth required)
```

## Stack

| Role | Tool |
|---|---|
| Reverse proxy | Traefik v3 |
| CI/CD | GitHub Actions |
| Registry | GitHub Container Registry (ghcr.io) |
| Security scan | Trivy |
| Runtime | Docker + Docker Compose |
| Language | Go 1.24 |

## Technical choices

**`FROM scratch`** — The final image contains only the statically compiled binary. No OS, no shell, no package manager. Minimal attack surface, ~8MB image.

**Shift-left security** — Trivy scan runs in the pipeline before any deployment. If a critical or high CVE is detected, the pipeline stops. The code doesn't ship.

**TLS everywhere** — Traefik forces HTTP → HTTPS redirection and injects security headers (HSTS, X-Content-Type-Options, X-XSS-Protection) on all services without touching application code.

## Run locally

### Prerequisites
- Docker + Docker Compose
- mkcert
- Git Bash (Windows) or Unix terminal

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USER/secure-deploy
cd secure-deploy

# 2. Generate certificates and configure environment
./setup-local.sh

# 3. Start the stack
docker compose up -d
```

### Access

| URL | Service |
|---|---|
| https://app.localhost/health | Application |
| https://traefik.localhost | Traefik Dashboard |

## CI/CD Pipeline

The pipeline triggers on every push to `main` and every pull request.

```
lint → build → scan
```

- **lint** — Validates YAML files (docker-compose, Traefik, workflow)
- **build** — Compiles Go binary, builds multi-stage image, pushes to ghcr.io
- **scan** — Trivy analyzes the image against known CVE database. Exit code 1 if CRITICAL or HIGH detected

### Real-world blocking example

During development, the image built with `golang:1.23` contained several CVEs in the Go stdlib (including a critical one in `crypto/tls`). The pipeline blocked deployment. Fix: upgrade to `golang:1.24`.

## Project structure

```
secure-deploy/
├── .github/
│   └── workflows/
│       └── ci.yml          # CI/CD pipeline
├── cmd/
│   └── server/
│       └── main.go         # Go application
├── traefik/
│   └── dynamic/
│       └── tls.yml         # Local certificates config
├── docker-compose.yml
├── Dockerfile               # Multi-stage build
├── setup-local.sh           # Local setup script
└── .env.example
```

## What's not here (and why)

This project is intentionally focused on the pipeline and infrastructure. Natural extensions would be:

- **Vault** (HashiCorp) — secret management rather than environment variables
- **Prometheus + Grafana** — observability and alerting