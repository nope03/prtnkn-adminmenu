Config = {}

Config.AdminPermissions = {
    ["bring"] = { "admin", "superadmin" },
    ["goto"] = { "admin", "superadmin" },
    ["freeze"] = { "admin", "superadmin" },
    ["heal"] = { "admin", "superadmin", "mod" },
    ["kick"] = { "admin", "superadmin" },
    ["ban"] = { "superadmin" },
    ["unban"] = { "superadmin" },
    ["revive"] = { "admin", "superadmin", "mod" },
    ["spectate"] = { "admin", "superadmin" },
    ["warn"] = { "admin", "superadmin", "mod" },
    ["godmode"] = { "admin", "superadmin" },
    ["noclip"] = { "admin", "superadmin" },
    ["teleportwaypoint"] = { "admin", "superadmin" },
    ["invisible"] = { "admin", "superadmin" },
    ["spawnvehicle"] = { "admin", "superadmin" },
    ["changeWeather"] = { "admin", "superadmin" },
    ["fixvehicle"] = { "admin", "superadmin" },
    ["healself"] = { "admin", "superadmin", "mod" },
    ["openInventory"] = { "admin", "superadmin" },
    ["makedrunk"] = { "admin", "superadmin" },
    ["makefire"] = { "admin", "superadmin" },
    ["attackanimal"] = { "admin", "superadmin" },
    ["openClothing"] = { "admin", "superadmin", "mod" },
    ["setTime"] = { "admin", "superadmin", "mod" },
}

Config.HasPermission = function(source, permission)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local playerGroup = xPlayer.getGroup()
    local allowedGroups = Config.AdminPermissions[permission] or {}

    for _, group in ipairs(allowedGroups) do
        if playerGroup == group then
            return true
        end
    end

    return false
end