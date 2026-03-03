# Architecture SecureDeploy

## Vue d'ensemble

Ce projet met en place un environnement de développement local sécurisé utilisant **Traefik** comme reverse proxy avec support HTTPS natif. L'architecture est conteneurisée avec Docker et utilise des certificats SSL auto-signés reconnus par le système.

## Composants

### 1. Traefik (Reverse Proxy)

**Image**: `traefik:v3.2`

Traefik sert de point d'entrée unique pour toutes les applications. Il gère automatiquement:
- Le routage des requêtes vers les bons services
- La terminaison SSL/TLS
- La redirection automatique HTTP → HTTPS
- L'exposition d'un dashboard de monitoring

**Configuration clé**:
- **Ports exposés**: 80 (HTTP) et 443 (HTTPS)
- **Dashboard**: Accessible sur `https://traefik.localhost`
- **Authentification**: Protégé par Basic Auth (credentials dans `.env`)
- **Auto-discovery**: Détecte automatiquement les conteneurs Docker via labels

### 2. Application de démonstration

**Image**: `traefik/whoami`

Application simple qui affiche des informations sur la requête reçue. Sert de preuve de concept pour valider le fonctionnement du proxy.

**Accès**: `https://app.localhost`

### 3. Réseau Docker

Un réseau bridge externe nommé `proxy` permet la communication entre Traefik et les services qu'il expose.

### 4. Certificats SSL

Les certificats sont générés localement avec **mkcert** et stockés dans le dossier `certs/`:
- `local.crt` - Certificat
- `local.key` - Clé privée

Domaines couverts:
- `localhost`
- `app.localhost`
- `traefik.localhost`

Ces certificats sont reconnus comme valides par le navigateur car mkcert installe une autorité de certification locale.

## Sécurité

### Transport Layer Security (TLS)
- Tous les services sont accessibles uniquement via HTTPS
- Redirection automatique de HTTP vers HTTPS
- Certificats valides pour éviter les avertissements du navigateur

### En-têtes de sécurité
Middleware `secure-headers` configuré avec:
- `Strict-Transport-Security` (HSTS): Force HTTPS pour 1 an
- `X-Content-Type-Options`: Prévient le MIME sniffing
- `X-XSS-Protection`: Active la protection XSS du navigateur

### Authentification
Le dashboard Traefik est protégé par Basic Authentication (utilisateur: `admin`, mot de passe défini lors du setup).

## Flux de requête

```
Navigateur
    ↓
https://app.localhost
    ↓
Traefik (port 443)
    ↓
[Vérifie le Host header]
    ↓
[Applique les middlewares]
    ↓
Conteneur app (whoami)
    ↓
Réponse
```

## Structure des fichiers

```
.
├── docker-compose.yml          # Orchestration des services
├── setup-local.sh             # Script d'initialisation
├── .env                       # Variables d'environnement (credentials)
├── certs/                     # Certificats SSL locaux
│   ├── local.crt
│   └── local.key
└── traefik/
    └── dynamic/
        └── tls.yml            # Configuration TLS de Traefik
```

## Installation et démarrage

### Prérequis
- Docker et Docker Compose
- Bash (Linux/macOS/WSL sur Windows)

### Déploiement

1. **Initialisation**:
   ```bash
   chmod +x setup-local.sh
   ./setup-local.sh
   ```
   Ce script:
   - Installe mkcert
   - Génère les certificats SSL
   - Crée le réseau Docker
   - Configure l'authentification Traefik

2. **Lancement**:
   ```bash
   docker compose up -d
   ```

3. **Accès**:
   - Application: https://app.localhost
   - Dashboard Traefik: https://traefik.localhost

## Extensibilité

Pour ajouter un nouveau service:

1. Ajouter le service dans `docker-compose.yml`
2. Le connecter au réseau `proxy`
3. Configurer les labels Traefik:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.monservice.rule=Host(`monservice.localhost`)"
     - "traefik.http.routers.monservice.entrypoints=websecure"
     - "traefik.http.routers.monservice.tls=true"
   ```
4. Régénérer les certificats si besoin d'un nouveau domaine

## Points forts de l'architecture

✅ **Sécurisé par défaut**: HTTPS obligatoire sur tous les services  
✅ **Zéro configuration manuelle**: Discovery automatique des services  
✅ **Isolation**: Chaque service dans son conteneur  
✅ **Scalable**: Architecture prête pour héberger plusieurs applications  
✅ **Développement proche de la production**: Même stack que pour un déploiement réel  
✅ **Monitoring intégré**: Dashboard Traefik pour observer le trafic en temps réel

## Technologies utilisées

- **Docker Compose**: Orchestration des conteneurs
- **Traefik v3.2**: Reverse proxy et load balancer moderne
- **mkcert**: Génération de certificats SSL locaux valides
- **Whoami**: Application de test légère
