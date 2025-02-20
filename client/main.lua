local isSpectating = false
local spectatedPlayer = nil
local isGodModeActive = false
local isNoClipActive = false
local adminPermissions = {}

local function notify(title, description, type)
    lib.notify({ title = title, description = description, type = type, duration = 5000 })
end

local function toggleSpectate(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    
    if not DoesEntityExist(targetPed) then
        return notify("Admin Menu", "❌ Player not found!", "error")
    end

    isSpectating = not isSpectating
    spectatedPlayer = isSpectating and targetId or nil
    NetworkSetInSpectatorMode(isSpectating, targetPed)
    SetEntityVisible(cache.ped, not isSpectating)
    
    notify("Admin Menu", isSpectating and "👁 Now Spectating Player ID: " .. targetId or "📌 Stopped Spectating.", "info")
end

RegisterNetEvent("adminmenu:receivePermissions")
AddEventHandler("adminmenu:receivePermissions", function(permissions)
    adminPermissions = permissions
    SendNUIMessage({
        type = "updatePermissions",
        permissions = adminPermissions
    })
end)

RegisterNetEvent("adminmenu:spectate", function(targetId)
    if targetId == GetPlayerServerId(PlayerId()) then
        return notify("Admin Menu", "❌ You cannot spectate yourself!", "error")
    end
    toggleSpectate(targetId)
end)

RegisterNetEvent("adminmenu:toggle", function(state)
    SetNuiFocus(state, state)
    if state then
        lib.callback("adminmenu:getPlayers", false, function(players)
            SendNUIMessage({ type = "show", players = players })
        end)
    else
        SendNUIMessage({ type = "hide" })
    end
end)

RegisterNetEvent("adminmenu:freeze", function(state)
    FreezeEntityPosition(cache.ped, state)
    notify("Admin Menu", state and "❄️ You are frozen!" or "✅ You are unfrozen!", "info")
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

RegisterNetEvent("adminmenu:ClotingMenu")
AddEventHandler("adminmenu:ClotingMenu", function(Cloting)
    -- Kirim data ke NUI untuk menampilkan warning overlay
    SendNUIMessage({
        type = "openClothing",
        Cloting = Cloting
    })
end)

RegisterNetEvent("adminmenu:godmode", function()
    isGodModeActive = not isGodModeActive
    
    SetEntityInvincible(cache.ped, isGodModeActive)
    SetPlayerInvincible(PlayerId(), isGodModeActive)
    SetEntityCanBeDamaged(cache.ped, not isGodModeActive)
    if isGodModeActive then
        SetEntityHealth(cache.ped, 200)
        Citizen.CreateThread(function()
            while isGodModeActive do
                SetEntityHealth(cache.ped, 200)
                Citizen.Wait(100)
            end
        end)
    end
    notify("Admin Menu", isGodModeActive and "🛡️ God Mode Enabled" or "❌ God Mode Disabled", "success")
end)

RegisterNetEvent("adminmenu:fixvehicle", function()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        notify("Admin Menu", "🔧 Vehicle Fixed", "success")
    else
        notify("Admin Menu", "❌ You are not in a vehicle!", "error")
    end
end)

RegisterNetEvent("adminmenu:healself", function()
    SetEntityHealth(cache.ped, 200)
    notify("Admin Menu", "❤️ You have been healed!", "success")
end)

RegisterNetEvent("adminmenu:showWarning")
AddEventHandler("adminmenu:showWarning", function(adminName, reason)
    SendNUIMessage({
        type = "showWarning",
        adminName = adminName,
        reason = reason
    })
end)

RegisterNetEvent("adminmenu:teleportwaypoint", function()
    local waypoint = GetFirstBlipInfoId(8)
    if DoesBlipExist(waypoint) then
        SetEntityCoords(cache.ped, GetBlipCoords(waypoint), false, false, false, true)
        notify("Admin Menu", "📍 Teleported to Waypoint", "success")
    else
        notify("Admin Menu", "❌ No waypoint set!", "error")
    end
end)

RegisterNetEvent("adminmenu:invisible", function()
    local newState = not IsEntityVisible(cache.ped)
    SetEntityVisible(cache.ped, newState, false)
    notify("Admin Menu", newState and "❌ Invisible Mode Disabled" or "👻 Invisible Mode Enabled", "success")
end)

RegisterNetEvent("adminmenu:noclip")
AddEventHandler("adminmenu:noclip", function()
    isNoClipActive = not isNoClipActive

    if isNoClipActive then
        -- Aktifkan NoClip
        SetEntityAlpha(cache.ped, 150, false) -- Set transparansi (alpha = 150)
        SetEntityCollision(cache.ped, false, false) -- Nonaktifkan collision
        FreezeEntityPosition(cache.ped, true) -- Bekukan posisi ped
        SetEntityInvincible(cache.ped, true) -- Buat ped tidak bisa mati

        -- Sembunyikan player dari player lain
        SetEntityVisible(cache.ped, false, false) -- Sembunyikan dari diri sendiri
        NetworkSetEntityInvisibleToNetwork(cache.ped, true) -- Sembunyikan dari jaringan

        -- Mulai loop NoClip
        CreateThread(function()
            while isNoClipActive do
                local playerCoords = GetEntityCoords(cache.ped)
                local speed = 1.0 -- Kecepatan NoClip

                -- Dapatkan rotasi kamera
                local camRot = GetGameplayCamRot(2) -- 2 = Rotasi dalam derajat
                local forwardVector = RotToDirection(camRot) -- Vektor depan berdasarkan rotasi kamera

                -- Kontrol pergerakan NoClip
                if IsControlPressed(0, 32) then -- W (Maju)
                    playerCoords = playerCoords + forwardVector * speed
                end
                if IsControlPressed(0, 33) then -- S (Mundur)
                    playerCoords = playerCoords - forwardVector * speed
                end
                if IsControlPressed(0, 22) then -- Space (Naik)
                    playerCoords = playerCoords + vector3(0, 0, speed)
                end
                if IsControlPressed(0, 36) then -- Ctrl (Turun)
                    playerCoords = playerCoords - vector3(0, 0, speed)
                end

                -- Terapkan posisi baru
                SetEntityCoordsNoOffset(cache.ped, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)

                -- Tunggu frame berikutnyaWait(0)
            end
        end)

        lib.notify({ title = "Admin Menu", description = "✈️ NoClip Enabled", type = "success" })
    else
        -- Nonaktifkan NoClip
        ResetEntityAlpha(cache.ped) -- Kembalikan transparansi ke normal
        SetEntityCollision(cache.ped, true, true) -- Aktifkan collision
        FreezeEntityPosition(cache.ped, false) -- Lepaskan pembekuan posisi
        SetEntityInvincible(cache.ped, false) -- Buat ped bisa mati

        -- Tampilkan kembali player ke player lain
        SetEntityVisible(cache.ped, true, false) -- Tampilkan ke diri sendiri
        NetworkSetEntityInvisibleToNetwork(cache.ped, false) -- Tampilkan di jaringan

        lib.notify({ title = "Admin Menu", description = "❌ NoClip Disabled", type = "success" })
    end
end)

function RotToDirection(rotation)
    local rot = vector3(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))
    local x = -math.sin(rot.z) * math.abs(math.cos(rot.x))
    local y = math.cos(rot.z) * math.abs(math.cos(rot.x))
    local z = math.sin(rot.x)
    return vector3(x, y, z)
end

function SetEntityLocallyInvisible(entity)
    SetEntityVisible(entity, false, false)
    SetEntityLocallyInvisible(entity)
    NetworkConcealEntity(entity, true)
end

function SetEntityLocallyVisible(entity)
    SetEntityVisible(entity, true, false)
    SetEntityLocallyVisible(entity)
    NetworkConcealEntity(entity, false)
end

-- Event untuk membuka inventory pemain lain
RegisterNetEvent("adminmenu:openInventory")
AddEventHandler("adminmenu:openInventory", function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if DoesEntityExist(targetPed) then
        -- Tutup UI admin menu
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "hide" })

        -- Buka inventory pemain target menggunakan ox_inventory
        exports.ox_inventory:openInventory('player', targetId)
        lib.notify({
            title = "Admin Menu",
            description = "📦 Opened inventory of Player ID: " .. targetId,
            type = "success",
            duration = 5000
        })
    else
        lib.notify({
            title = "Admin Menu",
            description = "❌ Player not found!",
            type = "error",
            duration = 5000
        })
    end
