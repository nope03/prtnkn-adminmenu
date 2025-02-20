-- Event handler untuk mengubah cuaca
RegisterNetEvent("adminmenu:changeWeather")
AddEventHandler("adminmenu:changeWeather", function(weatherType)
    -- Set the weather type
    SetWeatherTypePersist(weatherType)
    SetWeatherTypeNow(weatherType)
    SetWeatherTypeNowPersist(weatherType)
    lib.notify({
        title = "Admin Menu",
        description = "🌤️ Weather changed to: " .. weatherType,
        type = "success"
    })
end)