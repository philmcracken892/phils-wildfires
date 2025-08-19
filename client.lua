local RSGCore = exports['rsg-core']:GetCoreObject()

local activeFires = {}
local fireId = 0
local blipEntries = {} 
lib.locale()

local function CreateFire(coords)
    fireId = fireId + 1
    local currentFireId = fireId
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    local fireCoords = foundGround and vector3(coords.x, coords.y, groundZ + 0.2) or vector3(coords.x, coords.y, coords.z + 0.5)

    local fireHandle = StartScriptFire(fireCoords.x, fireCoords.y, fireCoords.z, Config.MaxFireIntensity or 2, false)
    local isVfx = false

    if not fireHandle or fireHandle == 0 then
        RequestNamedPtfxAsset('scr_ind1')
        local timeout = 0
        while not HasNamedPtfxAssetLoaded('scr_ind1') and timeout < 5000 do
            Wait(100)
            timeout = timeout + 100
        end
        if HasNamedPtfxAssetLoaded('scr_ind1') then
            fireHandle = StartParticleFxLoopedAtCoord('scr_ind1_fire', fireCoords.x, fireCoords.y, fireCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
            isVfx = true
        else
            return nil
        end
    end

    activeFires[currentFireId] = {
        coords = fireCoords,
        fireHandle = fireHandle,
        isVfx = isVfx,
        startTime = GetGameTimer()
    }

    
    SetTimeout(Config.FireDuration, function()
        if activeFires[currentFireId] then
            if activeFires[currentFireId].isVfx then
                StopParticleFxLooped(activeFires[currentFireId].fireHandle, false)
            else
                RemoveScriptFire(activeFires[currentFireId].fireHandle)
            end
            activeFires[currentFireId] = nil
        end
       
        for i = #blipEntries, 1, -1 do
            local blipEntry = blipEntries[i]
            if blipEntry.coords == fireCoords then
                Citizen.InvokeNative(0xD8C3C1E2B741C3, blipEntry.handle) 
                if Config.AddGPSRoute then
                    Citizen.InvokeNative(0xE6DE71B03C12737, 0) 
                end
                table.remove(blipEntries, i)
            end
        end
    end)

    return currentFireId
end


local function GetNearestFire(coords)
    local nearestFire = nil
    local nearestDistance = Config.ExtinguishDistance

    for id, fireData in pairs(activeFires) do
        local distance = #(coords - fireData.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestFire = { id = id, data = fireData, distance = distance }
        end
    end

    return nearestFire
end

local function ExtinguishFire(Id)
    if activeFires[Id] then
        local fireData = activeFires[Id]
        if fireData.fireHandle and fireData.fireHandle ~= 0 then
            if fireData.isVfx then
                StopParticleFxLooped(fireData.fireHandle, false)
            else
                RemoveScriptFire(fireData.fireHandle)
            end
           
            for i = #blipEntries, 1, -1 do
                local blipEntry = blipEntries[i]
                if blipEntry.coords == fireData.coords then
                    Citizen.InvokeNative(0xD8C3C1E2B741C3, blipEntry.handle) 
                    if Config.AddGPSRoute then
                        Citizen.InvokeNative(0xE6DE71B03C12737, 0) 
                    end
                    table.remove(blipEntries, i)
                end
            end
            activeFires[Id] = nil
            return true
        else
            activeFires[Id] = nil
            return false
        end
    end

    return false
end


local function GetPlayerFireCount()
    local count = 0
    for _ in pairs(activeFires) do
        count = count + 1
    end

    return count
end

RegisterNetEvent('fire:startFire', function()
    print(locale('print_cl_started'))
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    if GetPlayerFireCount() >= Config.MaxFires then
        TriggerEvent('ox_lib:notify', {
            title = locale('not_cl_1'),
            description = locale('not_cl_2'),
            type = 'error',
            duration = 3000
        })
        return
    end

    local heading = GetEntityHeading(playerPed)
    local forwardX = math.sin(math.rad(-heading))
    local forwardY = math.cos(math.rad(-heading))
    local fireCoords = vector3(coords.x + forwardX * Config.FirePlaceDistance, coords.y + forwardY * Config.FirePlaceDistance, coords.z)

    if Config.UseAnimations then
        TaskStartScenarioInPlace(playerPed, GetHashKey("WORLD_HUMAN_CROUCH_INSPECT"), -1, true, "StartScenario", 0, false)
        Wait(Config.LightFireTime)
        ClearPedTasks(playerPed)
    end

    local createdFireId = CreateFire(fireCoords)

    if createdFireId then
        TriggerEvent('ox_lib:notify', {
            title = locale('not_cl_1'),
            description = locale('not_cl_3'),
            type = 'success',
            duration = 3000
        })
        if Config.ConsumeMatches then
            TriggerServerEvent('fire:removeItem', 'matches', 1)
        end
    else
        TriggerEvent('ox_lib:notify', {
            title = locale('not_cl_1'),
            description = locale('not_cl_4'),
            type = 'error',
            duration = 3000
        })
    end
end)


RegisterNetEvent('fire:client:fireAlert', function(coords, area)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - coords) < Config.RandomFireNotifyRadius then
        local createdFireId = CreateFire(coords)
        if createdFireId then
           
            local blipText = locale('not_cl_random_fire', area)
            TriggerEvent('ox_lib:notify', {
                title = locale('not_cl_1'),
                description = blipText,
                type = 'warning',
                duration = 7000
            })
            
            local blip = BlipAddForCoords(1664425300, coords.x, coords.y, coords.z)
            SetBlipSprite(blip, joaat(Config.BlipSprite), true)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipName(blip, blipText)
            Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_MP_COLOR_4')) -- Red color
            Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_AREA_PULSE')) -- Pulsing effect
            blipEntries[#blipEntries + 1] = { coords = coords, handle = blip }
            
            if Config.AddGPSRoute then
                Citizen.InvokeNative(0xA657EC9DBC6CC900, GetHashKey('COLOR_RED')) -- StartGpsMultiRoute
                Citizen.InvokeNative(0xE24822A4C9C1A3B, coords.x, coords.y, coords.z) -- AddPointToGpsMultiRoute
                Citizen.InvokeNative(0x2A6D1DAAB3EBB43, true) -- SetGpsMultiRouteRender
            end
        else
            TriggerEvent('ox_lib:notify', {
                title = locale('not_cl_1'),
                description = locale('not_cl_4'),
                type = 'error',
                duration = 3000
            })
        end
    end
end)


RegisterNetEvent('fire:checkActiveFires', function()
    local totalFires = GetPlayerFireCount()
    TriggerServerEvent('fire:reportActiveFires', totalFires)
end)

exports['ox_target']:addGlobalPlayer({
    {
        name = 'set_player_on_fire',
        label = locale('target_set_on_fire') or 'Set Player on Fire',
        icon = 'fas fa-fire',
        distance = 2.5, 
        canInteract = function(entity, distance, coords, name)
            
            if not IsPedAPlayer(entity) or entity == PlayerPedId() then
                return false
            end
            
            return GetPlayerFireCount() < Config.MaxFires
        end,
        onSelect = function(data)
            local playerPed = PlayerPedId()
            local targetPed = data.entity
            local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))

            if not targetServerId then
                TriggerEvent('ox_lib:notify', {
                    title = locale('not_cl_1'),
                    description = locale('not_cl_4') or 'Failed to identify target player.',
                    type = 'error',
                    duration = 3000
                })
                return
            end

            
            if Config.UseAnimations then
                TaskStartScenarioInPlace(playerPed, GetHashKey("WORLD_HUMAN_CROUCH_INSPECT"), -1, true, "StartScenario", 0, false)
                Wait(Config.LightFireTime or 2000)
                ClearPedTasks(playerPed)
            end

            
            TriggerServerEvent('fire:setPlayerOnFire', targetServerId)
        end
    }
})


RegisterNetEvent('fire:client:setPlayerOnFire', function(coords)
    local createdFireId = CreateFire(vector3(coords.x, coords.y, coords.z))

    if createdFireId then
        TriggerEvent('ox_lib:notify', {
            title = locale('not_cl_1'),
            description = locale('not_cl_3') or 'Fire started successfully!',
            type = 'success',
            duration = 3000
        })
    else
        TriggerEvent('ox_lib:notify', {
            title = locale('not_cl_1'),
            description = locale('not_cl_4') or 'Failed to start fire.',
            type = 'error',
            duration = 3000
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for id, fireData in pairs(activeFires) do
            if fireData.isVfx then
                StopParticleFxLooped(fireData.fireHandle, false)
            else
                RemoveScriptFire(fireData.fireHandle)
            end
        end
        for i = 1, #blipEntries do
            Citizen.InvokeNative(0xD8C3C1E2B741C3, blipEntries[i].handle) -- RemoveBlip
        end
        if Config.AddGPSRoute then
            Citizen.InvokeNative(0xE6DE71B03C12737, 0) -- ClearGpsMultiRoute
        end
        activeFires = {}
        blipEntries = {}
    end
end)