#!/usr/bin/env fish

set LAT 52.3
set LON 104.3
set TEMP_FILE /tmp/hyprsunset_temp
set TIMES_FILE ~/.cache/hyprsunset_times
set TZ "Asia/Irkutsk"

# Создаем кэш-папку, если её нет
mkdir -p (dirname $TIMES_FILE)

# Очищаем старую температуру при запуске
echo 5500 > $TEMP_FILE

function get_current_temperature
    if test -f $TEMP_FILE
        cat $TEMP_FILE
    else
        echo 5500
    end
end

function save_temperature
    echo $argv[1] > $TEMP_FILE
end

function kill_previous_hyprsunset
    ps aux | grep hyprsunset | grep -v grep | awk '{print $2}' | xargs -r kill -9
end

function update_sun_times
    # Проверяем, нужно ли обновление
    set current_date (date +%Y-%m-%d)

    # Если файл существует и данные свежие - ничего не делаем
    if test -f $TIMES_FILE
        set file_date (head -n 1 $TIMES_FILE)
        if test "$file_date" = "$current_date"
            return 0
        end
    end

    # Пробуем получить новые данные
    set response (curl -s -m 5 "https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0")

    # Проверяем, что запрос успешен
    if test $status -eq 0; and echo $response | jq -e '.results.sunrise' >/dev/null
        set -x TZ $TZ

        set sunrise_str (echo $response | jq -r '.results.sunrise')
        set sunset_str (echo $response | jq -r '.results.sunset')

        set sunrise_ts (date -d $sunrise_str +%s)
        set sunset_ts (date -d $sunset_str +%s)

        # Сохраняем дату и время в файл
        echo $current_date > $TIMES_FILE
        echo "$sunrise_ts $sunset_ts" >> $TIMES_FILE
        return 0
    end

    # Если запрос не удался, а файл существует - просто оставляем старые данные
    if test -f $TIMES_FILE
        return 0
    end

    # Если файла нет и запрос не удался - создаем файл с примерными значениями
    set -x TZ $TZ

    # Примерные значения восхода и заката для Иркутска
    set today_date (date +%Y-%m-%d)
    set sunrise_ts (date -d "$today_date 06:00:00" +%s)
    set sunset_ts (date -d "$today_date 18:00:00" +%s)

    echo $current_date > $TIMES_FILE
    echo "$sunrise_ts $sunset_ts" >> $TIMES_FILE
    return 0
end

function get_sun_times
    # Обновляем данные, если нужно
    update_sun_times

    # Считываем данные из файла (строка с временами - вторая строка)
    tail -n 1 $TIMES_FILE
end

function apply_temperature
    set current_time (date +%s)
    set times (get_sun_times)
    set sunrise (echo $times | awk '{print $1}')
    set sunset (echo $times | awk '{print $2}')

    set current_temp (get_current_temperature)
    set target_temp 5500

    if [ $current_time -gt $sunset ]
        set target_temp 3500
    end

    if [ $current_time -lt $sunrise ]
        set target_temp 3500
    end

    if [ $current_temp -ne $target_temp ]
        kill_previous_hyprsunset
        hyprsunset -t $target_temp >/dev/null 2>&1 &
        save_temperature $target_temp
        sleep 2
    end
end

# Обновляем данные при старте
update_sun_times

# Основной цикл
while true
    apply_temperature
    sleep 300
end
