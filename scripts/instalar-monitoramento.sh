#!/bin/bash
set -euo pipefail

cd /home/citizenadmin/citizentech-infra

mkdir -p /var/log/citizentech

exec > >(tee -a /var/log/citizentech/instalacao.log) 2>&1

echo "$(date) | Iniciando instalacao do monitoramento"

install -m 644 services/citizentech-monitor.service \
    /etc/systemd/system/citizentech-monitor.service

chmod +x scripts/monitorar.sh

systemctl daemon-reload
systemctl enable --now citizentech-monitor.service

echo "$(date) | Servico instalado e iniciado com sucesso"
