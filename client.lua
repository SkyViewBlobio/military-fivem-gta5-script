-- Client-side script for military level system
-- Handles spawning, AI behavior, and cleanup of military units

local currentLevel = 0
local spawnedUnits = {}
local relationshipGroup = nil
local playerRelationshipGroup = nil

-- Configuration
local Config = {
    CHEMSEC_MODEL = "s_m_m_chemsec_01",
    JUGGERNAUT_MODEL = "u_m_y_juggernaut_01",
    CRUSADER_MODEL = "crusader",
    BARRACKS_MODEL = "barracks",
    RHINO_MODEL = "rhino",
    LAZER_MODEL = "lazer",
    
    CLEANUP_TIME = 60000, -- 1 minute
    RHINO_CLEANUP_TIME = 300000, -- 5 minutes
    RHINO_SPAWN_DISTANCE = 1000.0,
    
    RESPAWN_CHECK_INTERVAL = 5000, -- Check every 5 seconds
    LAZER_FALLBACK_FIRE_CHANCE = 0.3, -- 30% chance to use bullet fallback when vehicle weapons may not be working
    
    -- Shooting cooldown timers (in milliseconds)
    RHINO_SHOOT_COOLDOWN = 15000, -- 15 seconds between tank shots
    LAZER_SHOOT_COOLDOWN = 15000, -- 15 seconds between jet shots
}

-- Unit tracking structure
local unitTypes = {
    level1_crusaders = {},
    level2_barracks = {},
    level3_rhino = {},
    level4_lazers = {}
}

-- Initialize relationship groups
Citizen.CreateThread(function()
    -- Create custom relationship group for military units
    local handle = AddRelationshipGroup("MILITARY_ENEMY")
    relationshipGroup = GetHashKey("MILITARY_ENEMY")
    
    -- Set military units to be hostile to everyone except each other
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("CIVMALE"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("CIVFEMALE"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("COP"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("SECURITY_GUARD"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_LOST"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_MEXICAN"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_FAMILY"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_BALLAS"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_MARABUNTE"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_CULT"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_SALVA"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_WEICHENG"))
    SetRelationshipBetweenGroups(5, relationshipGroup, GetHashKey("AMBIENT_GANG_HILLBILLY"))
    SetRelationshipBetweenGroups(0, relationshipGroup, relationshipGroup) -- Friendly to each other
    
    -- Make player hostile to military units
    playerRelationshipGroup = GetPedRelationshipGroupHash(PlayerPedId())
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), relationshipGroup)
end)

-- Request model with timeout
function RequestModelAsync(model)
    local modelHash = type(model) == "string" and GetHashKey(model) or model
    
    if not IsModelValid(modelHash) then
        print("Invalid model: " .. tostring(model))
        return false
    end
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 10000 do
        Citizen.Wait(100)
        timeout = timeout + 100
    end
    
    return HasModelLoaded(modelHash)
end

-- Request weapon asset
function RequestWeaponAssetSync(weaponHash)
    if not HasWeaponAssetLoaded(weaponHash) then
        RequestWeaponAsset(weaponHash) -- Native function call
        local timeout = 0
        while not HasWeaponAssetLoaded(weaponHash) and timeout < 10000 do
            Citizen.Wait(100)
            timeout = timeout + 100
        end
    end
end

-- Create blip for vehicle
function CreateVehicleBlip(vehicle, blipSprite, blipColor, blipName)
    if not DoesEntityExist(vehicle) then
        return nil
    end
    
    local blip = AddBlipForEntity(vehicle)
    if blip then
        SetBlipSprite(blip, blipSprite)
        SetBlipColour(blip, blipColor)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipName)
        EndTextCommandSetBlipName(blip)
    end
    
    return blip
end

