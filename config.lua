Config = {}

-- Fire settings
Config.FireDuration = 600000 -- 10 minutes
Config.MaxFireIntensity = 3
Config.MaxFires = 5
Config.ExtinguishDistance = 4.0
Config.FirePlaceDistance = 2.0

-- Random fire settings
Config.RandomFireInterval = 1800000 -- 30 minutes
Config.RandomFireNotifyRadius = 3000000.0 -- Notify players within 300 meters
Config.AddGPSRoute = true -- Enable GPS route to fire location
Config.BlipSprite = 1754365229 
Config.BlipScale = 0.8 -- Blip scale
Config.FireSpawnLocations = {
    { coords = vector3(-295.66, 690.57, 113.39), area = "Valentine warehouse haybales" }, -- Valentine outskirts
    { coords = vector3(1294.42, -1302.48, 77.04), area = " Bank of Rhodes" }, -- Rhodes town
    { coords = vector3(2835.52, -1413.55, 45.39), area = "Saint Denis Docks" }, -- Saint Denis docks
    { coords = vector3(-3705.89, -2604.23, -13.30), area = "Armadillo Saloon" }, -- Armadillo
    { coords = vector3(2934.66, 1307.07, 44.48), area = "Annesburg Train station " } -- Annesburg
}

-- Item consumption
Config.ConsumeMatches = true
Config.ConsumeWater = true

-- Animation settings
Config.UseAnimations = true
Config.LightFireTime = 4000
Config.ExtinguishTime = 4000