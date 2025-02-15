#!/usr/bin/env fish

set LAT 52.3
set LON 104.3
set TEMP_FILE /tmp/hyprsunset_temp

# Чистим старую температуру при запуске
rm -f $TEMP_FILE
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

function calculate_sun_times
    set response (curl -s "https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0")

    set -x TZ Asia/Irkutsk

    set sunrise_str (echo $response | jq -r '.results.sunrise')
    set sunset_str (echo $response | jq -r '.results.sunset')

    set sunrise_ts (date -d $sunrise_str +%s)
    set sunset_ts (date -d $sunset_str +%s)

    echo "$sunrise_ts"
    echo "$sunset_ts"
end

function apply_temperature
    set current_time (date +%s)
    set times (calculate_sun_times)
    set sunrise $times[1]
    set sunset $times[2]

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

while true
    apply_temperature
    sleep 300
end
