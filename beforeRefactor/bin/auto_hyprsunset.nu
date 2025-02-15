#!/usr/bin/env nu

let LAT = 52.3
let LON = 104.3
let TEMP_FILE = "/tmp/hyprsunset_temp"

# Чистим старую температуру при запуске
rm -f $TEMP_FILE
5500 | save -f $TEMP_FILE  # Стартуем с дефолтной температуры

def get_current_temperature [] {
    if ($TEMP_FILE | path exists) {
        open $TEMP_FILE | into int
    } else {
        5500  # дефолтная температура
    }
}

def save_temperature [temp: int] {
    $temp | save -f $TEMP_FILE
}

def apply_temperature [time_now: datetime, sun_times: record] {
    let current_temp = (get_current_temperature)
    let target_temp = if $time_now > $sun_times.sunset or $time_now < $sun_times.sunrise {
        3500
    } else {
        5500
    }

    if $current_temp != $target_temp {

        kill_previous_hyprsunset
        ^bash -c $"hyprsunset -t ($target_temp) >/dev/null 2>&1 &"
        save_temperature $target_temp
        sleep 2sec
    }
}

def kill_previous_hyprsunset [] {
    # Ищем процессы hyprsunset и убиваем их
    let processes = (ps | where name =~ 'hyprsunset')
    if not ($processes | is-empty) {
        $processes | each { |proc|
            kill -f $proc.pid
        }
    }
}

def calculate_sun_times [] {
    let response = (
        http get $"https://api.sunrise-sunset.org/json?lat=($LAT)&lng=($LON)&formatted=0"
    )

    let sunrise = ($response.results.sunrise | into datetime | date to-timezone "Asia/Irkutsk")
    let sunset = ($response.results.sunset | into datetime | date to-timezone "Asia/Irkutsk")

    {sunrise: $sunrise, sunset: $sunset}
}

while true {
    let current_time = (date now)
    let sun_times = (calculate_sun_times)

    apply_temperature $current_time $sun_times

    sleep 300sec
}