-- Create ped with weapons and AI settings
function CreateMilitaryPed(coords, weaponName, relationship)
    if not RequestModelAsync(Config.CHEMSEC_MODEL) then
        print("Failed to load ped model")
        return nil
    end
    
    local ped = CreatePed(4, GetHashKey(Config.CHEMSEC_MODEL), coords.x, coords.y, coords.z, 0.0, true, true)
    
    if DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        SetPedRelationshipGroupHash(ped, relationshipGroup)
        
        -- Give weapon
        local weaponHash = GetHashKey(weaponName)
        GiveWeaponToPed(ped, weaponHash, 9999, false, true)
        SetPedAmmo(ped, weaponHash, 9999)
        SetPedInfiniteAmmoClip(ped, true)
        
        -- Combat attributes
        SetPedCombatAttributes(ped, 46, true) -- Can use vehicles
        SetPedCombatAttributes(ped, 5, true) -- Can fight armed peds when not armed
        SetPedCombatAttributes(ped, 52, true) -- Use cover
        SetPedCombatAbility(ped, 100)
        SetPedCombatRange(ped, 2)
        SetPedAccuracy(ped, 60)
        SetPedFiringPattern(ped, 0xC6EE6B4C) -- Full auto
        
        SetPedAsEnemy(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatMovement(ped, 2)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        -- Task combat against nearby entities
        TaskCombatHatedTargetsAroundPed(ped, 300.0)
        
        return ped
    end
    
    return nil
end

-- Create juggernaut ped
function CreateJuggernautPed(coords, weaponName)
    if not RequestModelAsync(Config.JUGGERNAUT_MODEL) then
        print("Failed to load juggernaut model")
        return nil
    end
    
    local ped = CreatePed(4, GetHashKey(Config.JUGGERNAUT_MODEL), coords.x, coords.y, coords.z, 0.0, true, true)
    
    if DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        SetPedRelationshipGroupHash(ped, relationshipGroup)
        
        -- Set health and armor
        SetPedMaxHealth(ped, 2000)
        SetEntityHealth(ped, 2000)
        SetPedArmour(ped, 100)
        
        -- Give weapon
        local weaponHash = GetHashKey(weaponName)
        GiveWeaponToPed(ped, weaponHash, 9999, false, true)
        SetPedAmmo(ped, weaponHash, 9999)
        SetPedInfiniteAmmoClip(ped, true)
        
        -- Combat attributes
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAttributes(ped, 5, true)
        SetPedCombatAbility(ped, 100)
        SetPedCombatRange(ped, 2)
        SetPedAccuracy(ped, 70)
        
        SetPedAsEnemy(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        return ped
    end
    
    return nil
end

-- Spawn vehicle with peds
function SpawnVehicleWithPeds(vehicleModel, pedCount, weapons, spawnDistance)
    if not RequestModelAsync(vehicleModel) then
        print("Failed to load vehicle model: " .. vehicleModel)
        return nil
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Calculate spawn position
    local spawnDist = spawnDistance or 150.0
    local angle = math.random() * 2 * math.pi
    local spawnX = playerCoords.x + math.cos(angle) * spawnDist
    local spawnY = playerCoords.y + math.sin(angle) * spawnDist
    local spawnZ = playerCoords.z
    
    -- Get ground Z
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 500.0, false)
    if foundGround then
        spawnZ = groundZ + 1.0
    end
    
    -- Create vehicle
    local vehicle = CreateVehicle(GetHashKey(vehicleModel), spawnX, spawnY, spawnZ, heading, true, true)
    
    if not DoesEntityExist(vehicle) then
        print("Failed to create vehicle")
        return nil
    end
    
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDoorsLocked(vehicle, 4)
    
    local peds = {}
    local weaponList = type(weapons) == "table" and weapons or {weapons}
    
    -- Create driver
    local weaponName = weaponList[1]
    local driver = CreateMilitaryPed(vector3(spawnX, spawnY, spawnZ), weaponName, relationshipGroup)
    if driver then
        TaskWarpPedIntoVehicle(driver, vehicle, -1)
        TaskVehicleDriveWander(driver, vehicle, 40.0, 786603)
        table.insert(peds, driver)
    end
    
    -- Create passengers
    for i = 0, pedCount - 2 do
        local weaponIndex = ((i + 1) % #weaponList) + 1
        weaponName = weaponList[weaponIndex]
        local passenger = CreateMilitaryPed(vector3(spawnX, spawnY, spawnZ), weaponName, relationshipGroup)
        if passenger then
            TaskWarpPedIntoVehicle(passenger, vehicle, i)
            table.insert(peds, passenger)
        end
    end
    
    return {vehicle = vehicle, peds = peds}
end

-- Spawn Level 1: 4 Crusaders with 2 peds each
function SpawnLevel1()
    print("Spawning Level 1 units...")
    
    for i = 1, 4 do
        local unit = SpawnVehicleWithPeds(Config.CRUSADER_MODEL, 2, {"WEAPON_MUSKET", "WEAPON_MARKSMANRIFLE"}, 150.0)
        if unit then
            -- Create blip for the vehicle
            local blip = CreateVehicleBlip(unit.vehicle, 225, 1, "Military Crusader")
            
            table.insert(unitTypes.level1_crusaders, {
                vehicle = unit.vehicle,
                peds = unit.peds,
                blip = blip,
                spawnTime = GetGameTimer(),
                markedForCleanup = false
            })
        end
        Citizen.Wait(500)
    end
end

-- Spawn Level 2: 2 Barracks with 4 peds each
function SpawnLevel2()
    print("Spawning Level 2 units...")
    
    for i = 1, 2 do
        local unit = SpawnVehicleWithPeds(Config.BARRACKS_MODEL, 4, "WEAPON_MUSKET", 150.0)
        if unit then
            -- Create blip for the vehicle
            local blip = CreateVehicleBlip(unit.vehicle, 225, 1, "Military Barracks")
            
            table.insert(unitTypes.level2_barracks, {
                vehicle = unit.vehicle,
                peds = unit.peds,
                blip = blip,
                spawnTime = GetGameTimer(),
                markedForCleanup = false
            })
        end
        Citizen.Wait(500)
    end
end

-- Spawn Level 3: 1 Rhino tank
function SpawnLevel3()
    print("Spawning Level 3 units...")
    
    if not RequestModelAsync(Config.RHINO_MODEL) then
        print("Failed to load Rhino model")
        return
    end
    
    if not RequestModelAsync(Config.JUGGERNAUT_MODEL) then
        print("Failed to load Juggernaut model")
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Spawn far away
    local angle = math.random() * 2 * math.pi
    local spawnX = playerCoords.x + math.cos(angle) * Config.RHINO_SPAWN_DISTANCE
    local spawnY = playerCoords.y + math.sin(angle) * Config.RHINO_SPAWN_DISTANCE
    local spawnZ = playerCoords.z
    
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 500.0, false)
    if foundGround then
        spawnZ = groundZ + 1.0
    end
    
    -- Create Rhino
    local rhino = CreateVehicle(GetHashKey(Config.RHINO_MODEL), spawnX, spawnY, spawnZ, 0.0, true, true)
    
    if not DoesEntityExist(rhino) then
        print("Failed to create Rhino")
        return
    end
    
    SetEntityAsMissionEntity(rhino, true, true)
    SetVehicleEngineOn(rhino, true, true, false)
    
    -- Create juggernaut driver
    local driver = CreatePedInsideVehicle(rhino, 4, GetHashKey(Config.JUGGERNAUT_MODEL), -1, true, true)
    
    if DoesEntityExist(driver) then
        SetPedRelationshipGroupHash(driver, relationshipGroup)
        
        -- Set health and armor
        SetPedMaxHealth(driver, 2000)
        SetEntityHealth(driver, 2000)
        SetPedArmour(driver, 100)
        
        -- Give gusenberg
        local weaponHash = GetHashKey("WEAPON_GUSENBERG")
        GiveWeaponToPed(driver, weaponHash, 9999, false, true)
        SetPedAmmo(driver, weaponHash, 9999)
        SetPedInfiniteAmmoClip(driver, true)
        
        -- Combat settings
        SetBlockingOfNonTemporaryEvents(driver, true)
        SetPedCombatAttributes(driver, 46, true)
        SetPedAsEnemy(driver, true)
        SetPedCombatAbility(driver, 100)
        SetPedAccuracy(driver, 80)
        
        -- Set tank weapon
        SetCurrentPedVehicleWeapon(driver, GetHashKey("VEHICLE_WEAPON_TANK"))
        
        -- Create blip for the tank
        local blip = CreateVehicleBlip(rhino, 225, 1, "Military Rhino Tank")
        
        -- Store unit
        local unitData = {
            vehicle = rhino,
            driver = driver,
            blip = blip,
            spawnTime = GetGameTimer(),
            markedForCleanup = false,
            isRespawning = false,
            lastShotTime = 0 -- Track last shot time for cooldown
        }
        table.insert(unitTypes.level3_rhino, unitData)
        
        -- Start tank AI thread
        Citizen.CreateThread(function()
            RhinoAILoop(unitData)
        end)
    end
end

-- Rhino AI Loop
function RhinoAILoop(unitData)
    while DoesEntityExist(unitData.vehicle) and DoesEntityExist(unitData.driver) and not unitData.markedForCleanup do
        local driver = unitData.driver
        local vehicle = unitData.vehicle
        
        if IsPedDeadOrDying(driver, true) or not IsPedInVehicle(driver, vehicle, false) then
            break
        end
        
        -- Find nearest target (players only)
        local driverCoords = GetEntityCoords(driver)
        local nearestTarget = nil
        local nearestDist = 1000.0
        
        -- Check all players
        for _, playerId in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(playerId)
            if targetPed and DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                local dist = #(driverCoords - GetEntityCoords(targetPed))
                if dist < nearestDist then
                    nearestTarget = targetPed
                    nearestDist = dist
                end
            end
        end
        
        -- Chase and shoot target
        if nearestTarget then
            -- Make tank chase
            TaskVehicleChase(driver, nearestTarget)
            
            -- Shoot at target only if cooldown has elapsed
            local currentTime = GetGameTimer()
            if currentTime - unitData.lastShotTime >= Config.RHINO_SHOOT_COOLDOWN then
                local targetCoords = GetEntityCoords(nearestTarget)
                SetVehicleShootAtTarget(driver, nearestTarget, targetCoords.x, targetCoords.y, targetCoords.z)
                unitData.lastShotTime = currentTime
            end
        else
            -- Wander if no target
            TaskVehicleDriveWander(driver, vehicle, 30.0, 786603)
        end
        
        Citizen.Wait(200)
    end
end

-- Spawn Level 4: 2 Lazer jets
function SpawnLevel4()
    print("Spawning Level 4 units...")
    
    for i = 1, 2 do
        SpawnSingleLazer()
        Citizen.Wait(1000)
    end
end

-- Spawn a single Lazer jet
function SpawnSingleLazer()
    if not RequestModelAsync(Config.LAZER_MODEL) then
        print("Failed to load Lazer model")
        return nil
    end
    
    if not RequestModelAsync(Config.CHEMSEC_MODEL) then
        print("Failed to load pilot model")
        return nil
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Spawn in air
    local angle = math.random() * 2 * math.pi
    local spawnX = playerCoords.x + math.cos(angle) * 500.0
    local spawnY = playerCoords.y + math.sin(angle) * 500.0
    local spawnZ = playerCoords.z + 300.0
    
    -- Create Lazer
    local lazer = CreateVehicle(GetHashKey(Config.LAZER_MODEL), spawnX, spawnY, spawnZ, 0.0, true, true)
    
    if DoesEntityExist(lazer) then
        SetEntityAsMissionEntity(lazer, true, true)
        SetVehicleEngineOn(lazer, true, true, false)
        
        -- Create pilot
        local pilot = CreatePedInsideVehicle(lazer, 4, GetHashKey(Config.CHEMSEC_MODEL), -1, true, true)
        
        if DoesEntityExist(pilot) then
            SetPedRelationshipGroupHash(pilot, relationshipGroup)
            
            -- Combat settings
            SetBlockingOfNonTemporaryEvents(pilot, true)
            SetPedCombatAttributes(pilot, 46, true)
            SetPedAsEnemy(pilot, true)
            SetPedCombatAbility(pilot, 100)
            
            -- Set plane weapon
            SetCurrentPedVehicleWeapon(pilot, GetHashKey("VEHICLE_WEAPON_PLANE_ROCKET"))
            
            -- Create blip for the jet
            local blip = CreateVehicleBlip(lazer, 424, 1, "Military Lazer Jet")
            
            -- Store unit
            local unitData = {
                vehicle = lazer,
                pilot = pilot,
                blip = blip,
                spawnTime = GetGameTimer(),
                markedForCleanup = false,
                lastShotTime = 0 -- Track last shot time for cooldown
            }
            table.insert(unitTypes.level4_lazers, unitData)
            
            -- Start jet AI thread
            Citizen.CreateThread(function()
                LazerAILoop(unitData)
            end)
            
            return unitData
        end
    end
    
    return nil
end

-- Lazer AI Loop
function LazerAILoop(unitData)
    while DoesEntityExist(unitData.vehicle) and DoesEntityExist(unitData.pilot) and not unitData.markedForCleanup do
        local pilot = unitData.pilot
        local vehicle = unitData.vehicle
        
        if IsPedDeadOrDying(pilot, true) or not IsPedInVehicle(pilot, vehicle, false) then
            break
        end
        
        -- Find nearest target (players only)
        local pilotCoords = GetEntityCoords(pilot)
        local nearestTarget = nil
        local nearestDist = 2000.0
        
        -- Check all players
        for _, playerId in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(playerId)
            if targetPed and DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                local dist = #(pilotCoords - GetEntityCoords(targetPed))
                if dist < nearestDist then
                    nearestTarget = targetPed
                    nearestDist = dist
                end
            end
        end
        
        -- Chase and attack target
        if nearestTarget then
            -- Use plane mission to chase
            TaskPlaneMission(pilot, vehicle, 0, nearestTarget, 0, 0, 0, 6, 100.0, 50.0, 90.0)
            
            -- Shoot at target only if cooldown has elapsed
            local currentTime = GetGameTimer()
            if currentTime - unitData.lastShotTime >= Config.LAZER_SHOOT_COOLDOWN then
                local targetCoords = GetEntityCoords(nearestTarget)
                SetVehicleShootAtTarget(pilot, nearestTarget, targetCoords.x, targetCoords.y, targetCoords.z)
                
                -- Fallback: Use bullets if vehicle weapons fail
                if math.random() < Config.LAZER_FALLBACK_FIRE_CHANCE then
                    local lazerCoords = GetEntityCoords(vehicle)
                    ShootSingleBulletBetweenCoords(
                        lazerCoords.x, lazerCoords.y, lazerCoords.z,
                        targetCoords.x, targetCoords.y, targetCoords.z,
                        100, true, GetHashKey("WEAPON_VEHICLE_ROCKET"), pilot, true, false, 1000.0
                    )
                end
                
                unitData.lastShotTime = currentTime
            end
        else
            -- Fly around
            TaskPlaneMission(pilot, vehicle, 0, 0, 0, 0, 0, 4, 100.0, 50.0, 90.0)
        end
        
        Citizen.Wait(250)
    end
end

-- Cleanup dead/destroyed units
function CleanupUnit(unitData, isRhino)
    if unitData.markedForCleanup then
        return
    end
    
    unitData.markedForCleanup = true
    
    local cleanupTime = isRhino and Config.RHINO_CLEANUP_TIME or Config.CLEANUP_TIME
    
    Citizen.CreateThread(function()
        Citizen.Wait(cleanupTime)
        
        -- Delete peds
        if unitData.peds then
            for _, ped in ipairs(unitData.peds) do
                if DoesEntityExist(ped) then
                    DeleteEntity(ped)
                end
            end
        end
        
        if unitData.driver and DoesEntityExist(unitData.driver) then
            DeleteEntity(unitData.driver)
        end
        
        if unitData.pilot and DoesEntityExist(unitData.pilot) then
            DeleteEntity(unitData.pilot)
        end
        
        -- Remove blip
        if unitData.blip and DoesBlipExist(unitData.blip) then
            RemoveBlip(unitData.blip)
        end
        
        -- Delete vehicle (only after cleanup time for rhino)
        if unitData.vehicle and DoesEntityExist(unitData.vehicle) then
            DeleteEntity(unitData.vehicle)
        end
    end)
end

-- Monitor and respawn units
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RESPAWN_CHECK_INTERVAL)
        
        if currentLevel >= 1 then
            -- Check Level 1 Crusaders (iterate backwards to safely handle replacements)
            for i = #unitTypes.level1_crusaders, 1, -1 do
                local unit = unitTypes.level1_crusaders[i]
                if not unit.markedForCleanup then
                    local shouldCleanup = false
                    
                    -- Check if vehicle is destroyed or peds dead
                    if not DoesEntityExist(unit.vehicle) or IsEntityDead(unit.vehicle) then
                        shouldCleanup = true
                    else
                        local allDead = true
                        for _, ped in ipairs(unit.peds) do
                            if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
                                allDead = false
                                break
                            end
                        end
                        if allDead then
                            shouldCleanup = true
                        end
                    end
                    
                    if shouldCleanup then
                        CleanupUnit(unit, false)
                        -- Respawn immediately (cleanup happens in background)
                        local newUnit = SpawnVehicleWithPeds(Config.CRUSADER_MODEL, 2, {"WEAPON_MUSKET", "WEAPON_MARKSMANRIFLE"}, 150.0)
                        if newUnit then
                            -- Create blip for the respawned vehicle
                            local blip = CreateVehicleBlip(newUnit.vehicle, 225, 1, "Military Crusader")
                            
                            unitTypes.level1_crusaders[i] = {
                                vehicle = newUnit.vehicle,
                                peds = newUnit.peds,
                                blip = blip,
                                spawnTime = GetGameTimer(),
                                markedForCleanup = false
                            }
                        end
                    end
                end
            end
        end
        
        if currentLevel >= 2 then
            -- Check Level 2 Barracks (iterate backwards)
            for i = #unitTypes.level2_barracks, 1, -1 do
                local unit = unitTypes.level2_barracks[i]
                if not unit.markedForCleanup then
                    local shouldCleanup = false
                    
                    if not DoesEntityExist(unit.vehicle) or IsEntityDead(unit.vehicle) then
                        shouldCleanup = true
                    else
                        local allDead = true
                        for _, ped in ipairs(unit.peds) do
                            if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
                                allDead = false
                                break
                            end
                        end
                        if allDead then
                            shouldCleanup = true
                        end
                    end
                    
                    if shouldCleanup then
                        CleanupUnit(unit, false)
                        -- Respawn immediately (cleanup happens in background)
                        local newUnit = SpawnVehicleWithPeds(Config.BARRACKS_MODEL, 4, "WEAPON_MUSKET", 150.0)
                        if newUnit then
                            -- Create blip for the respawned vehicle
                            local blip = CreateVehicleBlip(newUnit.vehicle, 225, 1, "Military Barracks")
                            
                            unitTypes.level2_barracks[i] = {
                                vehicle = newUnit.vehicle,
                                peds = newUnit.peds,
                                blip = blip,
                                spawnTime = GetGameTimer(),
                                markedForCleanup = false
                            }
                        end
                    end
                end
            end
        end
        
        if currentLevel >= 3 then
            -- Check Level 3 Rhino (iterate backwards)
            for i = #unitTypes.level3_rhino, 1, -1 do
                local unit = unitTypes.level3_rhino[i]
                if not unit.markedForCleanup and not unit.isRespawning then
                    local shouldCleanup = false
                    
                    if not DoesEntityExist(unit.vehicle) or IsEntityDead(unit.vehicle) or 
                       not DoesEntityExist(unit.driver) or IsPedDeadOrDying(unit.driver, true) then
                        shouldCleanup = true
                    end
                    
                    if shouldCleanup then
                        unit.isRespawning = true
                        CleanupUnit(unit, true)
                        -- Respawn after 5 minutes and remove old entry
                        Citizen.CreateThread(function()
                            Citizen.Wait(Config.RHINO_CLEANUP_TIME)
                            SpawnLevel3()
                            -- Find and remove the old entry from the table
                            for j = #unitTypes.level3_rhino, 1, -1 do
                                if unitTypes.level3_rhino[j] == unit then
                                    table.remove(unitTypes.level3_rhino, j)
                                    break
                                end
                            end
                        end)
                    end
                end
            end
        end
        
        if currentLevel >= 4 then
            -- Check Level 4 Lazers (iterate backwards)
            for i = #unitTypes.level4_lazers, 1, -1 do
                local unit = unitTypes.level4_lazers[i]
                if not unit.markedForCleanup then
                    local shouldCleanup = false
                    
                    if not DoesEntityExist(unit.vehicle) or IsEntityDead(unit.vehicle) or 
                       not DoesEntityExist(unit.pilot) or IsPedDeadOrDying(unit.pilot, true) then
                        shouldCleanup = true
                    end
                    
                    if shouldCleanup then
                        CleanupUnit(unit, false)
                        -- Respawn immediately (cleanup happens in background)
                        SpawnSingleLazer()
                        -- Remove old entry from table
                        table.remove(unitTypes.level4_lazers, i)
                    end
                end
            end
        end
    end
