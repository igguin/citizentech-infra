#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERRO: execute com sudo bash scripts/provisionar.sh"
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/aplicacao"
WEB_DIR="/var/www/solocerto"
LOG_DIR="/var/log/citizentech"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/provisionamento.log") 2>&1

trap 'echo "$(date -Is) | ERRO na linha $LINENO: $BASH_COMMAND"' ERR

echo "$(date -Is) | Iniciando provisionamento"

if [[ ! -f "$APP_DIR/package-lock.json" ]]; then
    echo "ERRO: codigo-fonte do SoloCerto nao encontrado."
    exit 1
fi

# Configurar hostname
hostnamectl set-hostname citizentech-server

if ! grep -Eq '(^|[[:space:]])citizentech-server([[:space:]]|$)' /etc/hosts; then
    echo "127.0.1.1 citizentech-server" >> /etc/hosts
fi

# Verificar rede e DNS
echo "Verificando configuracao de rede..."
ip -4 -brief address
ip -4 route

getent ahostsv4 deb.debian.org > /dev/null || {
    echo "ERRO: resolucao DNS indisponivel."
    exit 1
}

echo "DNS funcionando."

# Instalar dependencias
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
    curl ca-certificates gnupg git \
    openssh-server nginx rsync python3

# Instalar Node.js 24 quando necessario
if ! command -v node >/dev/null 2>&1 || [[ "$(node --version)" != v24.* ]]; then
    curl -fsSL https://deb.nodesource.com/setup_24.x \
        -o /tmp/nodesource_setup.sh
    bash /tmp/nodesource_setup.sh
    apt-get install -y nodejs
fi

echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"

# Compilar aplicacao web
cd "$APP_DIR"

npm ci --no-audit --no-fund
npx expo export --platform web

test -f "$APP_DIR/dist/index.html"

# Publicar no Nginx
mkdir -p "$WEB_DIR"

rsync -a --delete "$APP_DIR/dist/" "$WEB_DIR/"

chown -R root:root "$WEB_DIR"
chmod -R a+rX "$WEB_DIR"

cat > /etc/nginx/sites-available/solocerto <<'NGINX'
server {
    listen 80 default_server;
    server_name _;

    root /var/www/solocerto;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINX

ln -sfn /etc/nginx/sites-available/solocerto \
    /etc/nginx/sites-enabled/solocerto

rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable --now nginx
systemctl reload nginx

# Configurar monitoramento systemd
chmod +x "$ROOT_DIR/scripts/monitorar.sh"

sed "s#/home/citizenadmin/citizentech-infra#$ROOT_DIR#g" \
    "$ROOT_DIR/services/citizentech-monitor.service" \
    > /etc/systemd/system/citizentech-monitor.service

systemctl daemon-reload
systemctl enable --now citizentech-monitor.service
systemctl restart citizentech-monitor.service

# Garantir acesso SSH
systemctl enable --now ssh

# Testes automaticos
curl -fsS http://127.0.0.1/ > /dev/null
systemctl is-active --quiet nginx
systemctl is-active --quiet citizentech-monitor.service

echo "$(date -Is) | SUCESSO: Infraestrutura preparada!"
