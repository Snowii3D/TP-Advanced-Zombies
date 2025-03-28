local specialZombies = {}
local redZones = {}
local fireZones = {}

-- Add event queuing system:
local EventQueue = {
    events = {},
    
    add = function(self, event)
        table.insert(self.events, event)
    end,
    
    process = function(self)
        for i = #self.events, 1, -1 do
            local event = self.events[i]
            if event.time <= GetGameTimer() then
                event.callback()
                table.remove(self.events, i)
            end
        end
    end
}

-- Function to create a special zombie
function CreateSpecialZombie(model, coords, zombieType)
    if not Config.ZombieTypes[zombieType].Enabled then return end
    
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        Wait(1)
    end
    
    local zombie = CreatePed(4, GetHashKey(model), coords.x, coords.y, coords.z, 0.0, true, false)
    
    -- Set zombie properties based on type
    if zombieType == "Stronger" then
        local zombieData = Config.ZombieTypes.Stronger.Models[model]
        if zombieData then
            SetEntityHealth(zombie, zombieData.hp)
        end
    elseif zombieType == "Runner" then
        local zombieData = Config.ZombieTypes.Runner.Models[model]
        if zombieData then
            SetPedMoveRateOverride(zombie, zombieData.speed)
        end
    elseif zombieType == "OnFire" then
        SetEntityOnFire(zombie, true)
        -- Start fire damage thread
        Citizen.CreateThread(function()
            while DoesEntityExist(zombie) and not IsEntityDead(zombie) do
                Wait(1000)
                local health = GetEntityHealth(zombie)
                SetEntityHealth(zombie, health - Config.ZombieTypes.OnFire.DamagePerSecond)
            end
        end)
    elseif zombieType == "Gas" then
        -- Create gas effect
        local gasEffect = StartParticleFxLoopedAtCoord("exp_grd_flame_lod", coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
        SetParticleFxLoopedAlpha(gasEffect, 0.5)
        SetParticleFxLoopedColour(gasEffect, 0.0, 1.0, 0.0, 0)
        SetParticleFxLoopedScale(gasEffect, Config.ZombieTypes.Gas.EffectRadius, 0)
        SetParticleFxLoopedRange(gasEffect, Config.ZombieTypes.Gas.EffectRadius)
        
        -- Start gas damage thread
        Citizen.CreateThread(function()
            while DoesEntityExist(zombie) and not IsEntityDead(zombie) do
                Wait(1000)
                local coords = GetEntityCoords(zombie)
                local players = GetActivePlayers()
                
                for _, player in ipairs(players) do
                    local ped = GetPlayerPed(player)
                    local playerCoords = GetEntityCoords(ped)
                    local distance = #(coords - playerCoords)
                    
                    if distance <= Config.ZombieTypes.Gas.EffectRadius then
                        local health = GetEntityHealth(ped)
                        SetEntityHealth(ped, health - Config.ZombieTypes.Gas.DamagePerSecond)
                    end
                end
            end
        end)
    end
    
    table.insert(specialZombies, zombie)
    return zombie
end

-- Function to handle redzone spawning
function HandleRedZoneSpawning(zoneName)
    if not Config.RedZones.Enabled then return end
    
    local zone = Config.RedZones.Zones[zoneName]
    if not zone then return end
    
    Citizen.CreateThread(function()
        while true do
            Wait(zone.SpawnRate)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local zoneCoords = vector3(zone.Pos.x, zone.Pos.y, zone.Pos.z)
            local distance = #(playerCoords - zoneCoords)
            
            if distance <= zone.Radius then
                -- Check if we're under the zombie limit
                local currentZombies = 0
                for _, zombie in pairs(entitys) do
                    if DoesEntityExist(zombie.entity) then
                        local zombieCoords = GetEntityCoords(zombie.entity)
                        local zombieDistance = #(zoneCoords - zombieCoords)
                        if zombieDistance <= zone.Radius then
                            currentZombies = currentZombies + 1
                        end
                    end
                end
                
                if currentZombies < zone.ZombieLimit then
                    -- Spawn new zombie
                    local model = zone.Models[math.random(#zone.Models)]
                    local spawnCoords = GetRandomSpawnPoint(zoneCoords, zone.SpawnDistance)
                    
                    if spawnCoords then
                        CreateSpecialZombie(model, spawnCoords, "Regular")
                    end
                end
            end
        end
    end)
end

-- Function to handle firezone effects
function HandleFireZone(zoneName)
    if not Config.FireZones.Enabled then return end
    
    local zone = Config.FireZones.Zones[zoneName]
    if not zone then return end
    
    Citizen.CreateThread(function()
        while true do
            Wait(1000)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local zoneCoords = vector3(zone.Pos.x, zone.Pos.y, zone.Pos.z)
            local distance = #(playerCoords - zoneCoords)
            
            if distance <= zone.Radius then
                -- Apply fire damage to all zombies in zone
                for _, zombie in pairs(entitys) do
                    if DoesEntityExist(zombie.entity) then
                        local zombieCoords = GetEntityCoords(zombie.entity)
                        local zombieDistance = #(zoneCoords - zombieCoords)
                        
                        if zombieDistance <= zone.Radius then
                            SetEntityOnFire(zombie.entity, true)
                            local health = GetEntityHealth(zombie.entity)
                            SetEntityHealth(zombie.entity, health - zone.DamagePerSecond)
                        end
                    end
                end
            end
        end
    end)
end

-- Helper function to get random spawn point
function GetRandomSpawnPoint(center, radius)
    local x = center.x + math.random(-radius, radius)
    local y = center.y + math.random(-radius, radius)
    local z = center.z
    
    local ground, groundZ = GetGroundZFor_3dCoord(x, y, z, 0)
    if ground then
        return vector3(x, y, groundZ)
    end
    
    return nil
end

-- Initialize redzones and firezones
Citizen.CreateThread(function()
    for zoneName, _ in pairs(Config.RedZones.Zones) do
        HandleRedZoneSpawning(zoneName)
    end
    
    for zoneName, _ in pairs(Config.FireZones.Zones) do
        HandleFireZone(zoneName)
    end
end)

-- Clean up special zombies when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    for _, zombie in pairs(specialZombies) do
        if DoesEntityExist(zombie) then
            DeleteEntity(zombie)
        end
    end
end)

-- Export functions for other resources to use
exports('CreateSpecialZombie', CreateSpecialZombie)
exports('HandleRedZoneSpawning', HandleRedZoneSpawning)
exports('HandleFireZone', HandleFireZone)

-- Use it for delayed effects:
EventQueue:add({
    time = GetGameTimer() + 1000,
    callback = function()
        -- Handle delayed effect
    end
})

-- Add validation for configuration:
local function ValidateConfig()
    local required = {
        "Framework",
        "ZombieTypes",
        "ZombieSpawning"
    }
    
    for _, key in ipairs(required) do
        if not Config[key] then
            error("Missing required config: " .. key)
        end
    end
    
    -- Validate zombie types
    for type, data in pairs(Config.ZombieTypes) do
        if data.Enabled then
            if not data.Models or #data.Models == 0 then
                error("No models defined for zombie type: " .. type)
            end
        end
    end
end

-- Recommended changes:
local function UpdateZombieTargeting()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyZombies = {}
    
    -- Use spatial partitioning
    for i, v in pairs(entitys) do
        local distance = #(GetEntityCoords(v.entity) - playerCoords)
        if distance < Config.Zombies.MaxTargetingDistance then
            table.insert(nearbyZombies, v.entity)
        end
    end
    
    -- Only update nearby zombies
    for _, zombie in ipairs(nearbyZombies) do
        TaskGoToEntity(zombie, playerPed, -1, 0.0, 500.0, 1073741824, 0)
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(100) -- Reduced from every frame to every 100ms
        if IsPedShooting(PlayerPedId()) then
            UpdateZombieTargeting()
        end
    end
end) 