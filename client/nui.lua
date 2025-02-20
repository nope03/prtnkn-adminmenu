RegisterNUICallback("ox_lib_dialog", function(data, cb)
    local input = lib.inputDialog(data.title, {
        { type = "input", label = data.description, placeholder = "Enter reason here..." }
    })

    if input and input[1] then
        cb({ input = input[1] })
    else
        cb({})
    end
end)

RegisterNUICallback("close", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "hide" })
end)

RegisterNUICallback("kill", function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
    print("Kill function triggered")
end)

RegisterNUICallback("spectate", function()
    TriggerServerEvent("adminmenu:spectate", GetPlayerServerId(PlayerId()))
    print("spectate function triggered")
end)

RegisterNUICallback("heal", function()
    TriggerServerEvent("adminmenu:heal", GetPlayerServerId(PlayerId()))
    print("heal function triggered")
end)

RegisterNUICallback("revive", function()
    TriggerServerEvent("adminmenu:revive", GetPlayerServerId(PlayerId()))
    print("Revive function triggered")
end)

RegisterNUICallback("kick", function(data)
    TriggerServerEvent("adminmenu:kick", data.playerId, data.reason)
end)

RegisterNUICallback("openBanDialog", function(data, cb)
    local playerId = tonumber(data.playerId) -- Ambil ID pemain dari data

    if not playerId then
        print("❌ Error: Invalid Player ID for ban dialog!")
        cb({ status = 'error', message = 'Invalid Player ID' })
        return
    end

    -- Buka dialog ox_lib untuk memasukkan durasi dan alasan ban
    local input = lib.inputDialog("Ban Player", {
        { type = "number", label = "Duration (minutes)", placeholder = "Enter duration", required = true },
        { type = "input", label = "Reason", placeholder = "Enter reason", required = true }
    })

    if input and input[1] and input[2] then
        local duration = tonumber(input[1])
        local reason = input[2]

        if duration and reason then
            -- Kirim data ke server untuk memproses ban
            TriggerServerEvent("adminmenu:ban", playerId, duration, reason)
            cb({ status = 'success' })
        else
            cb({ status = 'error', message = 'Invalid input' })
        end
    else
        cb({ status = 'error', message = 'Dialog canceled' })
    end
end)

RegisterNUICallback("freezeToggle", function(data)
    local playerId = tonumber(data.playerId) -- Pastikan angka

    if not playerId then
        print("❌ Error: Invalid Player ID for freeze toggle!")
        return
    end

    TriggerServerEvent("adminmenu:freezeToggle", playerId)
end)

-- Callback untuk aksi "bring"
RegisterNUICallback('bring', function(data, cb)
    local playerId = tonumber(data.playerId)
    if playerId then
        TriggerServerEvent('adminmenu:bring', playerId)
        cb({ status = 'success' })
    else
        cb({ status = 'error', message = 'Invalid player ID' })
    end
end)

-- Callback untuk aksi "goto"
RegisterNUICallback('goto', function(data, cb)
    local playerId = tonumber(data.playerId)
    if playerId then
        TriggerServerEvent('adminmenu:goto', playerId)
        cb({ status = 'success' })
    else
        cb({ status = 'error', message = 'Invalid player ID' })
    end
end)

RegisterNUICallback("warnPlayer", function(data, cb)
    local playerId = tonumber(data.playerId)
    local reason = data.reason

    if not playerId or not reason then
        cb({ status = 'error', message = 'Invalid player ID or reason' })
        return
    end

    TriggerServerEvent("adminmenu:warnPlayer", playerId, reason)
    cb({ status = 'success' })
end)

RegisterNUICallback("openClothing", function(data, cb)
    local playerId = tonumber(data.playerId)

    if not playerId then
        print("❌ Error: Invalid Player ID for Clothing Menu!")
        return
    end

    print("📌 Opening Clothing Menu for Player ID:", playerId)
    TriggerEvent("illenium-appearance:client:openClothingShop", playerId)

    cb({})
end)

