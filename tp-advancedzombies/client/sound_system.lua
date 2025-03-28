local soundSystem = {
    active = false,
    currentType = nil,
    sounds = {},
    volume = 0.5,
    maxDistance = 50.0
}

-- Initialize sound system
Citizen.CreateThread(function()
    if Config.SoundSystem.Enabled then
        soundSystem.currentType = Config.SoundSystem.Type
        soundSystem.volume = Config.SoundSystem.Volume
        soundSystem.maxDistance = Config.SoundSystem.MaxDistance
        
        if soundSystem.currentType == "xsound" then
            exports['xsound']:State('setVolume', soundSystem.volume)
        elseif soundSystem.currentType == "sounity" then
            exports['sounity']:SetVolume(soundSystem.volume)
        end
        
        soundSystem.active = true
    end
end)

-- Function to play 3D sound
function Play3DSound(soundFile, coords, volume)
    if not soundSystem.active then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - coords)
    
    if distance <= soundSystem.maxDistance then
        local volumeMultiplier = 1.0 - (distance / soundSystem.maxDistance)
        local finalVolume = volume * volumeMultiplier
        
        if soundSystem.currentType == "xsound" then
            exports['xsound']:State('play3D', {
                soundId = soundFile,
                position = coords,
                volume = finalVolume
            })
        elseif soundSystem.currentType == "sounity" then
            exports['sounity']:Play3D(soundFile, coords.x, coords.y, coords.z, finalVolume)
        end
    end
end

-- Function to play zombie sounds
function PlayZombieSound(zombieCoords, soundType)
    if not soundSystem.active then return end
    
    local sounds = Config.Zombies.SpeakingSounds.DistanceSounds[soundType]
    if sounds then
        local randomSound = sounds[math.random(#sounds)]
        Play3DSound(randomSound, zombieCoords, soundSystem.volume)
    end
end

-- Function to handle attraction sounds
function HandleAttractionSound(coords, soundType)
    if not Config.SoundSystem.AttractionSounds[soundType] then return end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - coords)
    
    if distance <= Config.SoundSystem.AttractionSounds.MaxAttractionDistance then
        -- Trigger zombie attraction event
        TriggerServerEvent('snowii_advanced-zombies:attractZombies', coords, soundType)
    end
end

-- Event handlers for different sound types
AddEventHandler('baseevents:onPlayerDied', function()
    if Config.SoundSystem.AttractionSounds.PlayerRunning then
        HandleAttractionSound(GetEntityCoords(PlayerPedId()), 'death')
    end
end)

AddEventHandler('baseevents:onPlayerKilled', function()
    if Config.SoundSystem.AttractionSounds.Gunshots then
        HandleAttractionSound(GetEntityCoords(PlayerPedId()), 'gunshot')
    end
end)

-- Vehicle noise handler
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if Config.SoundSystem.AttractionSounds.VehicleNoise then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                local speed = GetEntitySpeed(vehicle)
                if speed > 5.0 then
                    HandleAttractionSound(GetEntityCoords(vehicle), 'vehicle')
                end
            end
        end
    end
end)

-- Export functions for other resources to use
exports('Play3DSound', Play3DSound)
exports('PlayZombieSound', PlayZombieSound)
exports('HandleAttractionSound', HandleAttractionSound) 