end)

-- Display level on screen
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if currentLevel > 0 then
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 0, 0, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("Military Level: " .. currentLevel)
            DrawText(0.5, 0.05)
        end
    end
end)

-- Handle level set event from server
RegisterNetEvent('military:setLevel')
AddEventHandler('military:setLevel', function(level)
    -- Don't spawn duplicates if level is already active
    if level == currentLevel then
        print("Level " .. level .. " is already active")
        return
    end
    
    local oldLevel = currentLevel
    currentLevel = level
    
    print("Setting military level to: " .. level)
    
    -- Spawn new levels
    if level >= 1 and oldLevel < 1 then
        SpawnLevel1()
    end
    
    if level >= 2 and oldLevel < 2 then
        Citizen.Wait(1000)
        SpawnLevel2()
    end
    
    if level >= 3 and oldLevel < 3 then
        Citizen.Wait(1000)
        SpawnLevel3()
    end
    
    if level >= 4 and oldLevel < 4 then
        Citizen.Wait(1000)
        SpawnLevel4()
    end
    
    -- If level decreased, cleanup higher level units
    if level < oldLevel then
        if level < 4 and #unitTypes.level4_lazers > 0 then
            for _, unit in ipairs(unitTypes.level4_lazers) do
                CleanupUnit(unit, false)
            end
            unitTypes.level4_lazers = {}
        end
        
        if level < 3 and #unitTypes.level3_rhino > 0 then
            for _, unit in ipairs(unitTypes.level3_rhino) do
                CleanupUnit(unit, true)
            end
            unitTypes.level3_rhino = {}
        end
        
        if level < 2 and #unitTypes.level2_barracks > 0 then
            for _, unit in ipairs(unitTypes.level2_barracks) do
                CleanupUnit(unit, false)
            end
            unitTypes.level2_barracks = {}
        end
        
        if level < 1 and #unitTypes.level1_crusaders > 0 then
            for _, unit in ipairs(unitTypes.level1_crusaders) do
                CleanupUnit(unit, false)
            end
            unitTypes.level1_crusaders = {}
        end
    end
end)
