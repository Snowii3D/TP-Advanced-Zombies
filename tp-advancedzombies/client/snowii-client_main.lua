-- tp_advanced-zombies:onPlayerZombieKill client event in order to send in server side.

zombiesList            = {}
entitys                = {}

local loadedPlayerData = true
local isDead           = false

local playerIsInSafezone = false
local isPlayerCrouching  = false

local playerCurrentZone = nil

TriggerServerEvent("tp_advanced-zombies:onZombieSpawningStart")

AddEventHandler('esx:onPlayerDeath', function(data)
    isDead = true

    closeAdvancedZombiesUI()
end)

AddEventHandler('playerSpawned', function()
	isDead = false
end)

AddEventHandler('disc-death:onPlayerRevive', function(data)
    isDead = false
end)


RegisterNetEvent("tp_advanced-zombies:setCrouchingStatus")
AddEventHandler("tp_advanced-zombies:setCrouchingStatus", function(cb)
	isPlayerCrouching = cb
end)


if Config.NotHealthRecharge then
	SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
end

if Config.MuteAmbience then
	StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
end

-- Getting the player if is dead or not based on QBCore and Standalone.
if Config.Framework == "QBCore" or Config.Framework == "Standalone" then

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)

            if NetworkIsPlayerActive(PlayerId()) then

                isDead = IsEntityDead(PlayerPedId())
            
            end
        end

    end)
end

function isPlayerDead()
    return isDead
end


if Config.Zombies.AttackPlayersOnShooting then

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
    
            if IsPedShooting(PlayerPedId()) then
    
                for i, v in pairs(entitys) do
                    TaskGoToEntity(v.entity, PlayerPedId(), -1, 0.0, 500.0, 1073741824, 0)
                end
    
            end
        end
    end)

end

if Config.Zombies.AttackPlayersBasedInDistance then

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(Config.Zombies.DistanceAttackData.SleepTime)
            StartHuntingPlayerOnDistance()
        end
    end)

    StartHuntingPlayerOnDistance = function()
        for i, v in pairs(entitys) do
            local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(v.entity), true)
            local playerPed = PlayerPedId()
            local isCrouching = isPlayerCrouching
            local isRunning = IsPedRunning(playerPed)
            local isSprinting = IsPedSprinting(playerPed)
            
            -- Get detection settings based on player movement
            local detectionSettings
            if isCrouching then
                detectionSettings = Config.SoundSystem.AttractionSounds.FootstepDetection.Crouching
            elseif isSprinting then
                detectionSettings = Config.SoundSystem.AttractionSounds.FootstepDetection.Sprinting
            elseif isRunning then
                detectionSettings = Config.SoundSystem.AttractionSounds.FootstepDetection.Running
            else
                detectionSettings = Config.SoundSystem.AttractionSounds.FootstepDetection.Walking
            end

            -- Calculate detection chance based on distance and movement
            local detectionChance = detectionSettings.DetectionChance
            local maxDistance = detectionSettings.DetectionRadius
            
            -- Reduce detection chance based on distance
            if distance > maxDistance * 0.5 then
                detectionChance = detectionChance * (1 - ((distance - (maxDistance * 0.5)) / (maxDistance * 0.5)))
            end

            -- Random chance to detect player
            local randomChance = math.random(1, 100)
            
            -- Only make zombies chase if they detect the player
            if distance <= maxDistance and randomChance <= detectionChance and not isDead then
                -- Add a small delay before chasing to prevent all zombies from aggroing at once
                Citizen.CreateThread(function()
                    Wait(math.random(0, 2000)) -- Random delay between 0-2 seconds
                    if DoesEntityExist(v.entity) then
                        TaskGoToEntity(v.entity, PlayerPedId(), -1, 0.0, 500.0, 1073741824, 0)
                    end
                end)
            end
        end
    end
end

