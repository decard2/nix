#!/usr/bin/env fish

set LAT 52.3
set LON 104.3
set TEMP_FILE /tmp/wlsunset_temp
set TIMES_FILE ~/.cache/wlsunset_times
set TZ "Asia/Irkutsk"

# Создаем кэш-папку, если её нет
mkdir -p (dirname $TIMES_FILE)

# Очищаем старую температуру при запуске
echo 6500 > $TEMP_FILE

function get_current_temperature
    if test -f $TEMP_FILE
        cat $TEMP_FILE
    else
        echo 6500
    end
end

function save_temperature
    echo $argv[1] > $TEMP_FILE
end

function kill_previous_wlsunset
    pkill -f wlsunset
    sleep 1
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

function start_wlsunset
    set current_time (date +%s)
    set times (get_sun_times)
    set sunrise (echo $times | awk '{print $1}')
    set sunset (echo $times | awk '{print $2}')

    # Останавливаем предыдущий процесс
    kill_previous_wlsunset

    # Конвертируем timestamp в время для wlsunset
    set sunrise_time (date -d "@$sunrise" +%H:%M)
    set sunset_time (date -d "@$sunset" +%H:%M)

    echo "Starting wlsunset: sunrise at $sunrise_time, sunset at $sunset_time"

    # Запускаем wlsunset с параметрами
    wlsunset -l $LAT -L $LON -t 3500 -T 6500 -S $sunrise_time -s $sunset_time >/dev/null 2>&1 &

    # Сохраняем информацию о текущем состоянии
    if [ $current_time -gt $sunset ] || [ $current_time -lt $sunrise ]
        save_temperature 3500
    else
        save_temperature 6500
    end
end

# Обновляем данные при старте
update_sun_times

# Запускаем wlsunset
start_wlsunset

echo "wlsunset started successfully"

# Основной цикл - проверяем каждый час, нужно ли обновить времена
while true
    sleep 3600  # проверяем каждый час
    set old_times (get_sun_times)
    update_sun_times
    set new_times (get_sun_times)

    # Если времена изменились, перезапускаем wlsunset
    if test "$old_times" != "$new_times"
        echo "Sun times updated, restarting wlsunset"
        start_wlsunset
    end
end
