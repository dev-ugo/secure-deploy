#!/bin/bash
set -euo pipefail

# macOS
if command -v brew &>/dev/null; then
  brew install mkcert nss
# Linux (Debian/Ubuntu)
elif command -v apt-get &>/dev/null; then
  apt-get install -y libnss3-tools
  curl -Lo mkcert https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v1.4.4-linux-amd64
  chmod +x mkcert && mv mkcert /usr/local/bin/
fi

mkcert -install

mkdir -p certs
mkcert -cert-file certs/local.crt -key-file certs/local.key \
  localhost \
  app.localhost \
  traefik.localhost

echo "Certificats générés dans ./certs"

docker network create proxy 2>/dev/null || echo "Le réseau proxy existe déjà"

if ! command -v htpasswd &>/dev/null; then
  apt-get install -y apache2-utils 2>/dev/null || brew install httpd
fi

echo ""
echo "Choisis un mot de passe pour le dashboard Traefik :"
read -s -p "Mot de passe : " PASS
echo ""

HASHED=$(htpasswd -nB admin <<< "$PASS" | sed -e 's/\$/\$\$/g')

cat > .env <<EOF
TRAEFIK_AUTH=$HASHED
EOF

echo ".env créé"

# ── 6. Structure des dossiers ─────────────────────────────────────────────────
mkdir -p traefik/dynamic

echo ""
echo "Tout est prêt. Lance la stack avec :"
echo "   docker compose up -d"
echo ""
echo "Accès :"
echo "   https://app.localhost       → service whoami"
echo "   https://traefik.localhost   → dashboard Traefik"