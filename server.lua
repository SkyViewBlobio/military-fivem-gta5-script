-- Server-side script for military level system
-- Handles level state synchronization between players

local playerLevels = {}

-- Register command to set player level
RegisterCommand('level', function(source, args, rawCommand)
    if #args == 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Usage: /level <1-10> or /level <playername> <1-10>"}
        })
        return
    end
    
    -- Check if first argument is a number (self level set)
    local levelNum = tonumber(args[1])
    
    if levelNum then
        -- Setting own level
        if levelNum < 1 or levelNum > 10 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", "Level must be between 1 and 10"}
            })
            return
        end
        
        -- Store the level
        playerLevels[source] = levelNum
        
        -- Send to client to activate
        TriggerClientEvent('military:setLevel', source, levelNum)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"System", "Level set to " .. levelNum}
        })
    else
        -- Setting another player's level
        if #args < 2 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", "Usage: /level <playername> <1-10>"}
            })
            return
        end
        
        local targetName = args[1]
        local targetLevel = tonumber(args[2])
        
        if not targetLevel or targetLevel < 1 or targetLevel > 10 then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", "Level must be between 1 and 10"}
            })
            return
        end
        
        -- Find target player
        local targetPlayer = nil
        for _, playerId in ipairs(GetPlayers()) do
            local playerName = GetPlayerName(playerId)
            if playerName and string.lower(playerName) == string.lower(targetName) then
                targetPlayer = playerId
                break
            end
        end
        
        if not targetPlayer then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", "Player not found: " .. targetName}
            })
            return
        end
        
        -- Store and send level
        playerLevels[targetPlayer] = targetLevel
        TriggerClientEvent('military:setLevel', targetPlayer, targetLevel)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {"System", "Set " .. GetPlayerName(targetPlayer) .. "'s level to " .. targetLevel}
        })
        
        TriggerClientEvent('chat:addMessage', targetPlayer, {
            color = {0, 255, 0},
            multiline = true,
            args = {"System", "Your level was set to " .. targetLevel .. " by " .. GetPlayerName(source)}
        })
    end
end, false)

-- Clean up on player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    playerLevels[source] = nil
end)

-- Sync levels on player join
AddEventHandler('playerJoining', function()
    local source = source
    if playerLevels[source] then
        TriggerClientEvent('military:setLevel', source, playerLevels[source])
    end
end)
