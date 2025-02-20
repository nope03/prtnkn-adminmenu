local frozenPlayers = {}

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    local identifiers = GetPlayerIdentifiers(src)
    local steam = identifiers[1] or nil
    local license = identifiers[2] or nil
    local ip = GetPlayerEndpoint(src) or nil
    local discord = nil
    local xbox = nil
    local live = nil

    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "discord:") then
            discord = identifier
        elseif string.find(identifier, "xbl:") then
            xbox = identifier
        elseif string.find(identifier, "live:") then
            live = identifier
        end
    end

    if not steam and not license and not ip then
        deferrals.done("❌ Unable to verify your identity. Please restart FiveM and try again.")
        return
    end

    local query = MySQL.query.await('SELECT * FROM banned_players WHERE Steam = ? OR License = ? OR IP = ? OR Discord = ? OR Xbox = ? OR Live = ?', { 
        steam, license, ip, discord, xbox, live 
    })

    if query and #query > 0 then
        for i = 1, #query do
            local banData = query[i]
            if os.time() < banData.expires_at then
                deferrals.done("KAMU TELAH TER BANNED HINGGA " .. os.date('%Y-%m-%d %H:%M:%S', banData.expires_at) .. ". Reason: " .. banData.reason .. ". SILAHKAN HUBUNGI ADMIN VIA DISCORD")
                return
            else
                MySQL.update('DELETE FROM banned_players WHERE ID = ?', { banData.ID })
            end
        end
    end

    deferrals.done()
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

    if not Config.HasPermission(src, "bring") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

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

    if not Config.HasPermission(src, "goto") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

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
    local src = source
    targetId = tonumber(targetId) -- Pastikan ID adalah angka

    if not Config.HasPermission(src, "freeze") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    if not targetId then
        print("❌ Error: Invalid Player ID received for freeze toggle!")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer then
        local newFreezeState = not frozenPlayers[targetId]

        frozenPlayers[targetId] = newFreezeState

        TriggerClientEvent("adminmenu:freeze", targetId, newFreezeState)

        TriggerClientEvent("adminmenu:updateFreezeButton", -1, targetId, newFreezeState)

        print("📌 Freeze Toggle:", targetId, "| New State:", newFreezeState)
    else
        print("❌ Error: Player not found!")
    end
end)

RegisterServerEvent("adminmenu:heal")
AddEventHandler("adminmenu:heal", function(targetId)
    local src = source
    targetId = tonumber(targetId)

    if not Config.HasPermission(src, "heal") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

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
    local src = source

    if not Config.HasPermission(src, "kick") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    if not reason or reason == "" then reason = "No reason provided" end
    DropPlayer(targetId, "You have been kicked by an admin. Reason: " .. reason)
end)

RegisterServerEvent("adminmenu:ban")
AddEventHandler("adminmenu:ban", function(targetId, duration, reason)
    local src = source

    if not Config.HasPermission(src, "ban") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not targetPlayer then
        print("❌ Error: Player not found!")
        return
    end

    local expiration = os.time() + (duration * 60)

    local identifiers = GetPlayerIdentifiers(targetId)
    local steam = identifiers[1] or nil
    local license = identifiers[2] or nil
    local ip = GetPlayerEndpoint(targetId) or nil
    local discord = nil
    local xbox = nil
    local live = nil

    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, "discord:") then
            discord = identifier
        elseif string.find(identifier, "xbl:") then
            xbox = identifier
        elseif string.find(identifier, "live:") then
            live = identifier
        end
    end

    MySQL.insert(
        "INSERT INTO banned_players (identifier, name, reason, expires_at, isBanned, Steam, License, IP, Discord, Xbox, Live) " ..
        "VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)",
        { 
            targetPlayer.identifier,
            targetPlayer.getName(),
            reason,
            expiration,
            steam,
            license,
            ip,
            discord,
            xbox,
            live
        },
        function(insertId)
            if insertId then
                print("✅ Player banned successfully!")
                DropPlayer(targetId, "You have been banned for " .. duration .. " minutes. Reason: " .. reason)
            else
                print("❌ Error: Failed to insert ban into database!")
            end
        end
    )
end)

RegisterServerEvent("adminmenu:unban")
AddEventHandler("adminmenu:unban", function(identifier)
    local src = source

    if not Config.HasPermission(src, "unban") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    MySQL.update("DELETE FROM banned_players WHERE identifier = ?", { identifier }, function(rowsChanged)
        if rowsChanged > 0 then
            print("✅ Player unbanned successfully!")
            TriggerClientEvent("ox_lib:notify", src, { title = "Admin Menu", description = "✅ Player has been unbanned!", type = "success" })
        else
            print("❌ Error: Failed to unban player!")
            TriggerClientEvent("ox_lib:notify", src, { title = "Admin Menu", description = "❌ Failed to unban player!", type = "error" })
        end
    end)    
end)

RegisterServerEvent("adminmenu:revive")
AddEventHandler("adminmenu:revive", function(targetId)
    local src = source

    if not Config.HasPermission(src, "revive") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("esx_ambulancejob:revive", targetId)
end)

