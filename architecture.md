# SecureDeploy Architecture

## Overview

This project sets up a secure local development environment using **Traefik** as a reverse proxy with native HTTPS support. The architecture is containerized with Docker and uses self-signed SSL certificates trusted by the system.

## Components

### 1. Traefik (Reverse Proxy)

**Image**: `traefik:v3.2`

Traefik serves as the single entry point for all applications. It automatically handles:
- Routing requests to the appropriate services
- SSL/TLS termination
- Automatic HTTP → HTTPS redirection
- Monitoring dashboard exposure

**Key configuration**:
- **Exposed ports**: 80 (HTTP) and 443 (HTTPS)
- **Dashboard**: Accessible at `https://traefik.localhost`
- **Authentication**: Protected by Basic Auth (credentials in `.env`)
- **Auto-discovery**: Automatically detects Docker containers via labels

### 2. Demo Application

**Image**: `traefik/whoami`

Simple application that displays information about the received request. Serves as a proof of concept to validate proxy functionality.

**Access**: `https://app.localhost`

### 3. Docker Network

An external bridge network named `proxy` enables communication between Traefik and the services it exposes.

### 4. SSL Certificates

Certificates are generated locally with **mkcert** and stored in the `certs/` folder:
- `local.crt` - Certificate
- `local.key` - Private key

Covered domains:
- `localhost`
- `app.localhost`
- `traefik.localhost`

These certificates are recognized as valid by the browser because mkcert installs a local certificate authority.

## Security

### Transport Layer Security (TLS)
- All services are accessible only via HTTPS
- Automatic HTTP to HTTPS redirection
- Valid certificates to avoid browser warnings

### Security Headers
`secure-headers` middleware configured with:
- `Strict-Transport-Security` (HSTS): Enforces HTTPS for 1 year
- `X-Content-Type-Options`: Prevents MIME sniffing
- `X-XSS-Protection`: Enables browser XSS protection

### Authentication
The Traefik dashboard is protected by Basic Authentication (user: `admin`, password set during setup).

## Request Flow

```
Browser
    ↓
https://app.localhost
    ↓
Traefik (port 443)
    ↓
[Checks Host header]
    ↓
[Applies middlewares]
    ↓
App container (whoami)
    ↓
Response
```

## File Structure

```
.
├── docker-compose.yml          # Service orchestration
├── setup-local.sh             # Initialization script
├── .env                       # Environment variables (credentials)
├── certs/                     # Local SSL certificates
│   ├── local.crt
│   └── local.key
└── traefik/
    └── dynamic/
        └── tls.yml            # Traefik TLS configuration
```

## Installation and Startup

### Prerequisites
- Docker and Docker Compose
- Bash (Linux/macOS/WSL on Windows)

### Deployment

1. **Initialization**:
   ```bash
   chmod +x setup-local.sh
   ./setup-local.sh
   ```
   This script:
   - Installs mkcert
   - Generates SSL certificates
   - Creates Docker network
   - Configures Traefik authentication

2. **Startup**:
   ```bash
   docker compose up -d
   ```

3. **Access**:
   - Application: https://app.localhost
   - Traefik Dashboard: https://traefik.localhost

## Extensibility

To add a new service:

1. Add the service in `docker-compose.yml`
2. Connect it to the `proxy` network
3. Configure Traefik labels:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.myservice.rule=Host(`myservice.localhost`)"
     - "traefik.http.routers.myservice.entrypoints=websecure"
     - "traefik.http.routers.myservice.tls=true"
   ```
4. Regenerate certificates if a new domain is needed

## Architecture Strengths

**Secure by default**: HTTPS mandatory on all services  
**Zero manual configuration**: Automatic service discovery  
**Isolation**: Each service in its own container  
**Scalable**: Architecture ready to host multiple applications  
**Production-like development**: Same stack as for real deployment  
**Integrated monitoring**: Traefik dashboard to observe traffic in real-time

## Technologies Used

- **Docker Compose**: Container orchestration
- **Traefik v3.2**: Modern reverse proxy and load balancer
- **mkcert**: Valid local SSL certificate generation
- **Whoami**: Lightweight test application
