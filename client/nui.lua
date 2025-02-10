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

RegisterNUICallback("banRequest", function(data)
    local playerId = tonumber(data.playerId) -- Pastikan angka

    if not playerId then
        print("❌ Error: Invalid Player ID!") -- Debug
        return
    end

    local input = lib.inputDialog("Ban Player", {
        { type = "number", label = "Duration (minutes)", min = 1, placeholder = "Enter duration" },
        { type = "input", label = "Reason", placeholder = "Enter reason" }
    })

    if input and input[1] and input[2] then
        print("✅ Sending ban request for Player ID:", playerId, "Duration:", input[1], "Reason:", input[2]) -- Debug
        TriggerServerEvent("adminmenu:ban", playerId, tonumber(input[1]), input[2])
    else
        print("❌ Ban canceled or invalid input.") -- Debug
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