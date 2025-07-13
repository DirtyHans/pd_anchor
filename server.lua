local QBCore = exports['qb-core']:GetCoreObject()
local anchoredBoats = {}

-- Set anchor
RegisterNetEvent('anchor:server:setAnchor', function(boatNetId)
    local src = source

    if not boatNetId then
        return
    end

    anchoredBoats[boatNetId] = true
    TriggerClientEvent('anchor:client:setAnchor', -1, boatNetId)

    if Config.Debug then
        print(string.format("[ANCHOR DEBUG] Player %d set anchor for boat %d", src, boatNetId))
    end
end)

-- Remove anchor
RegisterNetEvent('anchor:server:removeAnchor', function(boatNetId)
    local src = source

    if not boatNetId then
        return
    end

    anchoredBoats[boatNetId] = nil
    TriggerClientEvent('anchor:client:removeAnchor', -1, boatNetId)

    if Config.Debug then
        print(string.format("[ANCHOR DEBUG] Player %d removed anchor for boat %d", src, boatNetId))
    end
end)

-- Sync anchors for new players
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    TriggerClientEvent('anchor:client:syncAnchors', src, anchoredBoats)
end)

-- Clean up anchors when boats are deleted
CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds

        for boatNetId, _ in pairs(anchoredBoats) do
            local boat = NetworkGetEntityFromNetworkId(boatNetId)
            if not DoesEntityExist(boat) then
                anchoredBoats[boatNetId] = nil
                if Config.Debug then
                    print("[ANCHOR DEBUG] Cleaned up anchor for deleted boat: " .. boatNetId)
                end
            end
        end
    end
end)
