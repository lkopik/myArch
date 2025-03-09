#!/bin/bash

send_notification() {
    local message="$1"
    # Удаляем все уведомления
    makoctl dismiss
    # Отправляем новое уведомление
    notify-send -u critical "Евангелион: Уровень LCL." "$message"
}

# определения основной и резервной батареи
determine_batteries() {
    local battery1=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100)
    local battery2=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100)
    
    
    echo "BAT0: $battery1%, BAT1: $battery2%"

    if [ $battery1 -lt $battery2 ]; then
        main_battery="BAT0"
        reserve_battery="BAT1"
    else
        main_battery="BAT1"
        reserve_battery="BAT0"
    fi

    main_capacity=$(cat /sys/class/power_supply/$main_battery/capacity)
    reserve_capacity=$(cat /sys/class/power_supply/$reserve_battery/capacity)
    main_status=$(cat /sys/class/power_supply/$main_battery/status)
    reserve_status=$(cat /sys/class/power_supply/$reserve_battery/status)

    
    echo "Основная батарея: $main_battery ($main_capacity%, статус: $main_status)"
    echo "Резервная батарея: $reserve_battery ($reserve_capacity%, статус: $reserve_status)"
}

check_battery() {
    determine_batteries
    
    # Если батарея заряжается, пропускаем уведомления
    if [[ $main_status == "Charging" || $reserve_status == "Charging" ]]; then
        echo "Батарея заряжается. Уведомления отключены."
        return
    fi

    # Уведомление при уровне основной батареи ниже 30%
    if [ $main_capacity -lt 30 ] && [ $main_capacity -ge 10 ]; then
        send_notification "LCL: $main_capacity%. Подключите внешний источник."
    fi

    # Уведомление при критическом уровне основной батареи ниже 10%
    if [ $main_capacity -lt 10 ] && [ $main_capacity -ge 1 ]; then
        send_notification "LCL: $main_capacity%. Активирован резервный контур."
    fi

    # Уведомление, если на резервной батарее осталось меньше 50%
    if [ $reserve_capacity -lt 50 ]; then
        send_notification "ОПАСНОСТЬ!: РЕЗЕРВНАЯ батарея $reserve_capacity%. LCL-уровень КРИТИЧЕСКИЙ!"
    fi
}

# Основной цикл проверки
while true; do
    makoctl dismiss
    check_battery
    sleep 30 
done
