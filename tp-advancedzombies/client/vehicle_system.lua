local parkedVehicles = {}
local damagedVehicles = {}

-- Initialize parked vehicles
Citizen.CreateThread(function()
    if Config.VehicleSystem.EnableParkedVehicles then
        SetParkedVehicleDensityMultiplierThisFrame(Config.VehicleSystem.ParkedVehicleDensity)
    end
end)

-- Vehicle damage system
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.VehicleSystem.VehicleDamageSettings.DamageInterval)
        
        if not Config.VehicleSystem.EnableVehicleDamage then return end
        
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleCoords = GetEntityCoords(vehicle)
            
            -- Check for zombies near the vehicle
            for _, zombie in pairs(entitys) do
                if DoesEntityExist(zombie.entity) then
                    local zombieCoords = GetEntityCoords(zombie.entity)
                    local distance = #(vehicleCoords - zombieCoords)
                    
                    if distance < 2.0 then
                        -- Apply damage to vehicle
                        if Config.VehicleSystem.VehicleDamageSettings.EngineDamage then
                            local engineHealth = GetVehicleEngineHealth(vehicle)
                            SetVehicleEngineHealth(vehicle, engineHealth - Config.VehicleSystem.VehicleDamageSettings.DamageAmount)
                        end
                        
                        -- Apply damage to player
                        if Config.VehicleSystem.VehicleDamageSettings.PlayerDamage then
                            local playerHealth = GetEntityHealth(ped)
                            SetEntityHealth(ped, playerHealth - Config.VehicleSystem.VehicleDamageSettings.DamageAmount)
                        end
                        
                        -- Play damage sound
                        exports['snowii_advanced-zombies']:Play3DSound('vehicle_damage.mp3', vehicleCoords, 0.5)
                    end
                end
            end
        end
    end
end)

-- Function to handle vehicle damage events
function HandleVehicleDamage(vehicle, damageAmount)
    if not Config.VehicleSystem.EnableVehicleDamage then return end
    
    local engineHealth = GetVehicleEngineHealth(vehicle)
    SetVehicleEngineHealth(vehicle, engineHealth - damageAmount)
    
    -- Check if vehicle is destroyed
    if engineHealth <= 0 then
        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleUndriveable(vehicle, true)
    end
end

-- Function to spawn parked vehicles
function SpawnParkedVehicle(model, coords)
    if not Config.VehicleSystem.EnableParkedVehicles then return end
    
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        Wait(1)
    end
    
    local vehicle = CreateVehicle(GetHashKey(model), coords.x, coords.y, coords.z, coords.heading, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDoorsLocked(vehicle, 2) -- Locked
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    
    table.insert(parkedVehicles, vehicle)
    return vehicle
end

-- Clean up parked vehicles when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    for _, vehicle in pairs(parkedVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
end)

-- Export functions for other resources to use
exports('HandleVehicleDamage', HandleVehicleDamage)
exports('SpawnParkedVehicle', SpawnParkedVehicle) 