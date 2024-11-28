#!/usr/bin/env nu

let LAT = 52.3
let LON = 104.3

def kill_previous_hyprsunset [] {
    let pids = (^pgrep hyprsunset | split row "\n" | where { |line| $line != "" })
    if not ($pids | is-empty) {
        $pids | each { |pid|
            ^kill -9 $pid
        }
    }
}

def apply_temperature [time_now: datetime, sun_times: record] {
    kill_previous_hyprsunset

    if $time_now > $sun_times.sunset or $time_now < $sun_times.sunrise {
        ^bash -c "hyprsunset -t 3500 >/dev/null 2>&1 &"
    } else {
        ^bash -c "hyprsunset -t 5500 >/dev/null 2>&1 &"
    }

    sleep 2sec
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
