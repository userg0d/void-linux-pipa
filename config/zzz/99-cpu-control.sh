#!/bin/sh
# Этот скрипт должен лежать в /etc/zzz.d/suspend/ (для pre) и /etc/zzz.d/resume/ (для post)
# Или в /etc/zzz.d/ как единый скрипт (если ваша версия zzz поддерживает аргументы, но надежнее разделить или использовать $1)

# В Void Linux zzz передает аргументы: $1 (pre/post) и $2 (suspend/hibernate)
PHASE=$1

# Лог файл
LOG="/tmp/suspend_cpu_test.log"

case "$PHASE" in
    pre)
        # Действия ПЕРЕД сном (suspend)
        echo "Suspending at $(date)..." > "$LOG"
        
        # Отключаем ядра 1-7 (оставляем cpu0)
        # Проверяем наличие файла перед записью, чтобы избежать ошибок
        for i in $(seq 1 7); do
            CPU_FILE="/sys/devices/system/cpu/cpu$i/online"
            if [ -f "$CPU_FILE" ]; then
                echo 0 > "$CPU_FILE"
            fi
        done
        
        # Записываем состояние в лог
        echo "CPU status before sleep:" >> "$LOG"
        grep . /sys/devices/system/cpu/cpu*/online >> "$LOG" 2>&1
        ;;
        
    post)
        # Действия ПОСЛЕ пробуждения (resume)
        echo "...and we are back from $(date)" >> "$LOG"
        
        # Включаем ядра 1-7
        for i in $(seq 1 7); do
            CPU_FILE="/sys/devices/system/cpu/cpu$i/online"
            if [ -f "$CPU_FILE" ]; then
                echo 1 > "$CPU_FILE"
            fi
        done
        
        # Записываем состояние в лог
        echo "CPU status after resume:" >> "$LOG"
        grep . /sys/devices/system/cpu/cpu*/online >> "$LOG" 2>&1
        ;;
esac