end)

RegisterNetEvent("adminmenu:makedrunk")
AddEventHandler("adminmenu:makedrunk", function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if DoesEntityExist(targetPed) then
        -- Efek visual dan shake
        AnimpostfxPlay("DrugsMichaelAliensFight", 0, true)
        ShakeGameplayCam("DRUNK_SHAKE", 1.0)

        -- Muat animasi jalan mabuk
        RequestAnimSet("move_m@drunk@verydrunk")
        while not HasAnimSetLoaded("move_m@drunk@verydrunk") do
            Wait(100)
        end

        -- Terapkan gaya jalan mabuk
        SetPedMovementClipset(targetPed, "move_m@drunk@verydrunk", 1.0)
        lib.notify({ title = "Admin Menu", description = "🍺 Player is now drunk!", type = "success" })

        -- Hentikan efek setelah 30 detik
        Citizen.SetTimeout(30000, function()
            AnimpostfxStop("DrugsMichaelAliensFight")
            ShakeGameplayCam("DRUNK_SHAKE", 0.0)
            ResetPedMovementClipset(targetPed, 0.0)
            SetTimecycleModifier("default")
            lib.notify({ title = "Admin Menu", description = "✅ Drunk effect removed!", type = "info" })
        end)
    else
        lib.notify({ title = "Admin Menu", description = "❌ Player not found!", type = "error" })
    end
end)

