AddEventHandler("playerDropped", function(reason)
    TriggerClientEvent('snowii_advanced-zombies:clearZombies', source)
end)

RegisterServerEvent("snowii_advanced-zombies:getZombieEntityOnServer")
AddEventHandler("snowii_advanced-zombies:getZombieEntityOnServer", function(data)
	TriggerClientEvent("snowii_advanced-zombies:getZombieEntityOnClient", source, data)
end)


RegisterServerEvent("snowii_advanced-zombies:onZombieSpawningStart")
AddEventHandler("snowii_advanced-zombies:onZombieSpawningStart", function()
	TriggerClientEvent("snowii_advanced-zombies:onZombieSync", source)
end)

RegisterServerEvent('snowii_advanced-zombies:SyncSpeakingSoundsOnServer')
AddEventHandler('snowii_advanced-zombies:SyncSpeakingSoundsOnServer', function(entiyCoords)

    TriggerClientEvent('snowii_advanced-zombies:SyncSpeakingSoundsOnClient', source, entiyCoords)

end)

