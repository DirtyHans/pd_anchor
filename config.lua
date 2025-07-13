Config = {}

-- Command Settings
Config.Command = {
    Name = "anchor",           -- Command name
    JobRestricted = false,     -- Set to true to restrict to specific jobs
    AllowedJobs = {           -- Jobs allowed to use anchor (only if JobRestricted is true)
        "police",
        "ambulance",
        "mechanic"
    }
}

-- Anchor Settings
Config.Anchor = {
    MaxDistance = 10.0,        -- Maximum distance from boat to use anchor
    CheckInterval = 1000,      -- How often to check anchor status (ms)
}

-- QB-Target Settings
Config.Target = {
    Enabled = true,                    -- Enable QB-Target integration
    Distance = 3.0,                    -- Interaction distance
    SetIcon = "fas fa-anchor",         -- Icon when setting anchor
    RemoveIcon = "fas fa-ship",        -- Icon when removing anchor (different icon for clarity)
    SetLabel = "Drop Anchor",          -- Label when setting anchor
    RemoveLabel = "Raise Anchor",      -- Label when removing anchor
--    ShowWhenInDriverSeat = false,       -- Show target option when in driver seat
}

-- Notification Settings
Config.Notifications = {
    Enabled = true,            -- Enable notifications
    Duration = 3000,           -- Notification duration (ms)
    Messages = {
        AnchorSet = "Anchor dropped!",
        AnchorRemoved = "Anchor raised!",
        NoBoat = "No boat nearby!",
        NoPermission = "You don't have permission to use this!"
    }
}

-- Debug Settings
Config.Debug = false  -- Enable debug prints (set to false in production)