if Config.Zombies.PlayCustomSpeakingSounds then

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(3000)

            for i, v in pairs(entitys) do

                local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(v.entity), true)
                local entityCoords = GetEntityCoords(v.entity)
    
                -- Playing zombie sounds when close to the player.
                if distance <= 30.1 and GetEntityCoords(v.entity) ~= nil then
                    
                    local randomChance = math.random(1, 99)
    
                    --Creating a 50% chance of a zombie to do a sound in order to prevent all zombies doing sounds at the same time.
                    if math.random(1, 99) >= 50 then
                        local lCoords = entityCoords
                        local eCoords = GetEntityCoords(PlayerPedId())
                        local distIs  = Vdist(lCoords.x, lCoords.y, lCoords.z, eCoords.x, eCoords.y, eCoords.z)
                    
                        local number, sounds = 0, {}
                
                        if (distIs > 10.0 and distIs <= 30.01) then
                            number = distIs / 30.0
                            sounds = Config.Zombies.SpeakingSounds.DistanceSounds.far

                        elseif (distIs <= 10.0) then
                            number = distIs / 10.0 
                            sounds = Config.Zombies.SpeakingSounds.DistanceSounds.close
                        end
                
                        local volume = round(1-number, 2)
                
                        if sounds ~= nil and next(sounds) ~= nil then
                            local _sound = sounds[ math.random( #sounds ) ]

                            SendNUIMessage({ 
                                action = "playSound",
                
                                sound = _sound, 
                                soundVolume = volume
                            })
                
                        end
                    end
    
                    --TriggerServerEvent('tp_advanced-zombies:SyncSpeakingSoundsOnServer', GetEntityCoords(v.entity))
                end
    
            end
        end
    end)
    
end

if Config.Zombies.HumanEatingAndAttackingAnimation then
    local animationSleepTime = 2000

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(animationSleepTime)

            StartHumanEatingAndAttackingAnimation()
        end
    end)

    StartHumanEatingAndAttackingAnimation = function()

        for i, v in pairs(entitys) do

            local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(v.entity), true)

            if not isPedInAVehicle() then

                -- Playing zombies animation when a player is dead.
                if distance <= 1.2 and isDead then
                    animsAction(v.entity, {lib = "amb@world_human_gardener_plant@female@idle_a", anim = "idle_a_female"}) 
                end
    
                -- Playing zombies & players animation on attack.
                if distance <= 1.2 and not isDead then

                    RequestAnimDict("misscarsteal4@actor")
                    TaskPlayAnim(v.entity,"misscarsteal4@actor","stumble",1.0, 1.0, 500, 9, 1.0, 0, 0, 0)
    
                    RequestAnimDict("misscarsteal4@actor")
                    TaskPlayAnim(PlayerPedId(),"misscarsteal4@actor","stumble",1.0, 1.0, 500, 9, 1.0, 0, 0, 0)
    
                    TaskGoToEntity(v.entity, PlayerPedId(), -1, 0.0, 500.0, 1073741824, 0)
                end

            else
                if distance <= 2.2 and not isDead then

                    RequestAnimDict("misscarsteal4@actor")
                    TaskPlayAnim(v.entity,"misscarsteal4@actor","stumble",1.0, 1.0, 500, 9, 1.0, 0, 0, 0)
    
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    TaskGoToEntity(v.entity, PlayerPedId(), -1, 0.0, 500.0, 1073741824, 0)
                end
            end   
            
        end
    end

end


