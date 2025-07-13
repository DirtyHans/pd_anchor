local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local anchoredBoats = {}
local currentTargetBoat = nil

-- Initialize player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Function to check if player can use anchor
local function canUseAnchor()
    if not PlayerData or not PlayerData.job then return false end

    if Config.Command.JobRestricted then
        for _, job in pairs(Config.Command.AllowedJobs) do
            if PlayerData.job.name == job then
                return true
            end
        end
        return false
    end

    return true
end

-- Function to get closest boat
local function getClosestBoat()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestBoat = nil
    local closestDistance = Config.Target.Distance or 3.0

    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in pairs(vehicles) do
        if IsThisModelABoat(GetEntityModel(vehicle)) then
            local boatCoords = GetEntityCoords(vehicle)
            local distance = #(playerCoords - boatCoords)

            if distance < closestDistance then
                closestBoat = vehicle
                closestDistance = distance
            end
        end
    end

    return closestBoat, closestDistance
end

-- Function to check if player is in driver seat of a boat
local function isInDriverSeatOfBoat()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle and vehicle ~= 0 then
        if IsThisModelABoat(GetEntityModel(vehicle)) then
            local seat = GetPedInVehicleSeat(vehicle, -1) -- -1 is driver seat
            if seat == playerPed then
                return true, vehicle
            end
        end
    end

    return false, nil
end

-- Function to update qb-target options for a boat
local function updateBoatTargetOptions(boat)
    if not boat or not DoesEntityExist(boat) then return end

    local boatNetId = NetworkGetNetworkIdFromEntity(boat)
    local isAnchored = anchoredBoats[boatNetId] or false

    -- Remove existing target first
    exports['qb-target']:RemoveTargetEntity(boat)

    -- Add updated target with current state
    local targetOptions = {
        {
            type = "client",
            event = "anchor:client:toggleFromTarget",
            icon = isAnchored and Config.Target.RemoveIcon or Config.Target.SetIcon,
            label = isAnchored and Config.Target.RemoveLabel or Config.Target.SetLabel,
            boat = boat
        }
    }

    exports['qb-target']:AddTargetEntity(boat, {
        options = targetOptions,
        distance = Config.Target.Distance
    })

    if Config.Debug then
        print(string.format("[ANCHOR DEBUG] Updated target for boat %d - Anchored: %s", boatNetId, tostring(isAnchored)))
    end
end

-- Toggle anchor function
local function toggleAnchor(boat)
    if not boat or not DoesEntityExist(boat) then
        if Config.Notifications.Enabled then
            QBCore.Functions.Notify(Config.Notifications.Messages.NoBoat, 'error', Config.Notifications.Duration)
        end
        return
    end

    local boatNetId = NetworkGetNetworkIdFromEntity(boat)

    if anchoredBoats[boatNetId] then
        -- Remove anchor
        TriggerServerEvent('anchor:server:removeAnchor', boatNetId)
    else
        -- Set anchor
        TriggerServerEvent('anchor:server:setAnchor', boatNetId)
    end
end

-- Command registration
RegisterCommand(Config.Command.Name, function()
    if not canUseAnchor() then
        if Config.Notifications.Enabled then
            QBCore.Functions.Notify(Config.Notifications.Messages.NoPermission, 'error', Config.Notifications.Duration)
        end
        return
    end

    local isInDriverSeat, boat = isInDriverSeatOfBoat()

    if isInDriverSeat and boat then
        -- Player is in driver seat, use the boat they're driving
        toggleAnchor(boat)
    else
        -- Player is not in driver seat, find closest boat
        local closestBoat = getClosestBoat()
        if closestBoat then
            toggleAnchor(closestBoat)
        else
            if Config.Notifications.Enabled then
                QBCore.Functions.Notify(Config.Notifications.Messages.NoBoat, 'error', Config.Notifications.Duration)
            end
        end
    end
end)

-- QB-Target integration
if Config.Target.Enabled then
    CreateThread(function()
        while true do
            Wait(1000) -- Check every second

            if not canUseAnchor() then
                goto continue
            end

            local playerPed = PlayerPedId()
            local isInDriverSeat, driverBoat = isInDriverSeatOfBoat()
            local targetBoat = nil

            if isInDriverSeat and driverBoat and Config.Target.ShowWhenInDriverSeat then
                -- Player is in driver seat and config allows target when in driver seat
                targetBoat = driverBoat
            elseif not isInDriverSeat then
                -- Player is not in driver seat, check for nearby boats
                targetBoat = getClosestBoat()
            end

            -- Update target if boat changed or if we need to refresh the current boat
            if targetBoat ~= currentTargetBoat then
                -- Remove old target
                if currentTargetBoat and DoesEntityExist(currentTargetBoat) then
                    exports['qb-target']:RemoveTargetEntity(currentTargetBoat)
                    if Config.Debug then
                        print("[ANCHOR DEBUG] Removed old target")
                    end
                end

                -- Add new target
                if targetBoat then
                    updateBoatTargetOptions(targetBoat)
                    currentTargetBoat = targetBoat
                else
                    currentTargetBoat = nil
                end
            elseif targetBoat and targetBoat == currentTargetBoat then
                -- Same boat, but update options in case anchor state changed
                updateBoatTargetOptions(targetBoat)
            end

            ::continue::
        end
    end)
end

-- QB-Target event handler
RegisterNetEvent('anchor:client:toggleFromTarget', function(data)
    if data and data.boat then
        toggleAnchor(data.boat)
    end
end)

-- Server events
RegisterNetEvent('anchor:client:setAnchor', function(boatNetId)
    local boat = NetworkGetEntityFromNetworkId(boatNetId)
    if DoesEntityExist(boat) then
        anchoredBoats[boatNetId] = true
        FreezeEntityPosition(boat, true)

        -- Update target options immediately
        if currentTargetBoat == boat then
            updateBoatTargetOptions(boat)
        end

        if Config.Notifications.Enabled then
            QBCore.Functions.Notify(Config.Notifications.Messages.AnchorSet, 'success', Config.Notifications.Duration)
        end

        if Config.Debug then
            print("[ANCHOR DEBUG] Anchor set for boat: " .. boatNetId)
        end
    end
end)

RegisterNetEvent('anchor:client:removeAnchor', function(boatNetId)
    local boat = NetworkGetEntityFromNetworkId(boatNetId)
    if DoesEntityExist(boat) then
        anchoredBoats[boatNetId] = nil
        FreezeEntityPosition(boat, false)

        -- Update target options immediately
        if currentTargetBoat == boat then
            updateBoatTargetOptions(boat)
        end

        if Config.Notifications.Enabled then
            QBCore.Functions.Notify(Config.Notifications.Messages.AnchorRemoved, 'success', Config.Notifications.Duration)
        end

        if Config.Debug then
            print("[ANCHOR DEBUG] Anchor removed for boat: " .. boatNetId)
        end
    end
end)

RegisterNetEvent('anchor:client:syncAnchors', function(anchors)
    for boatNetId, isAnchored in pairs(anchors) do
        local boat = NetworkGetEntityFromNetworkId(boatNetId)
        if DoesEntityExist(boat) then
            anchoredBoats[boatNetId] = isAnchored
            FreezeEntityPosition(boat, isAnchored)

            -- Update target if this is the current target boat
            if currentTargetBoat == boat then
                updateBoatTargetOptions(boat)
            end
        end
    end
end)

-- Clean up targets when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if currentTargetBoat and DoesEntityExist(currentTargetBoat) then
            exports['qb-target']:RemoveTargetEntity(currentTargetBoat)
        end
    end
end)
