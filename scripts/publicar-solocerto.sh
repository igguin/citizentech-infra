#!/bin/bash
set -euo pipefail

APP_DIR="/home/citizenadmin/solocerto-app"
WEB_DIR="/var/www/solocerto"
LOG_DIR="/var/log/citizentech"
LOG_FILE="$LOG_DIR/publicacao.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "$(date) | Iniciando publicacao SoloCerto"

if [ ! -f "$APP_DIR/dist/index.html" ]; then
    echo "ERRO: Aplicacao web nao foi compilada."
    exit 1
fi

mkdir -p "$WEB_DIR"
cp -a "$APP_DIR/dist/." "$WEB_DIR/"

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
systemctl enable nginx
systemctl reload nginx

echo "$(date) | SoloCerto publicado com sucesso"