-- Callback untuk membuka inventory pemain
RegisterNUICallback("openInventory", function(data, cb)
    local playerId = tonumber(data.playerId) -- Ambil ID pemain dari data

    if not playerId then
        print("❌ Error: Invalid Player ID for Open Inventory!")
        cb({ status = 'error', message = 'Invalid Player ID' })
        return
    end

    -- Tutup UI admin menu
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "hide" })

    -- Trigger event untuk membuka inventory pemain
    TriggerServerEvent("adminmenu:openInventory", playerId)
    cb({ status = 'success' })
end)

RegisterNUICallback("makedrunk", function(data)
    TriggerServerEvent("adminmenu:makedrunk", data.playerId)
end)

RegisterNUICallback("makefire", function(data)
    TriggerServerEvent("adminmenu:makefire", data.playerId)
end)

RegisterNUICallback("attackanimal", function(data)
    TriggerServerEvent("adminmenu:attackanimal", data.playerId)
end)

RegisterNUICallback("godmode", function(data, cb)
    TriggerServerEvent("adminmenu:godmode")
    cb({ status = 'success' })
end)

RegisterNUICallback("fixvehicle", function()
    TriggerServerEvent("adminmenu:fixvehicle")
end)

RegisterNUICallback("healself", function()
    TriggerServerEvent("adminmenu:healself")
end)

RegisterNUICallback("invisible", function(data)
    local playerId = tonumber(data.playerId) -- Pastikan angka
    if playerId then
        TriggerServerEvent("adminmenu:invisible", playerId)
    else
        print("❌ Error: Invalid Player ID for action 'invisible'")
    end
end)

RegisterNUICallback("spawnvehicle", function()
    TriggerEvent("adminmenu:spawnvehicle") -- Memanggil event untuk input dialog
end)

RegisterNUICallback("teleportwaypoint", function()
    TriggerServerEvent("adminmenu:teleportwaypoint")
end)

RegisterNUICallback("invisible", function()
    TriggerServerEvent("adminmenu:invisible")
end)

RegisterNUICallback("noclip", function(data, cb)
    TriggerServerEvent("adminmenu:noclip")
    cb({ status = 'success' })
end)

RegisterNUICallback("changeWeather", function(data, cb)
    local weatherType = data.weatherType

    if weatherType then
        TriggerServerEvent("adminmenu:changeWeather", weatherType) -- Kirim ke server
        cb({ status = "success" })
    else
        cb({ status = "error", message = "Invalid weather type" })
    end
end)

RegisterNUICallback("openWeatherDialog", function(_, cb)
    local weatherType = lib.inputDialog("🌦️ Change Weather", {
        { type = "select", label = "Select Weather", options = {
            { label = "Extra Sunny", value = "EXTRASUNNY" },
            { label = "Clear", value = "CLEAR" },
            { label = "Neutral", value = "NEUTRAL" },
            { label = "Smog", value = "SMOG" },
            { label = "Foggy", value = "FOGGY" },
            { label = "Overcast", value = "OVERCAST" },
            { label = "Clouds", value = "CLOUDS" },
            { label = "Rain", value = "RAIN" },
            { label = "Thunder", value = "THUNDER" },
            { label = "Snow", value = "SNOW" },
            { label = "Blizzard", value = "BLIZZARD" }
        }}
    })

    if weatherType then
        cb({ weatherType = weatherType[1] })
    else
        cb({}) -- Jika user batal memilih
    end
end)

RegisterNUICallback("changeTimer", function(data, cb)
    local hour = data.hour
    local minute = data.minute

    if hour or minute then
        TriggerServerEvent("adminmenu:changeWeather", hour, minute) -- Kirim ke server
        cb({ status = "success" })
    else
        cb({ status = "error", message = "Invalid weather type" })
    end
end)

RegisterNUICallback("openTimeDialog", function(_, cb)
    CreateThread(function()
        local timeInput = lib.inputDialog("⏰ Set Time", {
            { type = "number", label = "Hour (0-23)", min = 0, max = 23, default = 12 },
            { type = "number", label = "Minute (0-59)", min = 0, max = 59, default = 0 }
        })

        if timeInput then
            print("📌 Time input received. Hour:", timeInput[1], "Minute:", timeInput[2])
            cb({ hour = timeInput[1], minute = timeInput[2] })
        else
            print("❌ User canceled time selection.")
            cb({})
        end
    end)
end)
