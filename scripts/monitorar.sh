#!/bin/bash
set -euo pipefail

LOG_DIR="/var/log/citizentech"
LOG_FILE="$LOG_DIR/monitoramento.log"

CPU_LIMIT=${CPU_LIMIT:-80}
RAM_LIMIT=${RAM_LIMIT:-85}
DISK_LIMIT=${DISK_LIMIT:-90}

mkdir -p "$LOG_DIR"

registrar() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

ler_cpu() {
    awk '/^cpu / {
        total = 0
        for (i = 2; i <= NF; i++) total += $i
        print $5 + $6, total
        exit
    }' /proc/stat
}

read -r idle1 total1 < <(ler_cpu)
sleep 1
read -r idle2 total2 < <(ler_cpu)

CPU=$(awk -v i1="$idle1" -v i2="$idle2" \
    -v t1="$total1" -v t2="$total2" \
    'BEGIN {
        if (t2 > t1)
            printf "%.0f", 100 * (1 - (i2-i1)/(t2-t1))
        else
            print 0
    }')

RAM=$(LC_ALL=C free | awk '/^Mem:/ {
    printf "%.0f", 100 * ($2-$7)/$2
}')

DISK=$(df -P / | awk 'NR==2 {
    gsub("%", "", $5)
    print $5
}')

registrar "CPU: ${CPU}% | RAM: ${RAM}% | DISCO: ${DISK}%"

if (( CPU > CPU_LIMIT )); then
    registrar "ALERTA: CPU acima do limite!"
fi

if (( RAM > RAM_LIMIT )); then
    registrar "ALERTA: Memoria RAM acima do limite!"
fi

if (( DISK > DISK_LIMIT )); then
    registrar "ALERTA: Disco acima do limite!"
fi

registrar "Monitoramento concluido."
