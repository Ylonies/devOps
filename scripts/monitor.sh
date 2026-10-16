#!/bin/bash
# monitor.sh - проверка сервиса и подсчёт ошибок за последний час
# Использование: ./monitor.sh <имя_сервиса>

if [ -z "$1" ]; then
    echo "Использование: $0 <имя_сервиса>"
    echo "Пример: $0 docker"
    exit 1
fi

SERVICE_NAME="$1"
OS=$(uname -s)
STATUS_CODE=0

# ---------------------------------------------------------------
# macOS (launchd)
# ---------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
    echo "=== Проверка сервиса: $SERVICE_NAME (macOS) ==="

    LINE=$(launchctl list | grep -i "$SERVICE_NAME" | head -n 1)

    if [ -z "$LINE" ]; then
        echo "[ERROR] Сервис '$SERVICE_NAME' не найден в launchd."
        STATUS_CODE=1
    else
        PID=$(echo "$LINE" | awk '{print $1}')
        if [ "$PID" = "-" ]; then
            echo "[ERROR] Сервис загружен, но не запущен: $LINE"
            STATUS_CODE=1
        else
            echo "[OK] Сервис работает (PID $PID): $LINE"
        fi
    fi

    if [ "$STATUS_CODE" -ne 0 ]; then
        echo "--- Последние 10 строк лога для $SERVICE_NAME ---"
        log show --predicate "process == \"$SERVICE_NAME\"" --last 10m 2>/dev/null | tail -n 10
    fi

    echo ""
    echo "=== Ошибки за последний час (log show) ==="
    ERROR_COUNT=$(log show --last 1h --predicate 'messageType == error' 2>/dev/null | wc -l | tr -d ' ')
    echo "Количество ошибок: $ERROR_COUNT"
    exit $STATUS_CODE
fi

# ---------------------------------------------------------------
# Linux (systemd)
# ---------------------------------------------------------------
if ! command -v systemctl >/dev/null 2>&1; then
    echo "[ERROR] systemctl не найден. Поддерживаются Linux с systemd и macOS."
    exit 2
fi

echo "=== Проверка сервиса: $SERVICE_NAME ==="

SERVICE_STATUS=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)

if [ "$SERVICE_STATUS" = "active" ]; then
    echo "[OK] Сервис '$SERVICE_NAME' работает штатно (active)."
else
    echo "[ERROR] Сервис '$SERVICE_NAME' НЕ работает! Текущий статус: ${SERVICE_STATUS:-unknown}"
    echo "--- Последние 10 строк лога для $SERVICE_NAME ---"
    journalctl -u "$SERVICE_NAME" -n 10 --no-pager
    STATUS_CODE=1
fi

echo ""
echo "=== Ошибки за последний час ==="

if [ -r /var/log/syslog ]; then
    FIRST_FIELD=$(head -n 1 /var/log/syslog | awk '{print $1}')

    CUTOFF=$(date -d '1 hour ago' '+%Y-%m-%dT%H:%M:%S')
    ERROR_COUNT=$(awk -v cutoff="$CUTOFF" \
        'substr($1,1,19) >= cutoff && tolower($0) ~ /error|fail/ {c++} END {print c+0}' \
        /var/log/syslog)

    echo "Ошибок/сбоев в /var/log/syslog: $ERROR_COUNT"
else
    echo "[Info] /var/log/syslog недоступен (нет файла или прав), использую journalctl."
    ERROR_COUNT=$(journalctl --since "1 hour ago" -p err --no-pager -q 2>/dev/null | wc -l)
    echo "Ошибок в journalctl: $ERROR_COUNT"
fi

exit $STATUS_CODE