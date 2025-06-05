RegisterNetEvent("adminmenu:updateWeather")
AddEventHandler("adminmenu:updateWeather", function(weatherType)
    -- Set cuaca untuk semua pemain
    SetWeatherTypePersist(weatherType)
    SetWeatherTypeNow(weatherType)
    SetWeatherTypeNowPersist(weatherType)

    print("🌦️ Weather updated to:", weatherType)
end)

local currentHour, currentMinute = 12, 0

RegisterNetEvent("adminmenu:updateTime")
AddEventHandler("adminmenu:updateTime", function(hour, minute)
    print("📌 Received time update from server. Hour:", hour, "Minute:", minute)

    currentHour, currentMinute = hour, minute
    NetworkOverrideClockTime(currentHour, currentMinute, 0)
    print("⏰ Time updated to:", currentHour .. ":" .. currentMinute)
end)

-- Loop yang memperbarui waktu setiap detik
CreateThread(function()
    while true do
        Wait(1000)
        NetworkOverrideClockTime(currentHour, currentMinute, 0)
    end
end)

