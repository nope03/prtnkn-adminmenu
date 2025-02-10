local frozenPlayers = {} -- Simpan status freeze pemain

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    deferrals.defer()
    Citizen.Wait(0)

    print("Checking ban status for:", identifier)

    MySQL.Async.fetchAll("SELECT * FROM banned_players WHERE identifier = @identifier", { ['@identifier'] = identifier }, function(result)
        if #result > 0 then
            local banData = result[1]
            if os.time() < banData.expires_at then
                print("Player is still banned until:", os.date('%Y-%m-%d %H:%M:%S', banData.expires_at))
                deferrals.done("You are banned until " .. os.date('%Y-%m-%d %H:%M:%S', banData.expires_at) .. ". Reason: " .. banData.reason)
            else
                print("Ban expired, removing from database.")
                MySQL.Async.execute("DELETE FROM banned_players WHERE identifier = @identifier", { ['@identifier'] = identifier })
                deferrals.done()
            end
        else
            print("Player is not banned.")
            deferrals.done()
        end
    end)
end)

RegisterServerEvent("adminmenu:checkAdmin")
AddEventHandler("adminmenu:checkAdmin", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "admin" then
        TriggerClientEvent("adminmenu:toggle", source, true)
    else
        TriggerClientEvent("adminmenu:toggle", source, false)
    end
end)

RegisterServerEvent("adminmenu:bring")
AddEventHandler("adminmenu:bring", function(targetId)
    local src = source
    print("📌 Admin ID:", src, "is bringing Player ID:", targetId)

    local targetPed = GetPlayerPed(targetId)
    local adminPed = GetPlayerPed(src)

    if DoesEntityExist(targetPed) and DoesEntityExist(adminPed) then
        local coords = GetEntityCoords(adminPed)
        print("📌 Admin Coords:", coords)
        SetEntityCoords(targetPed, coords.x, coords.y, coords.z, false, false, false, true)
        TriggerClientEvent("ox_lib:notify", targetId, { title = "Admin Menu", description = "🔄 You have been brought to the admin!", type = "info" })
    else
        print("❌ Error: Target or admin entity does not exist!")
    end
end)

RegisterServerEvent("adminmenu:goto")
AddEventHandler("adminmenu:goto", function(targetId)
    local src = source
    print("📌 Admin ID:", src, "is going to Player ID:", targetId)

    local targetPed = GetPlayerPed(targetId)

    if DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        print("📌 Target Coords:", coords)
        SetEntityCoords(GetPlayerPed(src), coords.x, coords.y, coords.z, false, false, false, true)
        TriggerClientEvent("ox_lib:notify", src, { title = "Admin Menu", description = "🚀 You have teleported to the player!", type = "success" })
    else
        print("❌ Error: Target entity does not exist!")
    end
end)
RegisterServerEvent("adminmenu:freezeToggle")
AddEventHandler("adminmenu:freezeToggle", function(targetId)
    targetId = tonumber(targetId) -- Pastikan ID adalah angka

    if not targetId then
        print("❌ Error: Invalid Player ID received for freeze toggle!")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer then
        -- Ambil status freeze dari table
        local newFreezeState = not frozenPlayers[targetId]

        -- Simpan status baru ke table
        frozenPlayers[targetId] = newFreezeState

        -- Kirim status baru ke client
        TriggerClientEvent("adminmenu:freeze", targetId, newFreezeState)

        -- Kirim status freeze ke NUI untuk mengupdate tombol
        TriggerClientEvent("adminmenu:updateFreezeButton", -1, targetId, newFreezeState)

        print("📌 Freeze Toggle:", targetId, "| New State:", newFreezeState)
    else
        print("❌ Error: Player not found!")
    end
end)

RegisterServerEvent("adminmenu:heal")
AddEventHandler("adminmenu:heal", function(targetId)
    targetId = tonumber(targetId) -- Pastikan ID adalah angka

    if not targetId then
        print("❌ Error: Invalid Player ID received for heal!")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer then
        print("✅ Healing Player ID:", targetId)

        -- Heal dengan ESX Basic Needs
        TriggerClientEvent("esx_basicneeds:healPlayer", targetId)
        TriggerClientEvent('esx_basicneeds:resetStatus', targetId)

        -- Notifikasi ke pemain
        TriggerClientEvent("ox_lib:notify", targetId, {
            title = "Admin Menu",
            description = "❤️ You have been fully healed!",
            type = "success"
        })
    else
        print("❌ Error: Player not found!")
    end
end)

RegisterServerEvent("adminmenu:kick")
AddEventHandler("adminmenu:kick", function(targetId, reason)
    if not reason or reason == "" then reason = "No reason provided" end
    DropPlayer(targetId, "You have been kicked by an admin. Reason: " .. reason)
end)

RegisterServerEvent("adminmenu:ban")
AddEventHandler("adminmenu:ban", function(targetId, duration, reason)
    targetId = tonumber(targetId) -- Pastikan angka

    print("📌 Ban Request Received for Player ID:", targetId, "Duration:", duration, "Reason:", reason)

    if not targetId then
        print("❌ Error: Invalid Player ID!")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(targetId)
    if not xPlayer then
        print("❌ Error: Player not found!")
        return
    end

    local expiration = os.time() + (duration * 60)

    MySQL.Async.execute("INSERT INTO banned_players (identifier, name, reason, expires_at) VALUES (@identifier, @name, @reason, @expires)", {
        ['@identifier'] = xPlayer.identifier,
        ['@name'] = xPlayer.getName(),
        ['@reason'] = reason,
        ['@expires'] = expiration
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print("✅ Ban stored in database successfully!")
            DropPlayer(targetId, "You have been banned for " .. duration .. " minutes. Reason: " .. reason)
        else
            print("❌ Error: Failed to insert ban into database!")
        end
    end)
end)

RegisterServerEvent("adminmenu:revive")
AddEventHandler("adminmenu:revive", function(targetId)
    TriggerClientEvent("esx_ambulancejob:revive", targetId)
end)

RegisterServerEvent("adminmenu:spectate")
AddEventHandler("adminmenu:spectate", function(targetId)
    TriggerClientEvent("adminmenu:spectate", source, targetId)
end)

local warnCooldowns = {} -- Menyimpan cooldown setiap admin

RegisterServerEvent("adminmenu:warnPlayer")
AddEventHandler("adminmenu:warnPlayer", function(targetId, reason)
    local adminId = source -- ID admin yang memberi warning
    targetId = tonumber(targetId)

    if not targetId or not reason then
        print("❌ Error: Invalid Warning Data!")
        return
    end

    local admin = ESX.GetPlayerFromId(adminId)
    local xPlayer = ESX.GetPlayerFromId(targetId)

    if not xPlayer then
        print("❌ Error: Player not found!")
        return
    end

    local adminName = admin.getName()

    print("⚠️ Warning Sent to Player ID:", targetId, "| Warning by:", adminName, "| Reason:", reason)

    -- Kirim event ke client untuk menampilkan efek Warning
    TriggerClientEvent("adminmenu:warnEffect", targetId, reason, adminName)
end)

RegisterNetEvent("adminmenu:showWarning")
AddEventHandler("adminmenu:showWarning", function(adminName, reason)
    SendNUIMessage({
        type = "showWarning",
        adminName = adminName,
        reason = reason
    })
end)


ESX.RegisterServerCallback("adminmenu:getPlayers", function(source, cb)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        table.insert(players, { id = playerId, name = xPlayer.getName() })
    end
    cb(players)
end)
