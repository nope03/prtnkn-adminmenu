local isSpectating = false
local spectatedPlayer = nil

RegisterNetEvent("adminmenu:spectate")
AddEventHandler("adminmenu:spectate", function(targetId)
    local playerId = PlayerId()
    local playerServerId = GetPlayerServerId(playerId)

    -- Cek apakah admin memilih dirinya sendiri
    if targetId == playerServerId then
        lib.notify({
            title = "Admin Menu",
            description = "❌ You cannot spectate yourself!",
            type = "error",
            duration = 5000
        })
        return
    end

    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if DoesEntityExist(targetPed) then
        if isSpectating then
            -- Berhenti Spectate
            isSpectating = false
            spectatedPlayer = nil
            NetworkSetInSpectatorMode(false, PlayerPedId())
            SetEntityVisible(PlayerPedId(), true)

            lib.notify({
                title = "Admin Menu",
                description = "📌 Stopped Spectating.",
                type = "info",
                duration = 5000
            })
        else
            -- Mulai Spectate
            isSpectating = true
            spectatedPlayer = targetId
            NetworkSetInSpectatorMode(true, targetPed)
            SetEntityVisible(PlayerPedId(), false)

            lib.notify({
                title = "Admin Menu",
                description = "👁 Now Spectating Player ID: " .. targetId,
                type = "success",
                duration = 5000
            })
        end
    else
        lib.notify({
            title = "Admin Menu",
            description = "❌ Player not found!",
            type = "error",
            duration = 5000
        })
    end
end)

RegisterNetEvent("adminmenu:toggle")
AddEventHandler("adminmenu:toggle", function(state)
    SetNuiFocus(state, state)
    SendNUIMessage({
        type = state and "show" or "hide"
    })
end)

RegisterNetEvent("adminmenu:toggle")
AddEventHandler("adminmenu:toggle", function(state)
    SetNuiFocus(state, state)
    if state then
        ESX.TriggerServerCallback("adminmenu:getPlayers", function(players)
            SendNUIMessage({
                type = "show",
                players = players
            })
        end)
    else
        SendNUIMessage({ type = "hide" })
    end
end)

RegisterNetEvent("adminmenu:freeze")
AddEventHandler("adminmenu:freeze", function(state)
    local playerPed = PlayerPedId()
    
    print("📌 Received Freeze State:", state) -- Debugging

    -- Update status freeze
    FreezeEntityPosition(playerPed, state)

    if state then
        lib.notify({ title = "Admin Menu", description = "❄️ You are frozen!", type = "info" })
    else
        lib.notify({ title = "Admin Menu", description = "✅ You are unfrozen!", type = "success" })
    end
end)

RegisterNetEvent("adminmenu:updateFreezeButton")
AddEventHandler("adminmenu:updateFreezeButton", function(targetId, isFrozen)
    if targetId == GetPlayerServerId(PlayerId()) then
        SendNUIMessage({
            type = "updateFreezeButton",
            isFrozen = isFrozen
        })
    end
end)

RegisterNetEvent("adminmenu:warnEffect")
AddEventHandler("adminmenu:warnEffect", function(reason, adminName)
    -- Kirim data ke NUI untuk menampilkan warning overlay
    SendNUIMessage({
        type = "showWarning",
        adminName = adminName,
        reason = reason
    })
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 288) then -- F1 Key
            TriggerServerEvent("adminmenu:checkAdmin")
        end
    end
end)

