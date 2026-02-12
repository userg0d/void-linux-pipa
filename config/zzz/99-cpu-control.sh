#!/bin/sh
# Этот скрипт должен лежать в /etc/zzz.d/suspend/ (для pre) и /etc/zzz.d/resume/ (для post)
# Или в /etc/zzz.d/ как единый скрипт (если ваша версия zzz поддерживает аргументы, но надежнее разделить или использовать $1)

# В Void Linux zzz передает аргументы: $1 (pre/post) и $2 (suspend/hibernate)
PHASE=$1

case "$PHASE" in
    pre)
        # Отключаем ядра 1-7 (оставляем cpu0)
        for i in $(seq 1 7); do
            CPU_FILE="/sys/devices/system/cpu/cpu$i/online"
            if [ -f "$CPU_FILE" ]; then
                echo 0 > "$CPU_FILE"
            fi
        done

        # Set governor to powersave for all CPUs
        for i in $(seq 0 7); do
            GOVERNOR_FILE="/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
            if [ -f "$GOVERNOR_FILE" ]; then
                echo powersave > "$GOVERNOR_FILE"
            fi
        done
        ;;

    post)
        # Включаем ядра 1-7
        for i in $(seq 1 7); do
            CPU_FILE="/sys/devices/system/cpu/cpu$i/online"
            if [ -f "$CPU_FILE" ]; then
                echo 1 > "$CPU_FILE"
            fi
        done

        # Set governor to schedutil for all CPUs
        for i in $(seq 0 7); do
            GOVERNOR_FILE="/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor"
            if [ -f "$GOVERNOR_FILE" ]; then
                echo schedutil > "$GOVERNOR_FILE"
            fi
        done
        ;;
    
    *)
        echo "ERROR: Invalid phase '$PHASE'. Expected 'pre' or 'post'" >&2
        exit 1
        ;;
esac