-- On Zombie Peds Looting
if Config.Zombies.DropLoot and Config.Framework ~= "Standalone" then

    local markerType      = Config.Zombies.Loot.LootMarker.Type
    local scales          = {x = Config.Zombies.Loot.LootMarker.ScaleX, y = Config.Zombies.Loot.LootMarker.ScaleY, z = Config.Zombies.Loot.LootMarker.ScaleZ}
    local rgba            = {r = Config.Zombies.Loot.LootMarker.R, g = Config.Zombies.Loot.LootMarker.G, b = Config.Zombies.Loot.LootMarker.B, a = Config.Zombies.Loot.LootMarker.A}

    local markerDistance  = Config.Zombies.Loot.LootMarker.MarkerDistance
    local markerSleepTime = Config.Zombies.Loot.LootMarker.SleepTime

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
    
            local coords = GetEntityCoords(PlayerPedId())
            local letSleep = true
    
            if zombiesList then
                for k, v in pairs(zombiesList) do
    
                    local distance = GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true)
        
                    if distance < markerDistance then

                        letSleep = false
                        DrawMarker(markerType, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scales.x, scales.y, scales.z, rgba.r, rgba.g, rgba.b, rgba.a, false, false, 2, true, nil, nil, false)
                    end
                    
                end
    
            end
    
            if letSleep then
                Citizen.Wait(markerSleepTime)
            end
        end
    end)

    local droppedLootSleepTime = Config.Zombies.Loot.DropData.SleepTime
    local droppedLootDistanceToPickup = Config.Zombies.Loot.DropData.DistanceToPickup
    local droppedLootPickupKey = Config.Zombies.Loot.PickupKey

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
    
            local sleep = true
    
            local playerCoords = GetEntityCoords(PlayerPedId(), true)
            playerX, playerY, playerZ = table.unpack(playerCoords)
    
            if not IsPedInAnyVehicle(PlayerPedId(), false) then
                if zombiesList then
                    for k, v in pairs(zombiesList) do
    
                        local distance = GetDistanceBetweenCoords(playerCoords, v.x, v.y, v.z, true)
        
                        if distance <= droppedLootDistanceToPickup then
    
                            sleep = false
    
                            if Config.Zombies.Loot.LootMarker.DrawText3Ds then
                                DrawText3Ds( v.x, v.y, v.z + 0.5, Locales['press_to_search'])
                            end
            
                            if IsControlJustReleased(1, droppedLootPickupKey) then
                                if DoesEntityExist(GetPlayerPed(-1)) then

                                    RequestAnimDict("random@domestic")
                                    while not HasAnimDictLoaded("random@domestic") do
                                        Citizen.Wait(1)
                                    end
                                    TaskPlayAnim(PlayerPedId(), "random@domestic", "pickup_low", 8.0, -8, 2000, 2, 0, 0, 0, 0)

                                    TriggerServerEvent("tp_advanced-zombies:onZombiesLootReward", v.entityName)

                                    Wait(100)
                                    table.remove(zombiesList, k)

                                end
                            end
                        end
        
                    end
                end
            end
    
            if sleep then
                Citizen.Wait(droppedLootSleepTime)
            end
        end
    end)

    RegisterNetEvent("tp_advanced-zombies:getZombieEntityOnClient")
    AddEventHandler("tp_advanced-zombies:getZombieEntityOnClient", function(data)

        Wait(60000 * Config.Zombies.Loot.RemoveLootSleepTime)
    
        if zombiesList then
            for k, v in pairs(zombiesList) do
    
                if v.entity == data.entity then
                    table.remove(zombiesList, k)
                end
            end
        end
    
    end)
end

--if Config.Zombies.DropLoot and Config.Framework ~= "Standalone" then
-- On Zombie Killing counter and dropped loot system.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        StartCheckingZombiePedKills()
    end
end)

StartCheckingZombiePedKills = function()
    local dropLootChance = Config.Zombies.Loot.DropLootChance

    for i, v in pairs(entitys) do
        playerX, playerY, playerZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))

        pedX, pedY, pedZ = table.unpack(GetEntityCoords(v.entity, true))

        if not DoesEntityExist(v.entity) then
            table.remove(entitys, i)
        end

        if IsPedDeadOrDying(v.entity, 1) == 1 then
            if GetPedSourceOfDeath(v.entity) == PlayerPedId() then

                local deadZombieLocation = GetEntityCoords(v.entity, true)

                TriggerEvent("tp_advanced-zombies:onPlayerZombieKill")

                updatePlayerStatistics("zombie_kills", 1)

                if Config.Zombies.DropLoot and Config.Framework ~= "Standalone" then
                    local randomChance = math.random(0, 100)
                                
                    if Config.Debug then
                        print("Killed a {".. v.name .."} zombie ped model with a random chance of dropping loot {" .. randomChance .. " <= " .. dropLootChance .. "}.")
                    end
    
                    if randomChance <= dropLootChance then
    
                        table.insert(zombiesList,{
                            entity = v.entity,
                            entityName = v.name,
    
                            x = deadZombieLocation.x,
                            y = deadZombieLocation.y,
                            z = deadZombieLocation.z,
                        })
    
                        TriggerServerEvent("tp_advanced-zombies:getZombieEntityOnServer", {entity = v.entity, entityName = v.name, x = deadZombieLocation.x, y = deadZombieLocation.y, z = deadZombieLocation.z,} )
        
                    end
                end

                local model = GetEntityModel(v.entity)
                SetEntityAsNoLongerNeeded(v.entity)
                SetModelAsNoLongerNeeded(model)
                table.remove(entitys, i)

                Wait(2000)
            
                DeleteEntity(v.entity)
            end
        end
    end
end



