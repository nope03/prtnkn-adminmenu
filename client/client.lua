local isSpectating = false
local spectatedPlayer = nil
local isGodModeActive = false
local isNoClipActive = false
local adminPermissions = {}
local noclipThread = nil
local laserEnabled = false
local laserThread = nil

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

function DrawLaserAndDelete()
    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRotation = GetGameplayCamRot(2)
    local direction = RotToDirection(camRotation)
    local destination = camCoords + (direction * 100.0) -- 100m range
    
    -- Draw laser
    DrawLine(camCoords, destination, 255, 0, 0, 255) -- Red laser
    
    -- Check for entity
    local rayHandle = StartShapeTestRay(camCoords, destination, -1, playerPed, 0)
    local _, hit, hitCoords, _, entityHit = GetShapeTestResult(rayHandle)
    
    if hit then
        -- Draw marker at hit position
        DrawMarker(28, hitCoords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 0, 0, 100, false, true, 2, nil, nil, false)
        
        -- Show help text
        BeginTextCommandDisplayHelp("STRING")
        AddTextComponentSubstringPlayerName("Press ~INPUT_ATTACK~ to delete entity")
        EndTextCommandDisplayHelp(0, false, true, -1)
        
        -- Delete on attack button
        if IsControlJustPressed(0, 24) then -- INPUT_ATTACK (Left Click)
            if DoesEntityExist(entityHit) then
                local entityType = GetEntityType(entityHit)
                local model = GetEntityModel(entityHit)
                
                -- Check if entity is valid for deletion
                if entityType ~= 0 and entityType ~= 1 then -- Not a player or vehicle
                    DeleteEntity(entityHit)
                    lib.notify({
                        title = "Admin Menu",
                        description = "Entity deleted successfully",
                        type = "success"
                    })
                else
                    lib.notify({
                        title = "Admin Menu",
                        description = "Cannot delete players or vehicles",
                        type = "error"
                    })
                end
            end
        end
    end
end

RegisterNetEvent('adminmenu:toggleLaser')
AddEventHandler('adminmenu:toggleLaser', function()
    laserEnabled = not laserEnabled
    
    if laserEnabled then
        lib.notify({
            title = "Admin Menu",
            description = "Laser delete mode enabled",
            type = "success"
        })
        
        laserThread = CreateThread(function()
            while laserEnabled do
                DrawLaserAndDelete()
                Wait(0)
            end
        end)
    else
        if laserThread then
            TerminateThread(laserThread)
            laserThread = nil
        end
        
        lib.notify({
            title = "Admin Menu",
            description = "Laser delete mode disabled",
            type = "info"
        })
    end
end)

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
    local playerPed = PlayerPedId()
    
    if not DoesEntityExist(playerPed) then
        lib.notify({ title = "Admin Menu", description = "❌ Player ped not found!", type = "error" })
        return
    end

    isNoClipActive = not isNoClipActive

    if isNoClipActive then
        -- Enable NoClip
        SetEntityAlpha(playerPed, 150, false)
        SetEntityCollision(playerPed, false, false)
        FreezeEntityPosition(playerPed, true)
        SetEntityInvincible(playerPed, true)
        SetEntityVisible(playerPed, false, false)
        NetworkSetEntityInvisibleToNetwork(playerPed, true)

        -- Start NoClip thread
        noclipThread = CreateThread(function()
            while isNoClipActive do
                local playerCoords = GetEntityCoords(playerPed)
                local speed = 1.0 -- Base speed
                
                -- Increase speed when holding Shift
                if IsControlPressed(0, 21) then -- Left Shift
                    speed = speed * 2.5
                end

                -- Get camera rotation
                local camRot = GetGameplayCamRot(2)
                local forwardVector = RotToDirection(camRot)

                -- Movement controls
                if IsControlPressed(0, 32) then -- W (Forward)
                    playerCoords = playerCoords + (forwardVector * speed)
                end
                if IsControlPressed(0, 33) then -- S (Backward)
                    playerCoords = playerCoords - (forwardVector * speed)
                end
                if IsControlPressed(0, 22) then -- Space (Up)
                    playerCoords = playerCoords + vector3(0, 0, speed)
                end
                if IsControlPressed(0, 36) then -- Ctrl (Down)
                    playerCoords = playerCoords - vector3(0, 0, speed)
                end

                -- Apply new position
                SetEntityCoordsNoOffset(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
                
                -- Small delay to prevent crashing
                Wait(0)
            end
        end)

        lib.notify({ title = "Admin Menu", description = "✈️ NoClip Enabled", type = "success" })
    else
        -- Disable NoClip
        if noclipThread then
            -- Terminate the thread properly
            Citizen.InvokeNative(0x9FBDA379383A52A4, noclipThread) -- Native to terminate thread
            noclipThread = nil
        end

        ResetEntityAlpha(playerPed)
        SetEntityCollision(playerPed, true, true)
        FreezeEntityPosition(playerPed, false)
        SetEntityInvincible(playerPed, false)
        SetEntityVisible(playerPed, true, false)
        NetworkSetEntityInvisibleToNetwork(playerPed, false)

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