RegisterNetEvent("adminmenu:makefire")
AddEventHandler("adminmenu:makefire", function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        StartScriptFire(coords.x, coords.y, coords.z, 25, false)
        lib.notify({ title = "Admin Menu", description = "🔥 Fire has been created!", type = "success" })
    else
        lib.notify({ title = "Admin Menu", description = "❌ Player not found!", type = "error" })
    end
end)

RegisterNetEvent("adminmenu:attackanimal")
AddEventHandler("adminmenu:attackanimal", function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        local hash = `a_c_mtlion`
        lib.requestModel(hash)
        while not HasModelLoaded(hash) do Wait(10) end
        local animal = CreatePed(28, hash, coords.x + 2, coords.y + 2, coords.z, 0.0, true, true)
        TaskCombatPed(animal, targetPed, 0, 16)
        lib.notify({ title = "Admin Menu", description = "🐅 A wild animal has been unleashed!", type = "success" })
    else
        lib.notify({ title = "Admin Menu", description = "❌ Player not found!", type = "error" })
    end
end)

RegisterNetEvent("adminmenu:spawnvehicle")
AddEventHandler("adminmenu:spawnvehicle", function()
    local input = lib.inputDialog("Spawn Vehicle", {
        { type = "input", label = "Enter Vehicle Name", placeholder = "e.g. adder" }
    })

    if input and input[1] then
        local vehicleName = input[1]
        local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
        RequestModel(vehicleName)
        while not HasModelLoaded(vehicleName) do Wait(10) end
        local vehicle = CreateVehicle(vehicleName, x, y, z, GetEntityHeading(PlayerPedId()), true, false)
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
        lib.notify({ title = "Admin Menu", description = "🚗 Vehicle Spawned: " .. vehicleName, type = "success" })
    else
        lib.notify({ title = "Admin Menu", description = "❌ Vehicle spawn canceled!", type = "error" })
    end
end)

local keybind = lib.addKeybind({
    name = 'adminmenu',
    description = 'press F1 open admin menu',
    defaultKey = 'F1',
    onPressed = function()
        TriggerServerEvent("adminmenu:checkAdmin")
    end
})