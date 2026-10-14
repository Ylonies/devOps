#!/bin/bash

if [ -z "$1" ]; then
    echo "Использование: $0 <имя_сервиса>"
    echo "Пример: $0 docker"
    exit 1
fi

SERVICE_NAME="$1"

echo "=== Проверка сервиса: $SERVICE_NAME ==="

SERVICE_STATUS=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)

if [ "$SERVICE_STATUS" = "active" ]; then
    echo "[OK] Сервис '$SERVICE_NAME' работает штатно (active)."
else
    echo "[ERROR] Сервис '$SERVICE_NAME' НЕ работает! Текущий статус: $SERVICE_STATUS"
    echo "--- Последние 10 строк лога для сервиса $SERVICE_NAME ---"
    journalctl -u "$SERVICE_NAME" -n 10 --no-pager
fi

echo ""
echo "=== Анализ системных ошибок (/var/log/syslog) за последний час ==="


CURRENT_HOUR_PATTERN=$(date '+%b %e %H:')

if [ -f /var/log/syslog ]; then

    ERROR_COUNT=$(grep "$CURRENT_HOUR_PATTERN" /var/log/syslog | grep -E -i "error|fail" | awk 'END {print NR+0}')
    echo "Количество ошибок/сбоев за последний час: $ERROR_COUNT"
else
    echo "[Info] Файл /var/log/syslog не найден (возможно, используется systemd journal без rsyslog)."

    JOURNAL_ERR_COUNT=$(journalctl --since "1 hour ago" -p err --no-pager | awk 'END {print NR-1}')
    echo "Количество ошибок в journalctl за последний час: ${JOURNAL_ERR_COUNT#-}"
fi