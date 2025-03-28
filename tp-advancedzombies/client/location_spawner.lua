local activeZombies = {}
local pedSpawnPoints = {}
local lastSpawnTimes = {}

-- Function to collect ped spawn points
local function CollectPedSpawnPoints()
    if not Config.ZombieSpawning.UseNaturalSpawns then return end
    
    -- Store current ped spawn locations
    local peds = GetGamePool('CPed')
    for _, ped in ipairs(peds) do
        if not IsPedAPlayer(ped) and not IsPedInAnyVehicle(ped, false) then
            local coords = GetEntityCoords(ped)
            table.insert(pedSpawnPoints, coords)
            DeleteEntity(ped) -- Remove original ped
        end
    end
end

-- Function to check if location is in blacklisted area
local function IsLocationBlacklisted(coords)
    for _, area in pairs(Config.ZombieSpawning.BlacklistedAreas) do
        local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(area.center.x, area.center.y, area.center.z))
        if distance <= area.radius then
            return true
        end
    end
    return false
end

-- Function to check if location is too close to players
local function IsTooCloseToPlayers(coords)
    if not Config.ZombieSpawning.PreventPlayerProximitySpawns then return false end
    
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        local ped = GetPlayerPed(player)
        local playerCoords = GetEntityCoords(ped)
        local distance = #(vector3(coords.x, coords.y, coords.z) - playerCoords)
        if distance < Config.ZombieSpawning.MinPlayerDistance then
            return true
        end
    end
    return false
end

-- Function to get area type for location
local function GetAreaType(coords)
    for areaType, data in pairs(Config.ZombieSpawning.AreaDensity) do
        local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(data.center.x, data.center.y, data.center.z))
        if distance <= data.radius then
            return areaType, data
        end
    end
    return "Rural", Config.ZombieSpawning.AreaDensity.Rural -- Default to rural
end

-- Function to spawn zombie at location
local function SpawnZombieAtLocation(coords, areaData)
    if IsTooCloseToPlayers(coords) or IsLocationBlacklisted(coords) then
        return false
    end
    
    -- Check area zombie limit
    local areaZombies = 0
    for _, zombie in pairs(activeZombies) do
        if DoesEntityExist(zombie.entity) then
            local zombieCoords = GetEntityCoords(zombie.entity)
            local distance = #(vector3(coords.x, coords.y, coords.z) - zombieCoords)
            if distance <= areaData.radius then
                areaZombies = areaZombies + 1
            end
        end
    end
    
    if areaZombies >= areaData.maxZombies then
        return false
    end
    
    -- Select zombie type based on area
    local zombieType = areaData.zombieTypes[math.random(#areaData.zombieTypes)]
    local zombieData = Config.ZombieTypes[zombieType]
    
    if zombieData and zombieData.Enabled then
        -- Get random model for this zombie type
        local model = zombieData.Models[math.random(#zombieData.Models)].model
        
        -- Create zombie
        local zombie = CreateSpecialZombie(model, coords, zombieType)
        if zombie then
            table.insert(activeZombies, {
                entity = zombie,
                type = zombieType,
                spawnTime = GetGameTimer()
            })
            return true
        end
    end
    
    return false
end

-- Function to handle special location spawning
local function HandleSpecialLocationSpawning()
    for location, data in pairs(Config.ZombieSpawning.SpecialLocations) do
        local lastSpawn = lastSpawnTimes[location] or 0
        local currentTime = GetGameTimer()
        
        if currentTime - lastSpawn >= (data.respawnTime * 1000) then
            local locationZombies = 0
            
            -- Count current zombies in location
            for _, zombie in pairs(activeZombies) do
                if DoesEntityExist(zombie.entity) then
                    local zombieCoords = GetEntityCoords(zombie.entity)
                    local distance = #(vector3(data.center.x, data.center.y, data.center.z) - zombieCoords)
                    if distance <= data.radius then
                        locationZombies = locationZombies + 1
                    end
                end
            end
            
            -- Spawn new zombies if below limit
            if locationZombies < data.maxZombies then
                local spawnPoint = vector3(
                    data.center.x + math.random(-data.radius, data.radius),
                    data.center.y + math.random(-data.radius, data.radius),
                    data.center.z
                )
                
                if not IsLocationBlacklisted(spawnPoint) and not IsTooCloseToPlayers(spawnPoint) then
                    local zombieType = data.zombieTypes[math.random(#data.zombieTypes)]
                    local zombieData = Config.ZombieTypes[zombieType]
                    
                    if zombieData and zombieData.Enabled then
                        local model = zombieData.Models[math.random(#zombieData.Models)].model
                        local zombie = CreateSpecialZombie(model, spawnPoint, zombieType)
                        
                        if zombie then
                            table.insert(activeZombies, {
                                entity = zombie,
                                type = zombieType,
                                spawnTime = currentTime
                            })
                            lastSpawnTimes[location] = currentTime
                        end
                    end
                end
            end
        end
    end
end

-- Main spawn management thread
Citizen.CreateThread(function()
    -- Initial collection of spawn points
    CollectPedSpawnPoints()
    
    while true do
        Citizen.Wait(1000)
        
        -- Handle natural spawns
        if Config.ZombieSpawning.UseNaturalSpawns then
            for _, spawnPoint in ipairs(pedSpawnPoints) do
                local areaType, areaData = GetAreaType(spawnPoint)
                
                -- Random chance to spawn based on density
                if math.random() <= areaData.density then
                    SpawnZombieAtLocation(spawnPoint, areaData)
                end
            end
        end
        
        -- Handle special location spawns
        HandleSpecialLocationSpawning()
        
        -- Cleanup dead or far zombies
        for i = #activeZombies, 1, -1 do
            local zombie = activeZombies[i]
            if not DoesEntityExist(zombie.entity) or IsEntityDead(zombie.entity) then
                table.remove(activeZombies, i)
            end
        end
    end
end)

-- Export functions
exports('GetActiveZombies', function() return activeZombies end)
exports('SpawnZombieAtLocation', SpawnZombieAtLocation)
exports('IsLocationBlacklisted', IsLocationBlacklisted) 