RegisterServerEvent("adminmenu:spectate")
AddEventHandler("adminmenu:spectate", function(targetId)
    local src = source

    if not Config.HasPermission(src, "spectate") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:spectate", source, targetId)
end)

local warnCooldowns = {}

RegisterServerEvent("adminmenu:warnPlayer")
AddEventHandler("adminmenu:warnPlayer", function(targetId, reason)
    local adminId = source
    targetId = tonumber(targetId)

    if not Config.HasPermission(adminId, "warn") then
        print("❌ Unauthorized access attempt by Player ID:", adminId)
        return
    end

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

    TriggerClientEvent("adminmenu:warnEffect", targetId, reason, adminName)
end)

RegisterServerEvent("adminmenu:openClothing")
AddEventHandler("adminmenu:openClothing", function(targetId)
    local src = source

    if not Config.HasPermission(src, "openClothing") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end
    
    TriggerClientEvent("illenium-appearance:client:openClothing", targetId)
end)

RegisterServerEvent("adminmenu:godmode")
AddEventHandler("adminmenu:godmode", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(targetId)

    if not Config.HasPermission(src, "godmode") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:godmode", src)
end)

RegisterServerEvent("adminmenu:fixvehicle")
AddEventHandler("adminmenu:fixvehicle", function()
    local src = source

    if not Config.HasPermission(src, "fixvehicle") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end
    TriggerClientEvent("adminmenu:fixvehicle", src)
end)

RegisterServerEvent("adminmenu:healself")
AddEventHandler("adminmenu:healself", function()
    local src = source

    if not Config.HasPermission(src, "healself") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end
    TriggerClientEvent("esx_basicneeds:healPlayer", src)
    TriggerClientEvent('esx_basicneeds:resetStatus', src)

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Admin Menu",
        description = "❤️ You have been fully healed!",
        type = "success"
    })
end)

RegisterServerEvent("adminmenu:teleportwaypoint")
AddEventHandler("adminmenu:teleportwaypoint", function()
    local src = source

    if not Config.HasPermission(src, "teleportwaypoint") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end
    TriggerClientEvent("adminmenu:teleportwaypoint", src)
end)

RegisterServerEvent("adminmenu:invisible")
AddEventHandler("adminmenu:invisible", function()
    local src = source

    if not Config.HasPermission(src, "invisible") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end
    TriggerClientEvent("adminmenu:invisible", src)
end)

RegisterServerEvent("adminmenu:noclip")
AddEventHandler("adminmenu:noclip", function()
    local src = source

    if not Config.HasPermission(src, "noclip") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:noclip", src)
end)

RegisterServerEvent("adminmenu:openInventory")
AddEventHandler("adminmenu:openInventory", function(targetId)
    local src = source

    if not Config.HasPermission(src, "openInventory") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:openInventory", src, targetId)
end)

RegisterServerEvent("adminmenu:makedrunk")
AddEventHandler("adminmenu:makedrunk", function(targetId)
    local src = source

    if not Config.HasPermission(src, "makedrunk") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:makedrunk", targetId)
end)

RegisterServerEvent("adminmenu:makefire")
AddEventHandler("adminmenu:makefire", function(targetId)
    local src = source

    if not Config.HasPermission(src, "makefire") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:makefire", targetId)
end)

RegisterServerEvent("adminmenu:attackanimal")
AddEventHandler("adminmenu:attackanimal", function(targetId)
    local src = source

    if not Config.HasPermission(src, "attackanimal") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:attackanimal", targetId)
end)

RegisterServerEvent("adminmenu:spawnvehicle")
AddEventHandler("adminmenu:spawnvehicle", function(vehicleName)
    local src = source

    if not Config.HasPermission(src, "spawnvehicle") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    TriggerClientEvent("adminmenu:spawnvehicle", source, vehicleName)
end)

RegisterNetEvent("adminmenu:changeWeather")
AddEventHandler("adminmenu:changeWeather", function(weatherType)
    local src = source

    if not Config.HasPermission(src, "changeWeather") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    print("📌 Admin changed weather to:", weatherType)

    -- Kirim ke semua pemain agar cuaca tersinkronisasi
    TriggerClientEvent("adminmenu:updateWeather", -1, weatherType)

    -- Notifikasi ke semua admin
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Admin Menu",
        description = "✅ Weather changed to: " .. weatherType,
        type = "success"
    })
end)

RegisterNetEvent("adminmenu:setTime")
AddEventHandler("adminmenu:setTime", function(hour, minute)
    local src = source

    -- Pastikan fungsi Config.HasPermission ada sebelum digunakan
    if Config and Config.HasPermission and not Config.HasPermission(src, "setTime") then
        print("❌ Unauthorized access attempt by Player ID:", src)
        return
    end

    print("📌 Admin changed time to:", hour .. ":" .. minute)

    -- Kirim waktu baru ke semua pemain
    TriggerClientEvent("adminmenu:updateTime", -1, hour, minute)

    -- Notifikasi ke admin
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Admin Menu",
        description = "⏰ Time set to: " .. hour .. ":" .. minute,
        type = "success"
    })
end)


lib.callback.register("adminmenu:getPlayers", function(source)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        table.insert(players, { id = playerId, name = xPlayer.getName() })
    end
    return players
end)