AddEventHandler('tp_advanced-zombies:hasEnteredZone', function(zone, type, blockPlayerAggressiveActions, blockZombiePedSpawning)
    playerCurrentZone = zone

    if blockZombiePedSpawning then
        playerIsInSafezone = true
    end
end)

AddEventHandler('tp_advanced-zombies:hasExitedZone', function(zone)
    playerIsInSafezone = false
    playerCurrentZone  = nil
end)

RegisterNetEvent("tp_advanced-zombies:onZombieSync")
AddEventHandler("tp_advanced-zombies:onZombieSync", function()
    AddRelationshipGroup("zombie")
    SetRelationshipBetweenGroups(0, GetHashKey("zombie"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(2, GetHashKey("PLAYER"), GetHashKey("zombie"))

    local spawnZombies     = 0
    local maxSpawnDistance = Config.Zombies.MaxSpawnDistance
    local minSpawnDistance = Config.Zombies.MinSpawnDistance
    local despawnDistance  = Config.Zombies.DespawnDistance
    local spawnZombieDelay = Config.Zombies.SpawnDelay

    while true do
        Citizen.Wait(spawnZombieDelay)
        local coords = GetEntityCoords(PlayerPedId())

        if loadedPlayerData and not playerIsInSafezone then
            local canSpawnZombies = false

            if Config.Zombies.SpawnZombiesOnlyInZones then
                if Config.Zones[playerCurrentZone] and not Config.Zones[playerCurrentZone].BlockZombiePedSpawning then
                    canSpawnZombies = true
                end
            else
                canSpawnZombies = true
            end

            Wait(500)

            if canSpawnZombies then
                local TimeOfDay = GetClockHours()
                if TimeOfDay >= 18 or TimeOfDay <= 6 then
                    spawnZombies = Config.Zombies.SpawnZombieAtNight
                else
                    spawnZombies = Config.Zombies.SpawnZombieAtDaylight
                end

                Wait(100)

                if Config.Zones[playerCurrentZone] and Config.Zones[playerCurrentZone].ExtendedSpawnedZombies then
                    if Config.Zones[playerCurrentZone].ExtendedSpawnedZombies > 0 then
                        spawnZombies = spawnZombies + Config.Zones[playerCurrentZone].ExtendedSpawnedZombies
                    end
                end

                if #entitys < spawnZombies then
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local pedModelsList = {}

                    for _k1, _v1 in pairs(Config.ZombiePedModels) do
                        table.insert(pedModelsList, _v1)
                    end

                    if Config.Zones[playerCurrentZone] and Config.Zones[playerCurrentZone].ExtendedZombiePedModels then
                        for _k2, _v2 in pairs(Config.Zones[playerCurrentZone].ExtendedZombiePedModels) do
                            table.insert(pedModelsList, _v2)
                        end
                    end

                    Wait(500)

                    local EntityModel = pedModelsList[math.random(1, #pedModelsList)]
                    EntityModel = string.upper(EntityModel)
                    RequestModel(GetHashKey(EntityModel))
                    while not HasModelLoaded(GetHashKey(EntityModel)) or not HasCollisionForModelLoaded(GetHashKey(EntityModel)) do
                        Wait(1)
                    end

                    -- Improved spawn position logic
                    local spawnAttempts = 0
                    local maxAttempts = 10
                    local spawnPoint = nil
                    local canSpawn = false

                    while spawnAttempts < maxAttempts and not canSpawn do
                        spawnAttempts = spawnAttempts + 1
                        
                        -- Generate random angle and distance
                        local angle = math.random() * 2 * math.pi
                        local distance = math.random(minSpawnDistance, maxSpawnDistance)
                        
                        -- Calculate spawn position
                        local spawnX = playerCoords.x + (distance * math.cos(angle))
                        local spawnY = playerCoords.y + (distance * math.sin(angle))
                        local spawnZ = playerCoords.z + 999.0

                        -- Get ground Z coordinate
                        local ground, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ, 1)
                        
                        if ground then
                            -- Check if spawn point is valid
                            local isClear = true
                            
                            -- Check distance from other zombies
                            for _, zombie in pairs(entitys) do
                                local zombieCoords = GetEntityCoords(zombie.entity)
                                local distanceToZombie = #(vector3(spawnX, spawnY, groundZ) - zombieCoords)
                                if distanceToZombie < 10.0 then -- Minimum distance between zombies
                                    isClear = false
                                    break
                                end
                            end

                            -- Check if spawn point is in water
                            if not IsPointObscuredByAMissionEntity(spawnX, spawnY, groundZ, 5.0, 5.0, 5.0, 0) and not IsEntityInWater(GetPlayerPed(-1)) then
                                spawnPoint = vector3(spawnX, spawnY, groundZ)
                                canSpawn = true
                            end
                        end
                    end

                    if spawnPoint then
                        local entity = CreatePed(4, GetHashKey(EntityModel), spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, false, false)
                        local entityMaxHealth = Config.ZombiePedModelsData[string.lower(EntityModel)].data.health

                        SetEntityHealth(entity, entityMaxHealth)
                        local walk = Config.ZombiePedModelWalks[math.random(1, #Config.ZombiePedModelWalks)]

                        RequestAnimSet(walk)
                        while not HasAnimSetLoaded(walk) do
                            Citizen.Wait(1)
                        end

                        SetPedMovementClipset(entity, walk, 1.5)
                        TaskWanderStandard(entity, 10.0, 10)
                        SetCanAttackFriendly(entity, true, true)
                        SetPedCanEvasiveDive(entity, false)
                        SetPedRelationshipGroupHash(entity, GetHashKey("zombie"))
                        SetPedCombatAbility(entity, 0)
                        SetPedMoveRateOverride(entity, 10.0)
                        SetRunSprintMultiplierForPlayer(entity, 1.49)
                        SetPedCombatRange(entity, 0)
                        SetPedCombatMovement(entity, 0)
                        SetPedAlertness(entity, 0)
                        SetPedConfigFlag(entity, 100, 1)

                        -- Apply zombie damage effects
                        ApplyPedDamagePack(entity, "BigHitByVehicle", 1.0, 9.0)
                        ApplyPedDamagePack(entity, "SCR_Dumpster", 1.0, 9.0)
                        ApplyPedDamagePack(entity, "SCR_Torture", 1.0, 9.0)
                        ApplyPedDamagePack(entity, "Splashback_Face_0", 1.0, 9.0)
                        ApplyPedDamagePack(entity, "SCR_Cougar", 1.0, 9.0)
                        ApplyPedDamagePack(entity, "SCR_Shark", 1.0, 9.0)

                        DisablePedPainAudio(entity, true)
                        StopPedSpeaking(entity, true)
                        SetEntityAsMissionEntity(entity, true, true)
                        TaskSetBlockingOfNonTemporaryEvents(entity, true)

                        table.insert(entitys, {entity = entity, name = EntityModel})
                    end
                end
            end
        end
    end
end)

-- On Zombie Headshot Modifier System
Citizen.CreateThread(function()
    while true do
        Wait(0)

        for i, v in pairs(entitys) do
            SetPedSuffersCriticalHits(v.entity, Config.ZombiePedModelsData[string.lower(v.name)].data.headshot_instakill)
        end
    end

end)

Citizen.CreateThread(function()

    while true do
        Citizen.Wait(0)
        for i, v in pairs(entitys) do
	       	playerX, playerY, playerZ = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
			pedX, pedY, pedZ = table.unpack(GetEntityCoords(v.entity, true))
			if IsPedDeadOrDying(v.entity, 1) == 1 then
				--none :v
			else
				if(Vdist(playerX, playerY, playerZ, pedX, pedY, pedZ) < 0.6)then
					if IsPedRagdoll(v.entity, 1) ~= 1 then
						if not IsPedGettingUp(v.entity) then

							RequestAnimDict("misscarsteal4@actor")
							TaskPlayAnim(v.entity,"misscarsteal4@actor","stumble",1.0, 1.0, 500, 9, 1.0, 0, 0, 0)

							local playerPed = PlayerPedId()
                            local isPlayerInvincible = GetPlayerInvincible(PlayerId())

                            if not isPlayerInvincible and isPlayerInvincible ~= 1 and isPlayerInvincible ~= "1" then
                                local entityName = string.lower(v.name)

                                local withoutArmorDamage     = Config.ZombiePedModelsData[entityName].data.damage_without_armor
                                local armorDamage            = Config.ZombiePedModelsData[entityName].data.damage_with_armor
    
                                local armor = GetPedArmour(playerPed)
    
                                if armor > 0 then
    
                                    if armorDamage == nil or armorDamage == 0 then
                                        armorDamage = 10
                                    end
    
                                    SetPedArmour(playerPed, armor - armorDamage)
        
                                else
                                    ApplyDamageToPed(playerPed, withoutArmorDamage, false)
                                end
                            end

                
							Wait(1000)	

							-- Allowing entities to go to the player after any attack in order to keep them in track and not get bugged (Staying Frozen).
							TaskGoToEntity(v.entity, playerPed, -1, 0.0, 500.0, 1073741824, 0)
						end
					end
				end
			end
		end
    end
end)

RegisterNetEvent("tp_advanced-zombies:clearZombies")
AddEventHandler("tp_advanced-zombies:clearZombies", function()

    for i, v in pairs(entitys) do

        if not DoesEntityExist(v.entity) then
            table.remove(entitys, i)
        end

        local model = GetEntityModel(v.entity)
        SetEntityAsNoLongerNeeded(v.entity)
        SetModelAsNoLongerNeeded(model)
        DeleteEntity(v.entity)
	end
end)


AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    TriggerEvent('tp_advanced-zombies:clearZombies')
end)

-- Add new thread for zombie spawn locations
if Config.ZombieSpawnLocations.Enabled then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000) -- Check every 5 seconds
            
            for _, location in pairs(Config.ZombieSpawnLocations.Locations) do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distanceToLocation = #(playerCoords - location.coords)
                
                -- Only spawn zombies if player is within 200 units of the location
                if distanceToLocation < 200.0 then
                    local currentZombies = 0
                    
                    -- Count zombies in this location
                    for _, zombie in pairs(entitys) do
                        local zombieCoords = GetEntityCoords(zombie.entity)
                        local distanceToZombie = #(zombieCoords - location.coords)
                        if distanceToZombie < location.radius then
                            currentZombies = currentZombies + 1
                        end
                    end
                    
                    -- Spawn new zombies if needed
                    if currentZombies < location.maxZombies and math.random(1, 100) <= location.spawnChance then
                        local spawnPoint = GetRandomPointInRadius(location.coords, location.radius)
                        local model = location.models[math.random(#location.models)]
                        
                        -- Request and spawn the zombie model
                        RequestModel(GetHashKey(model))
                        while not HasModelLoaded(GetHashKey(model)) do
                            Wait(1)
                        end
                        
                        local zombie = CreatePed(4, GetHashKey(model), spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, true)
                        SetEntityAsMissionEntity(zombie, true, true)
                        SetPedCombatAttributes(zombie, 46, true)
                        SetPedCombatAbility(zombie, 2)
                        SetPedCombatMovement(zombie, 2)
                        SetPedCombatRange(zombie, 2)
                        SetPedAlertness(zombie, 3)
                        SetPedAccuracy(zombie, 100)
                        SetPedCanRagdoll(zombie, false)
                        
                        table.insert(entitys, {entity = zombie})
                    end
                end
            end
        end
    end)
end

-- Helper function to get random point in radius
function GetRandomPointInRadius(center, radius)
    local angle = math.random() * 2 * math.pi
    local r = math.sqrt(math.random()) * radius
    local x = center.x + r * math.cos(angle)
    local y = center.y + r * math.sin(angle)
    local z = center.z
    return vector3(x, y, z)
end

-- Add new thread for high-density zombie zones
if Config.ZombieSpawning.UseNaturalSpawns then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000) -- Check every 5 seconds
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local isNight = GetClockHours() >= 18 or GetClockHours() <= 6
            
            -- Check hot zones first
            for zoneName, zone in pairs(Config.ZombieSpawning.HotZones) do
                local distanceToZone = #(playerCoords - vector3(zone.center.x, zone.center.y, zone.center.z))
                
                -- Only spawn zombies if player is within 300 units of the zone
                if distanceToZone < 300.0 then
                    local currentZombies = 0
                    
                    -- Count zombies in this zone
                    for _, zombie in pairs(entitys) do
                        local zombieCoords = GetEntityCoords(zombie.entity)
                        local distanceToZombie = #(zombieCoords - vector3(zone.center.x, zone.center.y, zone.center.z))
                        if distanceToZombie < zone.radius then
                            currentZombies = currentZombies + 1
                        end
                    end
                    
                    -- Get night-specific or day settings
                    local maxZombies = isNight and (zone.maxZombiesNight or zone.maxZombies) or zone.maxZombies
                    local spawnChance = isNight and (zone.spawnChanceNight or zone.spawnChance) or zone.spawnChance
                    
                    -- Spawn new zombies if needed
                    if currentZombies < maxZombies and math.random(1, 100) <= spawnChance then
                        local spawnPoint = GetRandomPointInRadius(zone.center, zone.radius)
                        local model = zone.models[math.random(#zone.models)]
                        
                        -- Request and spawn the zombie model
                        RequestModel(GetHashKey(model))
                        while not HasModelLoaded(GetHashKey(model)) do
                            Wait(1)
                        end
                        
                        local zombie = CreatePed(4, GetHashKey(model), spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, true)
                        
                        -- Set zombie properties
                        SetEntityAsMissionEntity(zombie, true, true)
                        SetPedCombatAttributes(zombie, 46, true)
                        SetPedCombatAbility(zombie, 2)
                        SetPedCombatMovement(zombie, 2)
                        SetPedCombatRange(zombie, 2)
                        SetPedAlertness(zombie, 3)
                        SetPedAccuracy(zombie, 100)
                        SetPedCanRagdoll(zombie, false)
                        
                        -- Apply zombie damage effects
                        ApplyPedDamagePack(zombie, "BigHitByVehicle", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Dumpster", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Torture", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "Splashback_Face_0", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Cougar", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Shark", 1.0, 9.0)
                        
                        -- Set zombie behavior
                        local walk = Config.ZombiePedModelWalks[math.random(1, #Config.ZombiePedModelWalks)]
                        RequestAnimSet(walk)
                        while not HasAnimSetLoaded(walk) do
                            Wait(1)
                        end
                        SetPedMovementClipset(zombie, walk, 1.5)
                        
                        -- Add to entity list
                        table.insert(entitys, {entity = zombie, name = model})
                    end
                end
            end
            
            -- Check regular city areas
            for _, area in pairs(Config.ZombieSpawning.CityAreas) do
                local distanceToArea = #(playerCoords - vector3(area.center.x, area.center.y, area.center.z))
                
                if distanceToArea < 300.0 then
                    local currentZombies = 0
                    
                    for _, zombie in pairs(entitys) do
                        local zombieCoords = GetEntityCoords(zombie.entity)
                        local distanceToZombie = #(zombieCoords - vector3(area.center.x, area.center.y, area.center.z))
                        if distanceToZombie < area.radius then
                            currentZombies = currentZombies + 1
                        end
                    end
                    
                    -- Get night-specific or day settings
                    local maxZombies = isNight and (area.maxZombiesNight or area.maxZombies) or area.maxZombies
                    local spawnChance = isNight and (area.spawnChanceNight or area.spawnChance) or area.spawnChance
                    
                    if currentZombies < maxZombies and math.random(1, 100) <= spawnChance then
                        local spawnPoint = GetRandomPointInRadius(area.center, area.radius)
                        local model = area.models[math.random(#area.models)]
                        
                        RequestModel(GetHashKey(model))
                        while not HasModelLoaded(GetHashKey(model)) do
                            Wait(1)
                        end
                        
                        local zombie = CreatePed(4, GetHashKey(model), spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, true)
                        
                        -- Set zombie properties
                        SetEntityAsMissionEntity(zombie, true, true)
                        SetPedCombatAttributes(zombie, 46, true)
                        SetPedCombatAbility(zombie, 2)
                        SetPedCombatMovement(zombie, 2)
                        SetPedCombatRange(zombie, 2)
                        SetPedAlertness(zombie, 3)
                        SetPedAccuracy(zombie, 100)
                        SetPedCanRagdoll(zombie, false)
                        
                        -- Apply zombie damage effects
                        ApplyPedDamagePack(zombie, "BigHitByVehicle", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Dumpster", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Torture", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "Splashback_Face_0", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Cougar", 1.0, 9.0)
                        ApplyPedDamagePack(zombie, "SCR_Shark", 1.0, 9.0)
                        
                        -- Set zombie behavior
                        local walk = Config.ZombiePedModelWalks[math.random(1, #Config.ZombiePedModelWalks)]
                        RequestAnimSet(walk)
                        while not HasAnimSetLoaded(walk) do
                            Wait(1)
                        end
                        SetPedMovementClipset(zombie, walk, 1.5)
                        
                        -- Add to entity list
                        table.insert(entitys, {entity = zombie, name = model})
                    end
                end
            end
        end
    end)
end
