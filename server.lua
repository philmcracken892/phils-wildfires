local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()


local activeFireCounts = {}

RegisterNetEvent('fire:reportActiveFires', function(count)
    local src = source
    activeFireCounts[src] = count
end)


Citizen.CreateThread(function()
    while true do
        Wait(Config.RandomFireInterval)
        
        activeFireCounts = {}
        TriggerClientEvent('fire:checkActiveFires', -1)
        Wait(1000)
        
        local totalFires = 0
        for _, count in pairs(activeFireCounts) do
            totalFires = totalFires + count
        end
        if totalFires < Config.MaxFires then
            
            local randomIndex = math.random(1, #Config.FireSpawnLocations)
            local fireLocation = Config.FireSpawnLocations[randomIndex]
           
            TriggerClientEvent('fire:client:fireAlert', -1, fireLocation.coords, fireLocation.area)
            
        end
    end
end)

RSGCore.Functions.CreateUseableItem('matches', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    local hasItem = Player.Functions.GetItemByName('matches')
    if not hasItem or hasItem.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('not_sv_1'),
            description = locale('not_sv_2'),
            type = 'error',
            duration = 3000
        })
        return
    end

    TriggerClientEvent('fire:startFire', src)
end)

RegisterNetEvent('fire:removeItem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        
        return
    end

    local hasItem = Player.Functions.GetItemByName(item)
    if not hasItem or hasItem.amount < amount then
        return
    end

    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
end)


RegisterNetEvent('fire:setPlayerOnFire', function(targetServerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetServerId)

    
    if not Player then
       
        return
    end

    
    if not Target then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('not_sv_1'),
            description = locale('not_sv_4') or 'Invalid target player.',
            type = 'error',
            duration = 3000
        })
        return
    end

    
    local hasItem = Player.Functions.GetItemByName('matches')
    if not hasItem or hasItem.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('not_sv_1'),
            description = locale('not_sv_2') or 'You need matches to start a fire.',
            type = 'error',
            duration = 3000
        })
        return
    end

   
    local targetPed = GetPlayerPed(targetServerId)
    local targetCoords = GetEntityCoords(targetPed)

   

    
    if Config.ConsumeMatches then
        Player.Functions.RemoveItem('matches', 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['matches'], 'remove', 1)
    end

   
    TriggerClientEvent('fire:client:setPlayerOnFire', src, targetCoords)
end)