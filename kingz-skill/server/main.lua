local QBCore = exports['qb-core']:GetCoreObject()
local MySQL = exports.oxmysql  -- Explicitly import oxmysql to fix 'MySQL nil' error

-- Debug function to print tables
local function dumpTable(table, indent)
    if type(table) ~= "table" then
        print("Not a table: " .. tostring(table))
        return
    end
    
    indent = indent or 0
    for k, v in pairs(table) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            dumpTable(v, indent + 1)
        else
            print(formatting .. tostring(v))
        end
    end
end

-- Save player data to DB (Using QBCore methods)
local function SavePlayerData(Player)
    if not Player then return end
    
    -- Ensure skills and reputation are tables
    local skills = Player.PlayerData.skills
    if type(skills) == "string" then
        local success, result = pcall(function() return json.decode(skills) end)
        if success and type(result) == "table" then
            skills = result
        else
            skills = {}
        end
    end
    
    local rep = Player.PlayerData.reputation
    if type(rep) == "string" then
        local success, result = pcall(function() return json.decode(rep) end)
        if success and type(result) == "table" then
            rep = result
        else
            rep = {}
        end
    end
    
    -- Update player data with parsed values
    Player.PlayerData.skills = skills
    Player.PlayerData.reputation = rep
    
    -- Let QBCore handle the database update
    Player.Functions.Save()
    
    print('[kingz-skills] Saved skills and reputation for ' .. Player.PlayerData.citizenid)
end

-- Check if player has a specific perk
local function HasPerk(Player, skillName, perkLevel)
    if not Player or not skillName then return false end
    
    -- Ensure skills is a table
    local skills = Player.PlayerData.skills
    if type(skills) == "string" then
        local success, result = pcall(function() return json.decode(skills) end)
        if success and type(result) == "table" then
            skills = result
        else
            skills = {}
        end
    end
    
    -- Check if player has the required skill level
    if not skills[skillName] or skills[skillName].level < perkLevel then
        return false
    end
    
    -- Check if the perk exists
    if not Config.SkillPerks[skillName] or not Config.SkillPerks[skillName][perkLevel] then
        return false
    end
    
    -- Return the perk effect
    return Config.SkillPerks[skillName][perkLevel].effect(Player)
end

-- Apply job bonus to skill XP gain
local function GetJobBonus(Player, skillName)
    if not Player or not skillName then return 1.0 end
    
    local job = Player.PlayerData.job.name
    if not job or not Config.JobSkillBonuses[job] then return 1.0 end
    
    return Config.JobSkillBonuses[job][skillName] or 1.0
end

-- Load player skills/rep from DB
QBCore.Functions.CreateCallback('kingz-skills:getPlayerData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    
    -- Initialize default skills and reputation
    local skills = {}
    local rep = {}
    
    -- Initialize default skills
    for skillName, skillData in pairs(Config.Skills) do
        skills[skillName] = {xp = 0, level = 1}
    end
    
    -- Initialize default reputation
    for repName, repData in pairs(Config.Reputation) do
        rep[repName] = 0
    end
    
    -- Check if Player.PlayerData.skills exists and parse it if it's a string
    if Player.PlayerData.skills then
        local playerSkills = Player.PlayerData.skills
        if type(playerSkills) == "string" then
            -- Try to parse the string as JSON
            local success, result = pcall(function() return json.decode(playerSkills) end)
            if success and type(result) == "table" then
                playerSkills = result
            else
                print("^1[kingz-skills] Failed to parse skills string: " .. playerSkills .. "^7")
                playerSkills = {}
            end
        end
        
        -- If we have valid skills data, merge it with our defaults
        if type(playerSkills) == "table" then
            for skillName, skillData in pairs(playerSkills) do
                skills[skillName] = skillData
            end
        end
    end
    
    -- Check if Player.PlayerData.reputation exists and parse it if it's a string
    if Player.PlayerData.reputation then
        local playerRep = Player.PlayerData.reputation
        if type(playerRep) == "string" then
            -- Try to parse the string as JSON
            local success, result = pcall(function() return json.decode(playerRep) end)
            if success and type(result) == "table" then
                playerRep = result
            else
                print("^1[kingz-skills] Failed to parse reputation string: " .. playerRep .. "^7")
                playerRep = {}
            end
        end
        
        -- If we have valid reputation data, merge it with our defaults
        if type(playerRep) == "table" then
            for repName, repValue in pairs(playerRep) do
                rep[repName] = repValue
            end
        end
    end
    
    -- Debug output
    print("^2[kingz-skills] Sending player data to client:^7")
    print("^3Skills:^7")
    dumpTable(skills)
    print("^3Reputation:^7")
    dumpTable(rep)
    
    -- Update player data with parsed values
    Player.PlayerData.skills = skills
    Player.PlayerData.reputation = rep
    
    -- Save to ensure database is updated with any new skills/rep
    SavePlayerData(Player)
    
    cb({skills = skills, rep = rep})
end)

-- Update Skill XP
RegisterServerEvent('kingz-skills:updateSkill')
AddEventHandler('kingz-skills:updateSkill', function(skillName, xpAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Config.Skills[skillName] then return end
    
    print("^2[kingz-skills] Adding " .. xpAmount .. " XP to " .. skillName .. " for player " .. src .. "^7")
    
    -- Apply job bonus
    local jobBonus = GetJobBonus(Player, skillName)
    xpAmount = math.floor(xpAmount * jobBonus)
    
    -- Update last used timestamp for this skill
    local lastUsed = Player.PlayerData.metadata.lastSkillUse or {}
    if type(lastUsed) == "string" then
        lastUsed = json.decode(lastUsed) or {}
    end
    
    lastUsed[skillName] = os.time()
    Player.Functions.SetMetaData('lastSkillUse', lastUsed)
    
    -- Ensure skills is a table
    local skills = Player.PlayerData.skills
    if type(skills) == "string" then
        local success, result = pcall(function() return json.decode(skills) end)
        if success and type(result) == "table" then
            skills = result
        else
            skills = {}
        end
    end
    
    -- Initialize if not exists
    if type(skills) ~= "table" then skills = {} end
    skills[skillName] = skills[skillName] or {xp = 0, level = 1}
    
    -- Apply rep bonus if applicable
    local repBonus = Config.RepBonuses[skillName]
    if repBonus then
        local rep = Player.PlayerData.reputation
        if type(rep) == "string" then
            local success, result = pcall(function() return json.decode(rep) end)
            if success and type(result) == "table" then
                rep = result
            else
                rep = {}
            end
        end
        
        local repValue = rep[repBonus.repCategory] or 0
        if repValue > 50 then
            xpAmount = math.floor(xpAmount * repBonus.bonusMultiplier)
        end
    end
    
    skills[skillName].xp = skills[skillName].xp + xpAmount
    local threshold = Config.Skills[skillName].levelThreshold * skills[skillName].level
    if skills[skillName].xp >= threshold and skills[skillName].level < Config.Skills[skillName].maxLevel then
        skills[skillName].level = skills[skillName].level + 1
        skills[skillName].xp = 0  -- Reset XP for next level
        
        -- Send notification to client
        TriggerClientEvent('kingz-skills:client:skillLevelUp', src, skillName, skills[skillName].level)
    end
    
    Player.PlayerData.skills = skills
    SavePlayerData(Player)
    
    -- Force update client data
    TriggerClientEvent('QBCore:Player:SetPlayerData', src, Player.PlayerData)
end)

-- Update Reputation
RegisterServerEvent('kingz-skills:updateRep')
AddEventHandler('kingz-skills:updateRep', function(repCategory, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Config.Reputation[repCategory] then return end
    
    print("^2[kingz-skills] Adding " .. amount .. " reputation to " .. repCategory .. " for player " .. src .. "^7")
    
    -- Ensure reputation is a table
    local rep = Player.PlayerData.reputation
    if type(rep) == "string" then
        local success, result = pcall(function() return json.decode(rep) end)
        if success and type(result) == "table" then
            rep = result
        else
            rep = {}
        end
    end
    
    -- Initialize if not exists
    if type(rep) ~= "table" then rep = {} end
    rep[repCategory] = (rep[repCategory] or 0) + amount
    rep[repCategory] = math.max(Config.Reputation[repCategory].min, math.min(Config.Reputation[repCategory].max, rep[repCategory]))
    
    Player.PlayerData.reputation = rep
    SavePlayerData(Player)
    
    -- Send notification to client
    TriggerClientEvent('kingz-skills:client:repChanged', src, repCategory, amount, rep[repCategory])
    
    -- Force update client data
    TriggerClientEvent('QBCore:Player:SetPlayerData', src, Player.PlayerData)
end)

-- Get skill perks
QBCore.Functions.CreateCallback('kingz-skills:getSkillPerks', function(source, cb, skillName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not skillName or not Config.SkillPerks[skillName] then 
        return cb({})
    end
    
    cb(Config.SkillPerks[skillName])
end)

-- Skill challenges system
local activeChallenges = {}

-- Start a challenge for a player
exports('StartChallenge', function(source, skillName, challengeIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not skillName or not Config.SkillChallenges[skillName] or not Config.SkillChallenges[skillName][challengeIndex] then
        return false, "Invalid challenge"
    end
    
    local challenge = Config.SkillChallenges[skillName][challengeIndex]
    local playerId = Player.PlayerData.citizenid
    
    -- Check if player has already completed one-time challenge
    local completedChallenges = Player.PlayerData.metadata.completedChallenges or {}
    if type(completedChallenges) == "string" then
        completedChallenges = json.decode(completedChallenges) or {}
    end
    
    local challengeId = skillName .. "_" .. challengeIndex
    if challenge.oneTime and completedChallenges[challengeId] then
        return false, "Challenge already completed"
    end
    
    -- Check level requirement
    local skills = Player.PlayerData.skills
    if type(skills) == "string" then
        skills = json.decode(skills) or {}
    end
    
    if challenge.levelRequired and (not skills[skillName] or skills[skillName].level < challenge.levelRequired) then
        return false, "Skill level too low"
    end
    
    -- Initialize challenge
    if not activeChallenges[playerId] then
        activeChallenges[playerId] = {}
    end
    
    activeChallenges[playerId][challengeId] = {
        startTime = os.time(),
        progress = 0,
        failed = false
    }
    
    -- Set time limit if applicable
    if challenge.timeLimit then
        Citizen.SetTimeout(challenge.timeLimit * 3600 * 1000, function()
            if activeChallenges[playerId] and activeChallenges[playerId][challengeId] and not activeChallenges[playerId][challengeId].completed then
                activeChallenges[playerId][challengeId].failed = true
                TriggerClientEvent('kingz-skills:client:challengeFailed', source, skillName, challengeIndex, "Time limit reached")
            end
        end)
    end
    
    TriggerClientEvent('kingz-skills:client:challengeStarted', source, skillName, challengeIndex)
    return true, "Challenge started"
end)

-- Update challenge progress
exports('UpdateChallengeProgress', function(source, skillName, challengeIndex, amount, failed)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not skillName or not Config.SkillChallenges[skillName] or not Config.SkillChallenges[skillName][challengeIndex] then
        return false
    end
    
    local challenge = Config.SkillChallenges[skillName][challengeIndex]
    local playerId = Player.PlayerData.citizenid
    local challengeId = skillName .. "_" .. challengeIndex
    
    if not activeChallenges[playerId] or not activeChallenges[playerId][challengeId] then
        return false
    end
    
    local challengeData = activeChallenges[playerId][challengeId]
    
    -- Check if challenge already failed or completed
    if challengeData.failed or challengeData.completed then
        return false
    end
    
    -- Check for failure condition
    if failed then
        if challenge.failOnMistake or challenge.failOnCrash then
            challengeData.failed = true
            TriggerClientEvent('kingz-skills:client:challengeFailed', source, skillName, challengeIndex, "Failed challenge condition")
            return false
        end
    end
    
    -- Update progress
    challengeData.progress = challengeData.progress + (amount or 1)
    
    -- Check if challenge is completed
    if challenge.target and challengeData.progress >= challenge.target then
        -- Complete the challenge
        challengeData.completed = true
        
        -- Award XP
        TriggerEvent('kingz-skills:updateSkill', source, skillName, challenge.reward)
        
        -- Mark as completed if one-time
        if challenge.oneTime then
            local completedChallenges = Player.PlayerData.metadata.completedChallenges or {}
            if type(completedChallenges) == "string" then
                completedChallenges = json.decode(completedChallenges) or {}
            end
            
            completedChallenges[challengeId] = os.time()
            Player.Functions.SetMetaData('completedChallenges', completedChallenges)
        end
        
                TriggerClientEvent('kingz-skills:client:challengeCompleted', source, skillName, challengeIndex, challenge.reward)
        return true
    end
    
    -- Notify progress if it's a multiple of 5 or at specific milestones
    if challenge.target and (challengeData.progress % 5 == 0 or challengeData.progress == math.floor(challenge.target / 2)) then
        TriggerClientEvent('kingz-skills:client:challengeProgress', source, skillName, challengeIndex, challengeData.progress, challenge.target)
    end
    
    return true
end)

-- Get all available challenges for a skill
exports('GetSkillChallenges', function(source, skillName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not skillName or not Config.SkillChallenges[skillName] then
        return {}
    end
    
    local challenges = {}
    local completedChallenges = Player.PlayerData.metadata.completedChallenges or {}
    if type(completedChallenges) == "string" then
        completedChallenges = json.decode(completedChallenges) or {}
    end
    
    local playerId = Player.PlayerData.citizenid
    
    for i, challenge in ipairs(Config.SkillChallenges[skillName]) do
        local challengeId = skillName .. "_" .. i
        local status = {
            name = challenge.name,
            description = challenge.description,
            reward = challenge.reward,
            oneTime = challenge.oneTime or false,
            completed = completedChallenges[challengeId] ~= nil,
            active = activeChallenges[playerId] and activeChallenges[playerId][challengeId] ~= nil,
            levelRequired = challenge.levelRequired or 1,
            icon = challenge.icon or "trophy"
        }
        
        if status.active then
            local activeData = activeChallenges[playerId][challengeId]
            status.progress = activeData.progress or 0
            status.failed = activeData.failed or false
            status.target = challenge.target or 0
        end
        
        table.insert(challenges, status)
    end
    
    return challenges
end)

-- Check challenge status
exports('GetChallengeStatus', function(source, skillName, challengeIndex)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not skillName or not Config.SkillChallenges[skillName] or not Config.SkillChallenges[skillName][challengeIndex] then
        return nil
    end
    
    local playerId = Player.PlayerData.citizenid
    local challengeId = skillName .. "_" .. challengeIndex
    
    if not activeChallenges[playerId] or not activeChallenges[playerId][challengeId] then
        return {
            active = false,
            completed = false,
            failed = false,
            progress = 0
        }
    end
    
    local challengeData = activeChallenges[playerId][challengeId]
    local challenge = Config.SkillChallenges[skillName][challengeIndex]
    
    return {
        active = true,
        completed = challengeData.completed or false,
        failed = challengeData.failed or false,
        progress = challengeData.progress or 0,
        target = challenge.target or 0,
        startTime = challengeData.startTime,
        timeLimit = challenge.timeLimit and (challengeData.startTime + (challenge.timeLimit * 3600)) or nil
    }
end)

-- Get reputation effect for a player
exports('GetReputationEffect', function(source, repCategory, effectType)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not repCategory or not effectType then return 0 end
    
    local rep = Player.PlayerData.reputation
    if type(rep) == "string" then
        rep = json.decode(rep) or {}
    end
    
    local repValue = rep[repCategory] or 0
    local effects = Config.ReputationEffects[repCategory]
    
    if not effects then return 0 end
    
    if repValue > 50 and effects.high and effects.high[effectType] then
        -- Return the high reputation effect
        for k, v in pairs(effects.high[effectType]) do
            return v -- Return the first effect value
        end
    elseif repValue < -50 and effects.low and effects.low[effectType] then
        -- Return the low reputation effect
        for k, v in pairs(effects.low[effectType]) do
            return v -- Return the first effect value
        end
    end
    
    return 0
end)

-- Check if player has a specific reputation effect
exports('HasReputationEffect', function(source, repCategory, effectType, effectName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not repCategory or not effectType or not effectName then return false end
    
    local rep = Player.PlayerData.reputation
    if type(rep) == "string" then
        rep = json.decode(rep) or {}
    end
    
    local repValue = rep[repCategory] or 0
    local effects = Config.ReputationEffects[repCategory]
    
    if not effects then return false end
    
    if repValue > 50 and effects.high and effects.high[effectType] and effects.high[effectType][effectName] then
        return true, effects.high[effectType][effectName]
    elseif repValue < -50 and effects.low and effects.low[effectType] and effects.low[effectType][effectName] then
        return true, effects.low[effectType][effectName]
    end
    
    return false
end)

-- Get all active reputation effects for a player
exports('GetAllReputationEffects', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local rep = Player.PlayerData.reputation
    if type(rep) == "string" then
        rep = json.decode(rep) or {}
    end
    
    local activeEffects = {}
    
    for repCategory, repValue in pairs(rep) do
        local effects = Config.ReputationEffects[repCategory]
        if effects then
            if repValue > 50 and effects.high then
                for effectType, effectData in pairs(effects.high) do
                    if not activeEffects[repCategory] then activeEffects[repCategory] = {} end
                    activeEffects[repCategory][effectType] = effectData
                end
            elseif repValue < -50 and effects.low then
                for effectType, effectData in pairs(effects.low) do
                    if not activeEffects[repCategory] then activeEffects[repCategory] = {} end
                    activeEffects[repCategory][effectType] = effectData
                end
            end
        end
    end
    
    return activeEffects
end)

-- Export the HasPerk function
exports('HasPerk', function(source, skillName, perkLevel)
    local Player = QBCore.Functions.GetPlayer(source)
    return HasPerk(Player, skillName, perkLevel)
end)

-- Get all perks for a player
exports('GetAllPerks', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local skills = Player.PlayerData.skills
    if type(skills) == "string" then
        local success, result = pcall(function() return json.decode(skills) end)
        if success and type(result) == "table" then
            skills = result
        else
            skills = {}
        end
    end
    
    local perks = {}
    
    for skillName, skillData in pairs(skills) do
        if Config.SkillPerks[skillName] then
            perks[skillName] = {}
            for perkLevel, perkData in pairs(Config.SkillPerks[skillName]) do
                if skillData.level >= perkLevel then
                    perks[skillName][perkLevel] = {
                        name = perkData.name,
                        description = perkData.description,
                        active = true
                    }
                end
            end
        end
    end
    
    return perks
end)

-- Check if player meets job skill requirements
exports('MeetsJobRequirements', function(source, job)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not job or not Config.JobSkillRequirements[job] then return true end
    
    local skills = Player.PlayerData.skills
    if type(skills) == "string" then
        skills = json.decode(skills) or {}
    end
    
    for skillName, requiredLevel in pairs(Config.JobSkillRequirements[job]) do
        if not skills[skillName] or skills[skillName].level < requiredLevel then
            return false, skillName, requiredLevel
        end
    end
    
    return true
end)

-- Skill decay system
Citizen.CreateThread(function()
    if not Config.EnableSkillDecay then return end
    
    while true do
        Citizen.Wait(3600000) -- Check every hour
        
        -- Get all online players
        local players = QBCore.Functions.GetPlayers()
        
        for _, playerId in ipairs(players) do
            local Player = QBCore.Functions.GetPlayer(playerId)
            if Player then
                -- Get player skills
                local skills = Player.PlayerData.skills
                if type(skills) == "string" then
                    skills = json.decode(skills) or {}
                end
                
                -- Get last used timestamps
                local lastUsed = Player.PlayerData.metadata.lastSkillUse or {}
                if type(lastUsed) == "string" then
                    lastUsed = json.decode(lastUsed) or {}
                end
                
                local currentTime = os.time()
                local decayThreshold = Config.SkillDecayInterval * 3600 -- Convert hours to seconds
                local skillsChanged = false
                
                -- Check each skill for decay
                for skillName, skillData in pairs(skills) do
                    -- Skip skills below exempt level
                    if skillData.level > Config.SkillDecayExemptLevel then
                        -- Check if skill hasn't been used recently
                        local lastUsedTime = lastUsed[skillName] or 0
                        if (currentTime - lastUsedTime) > decayThreshold then
                            -- Decay the skill
                            skillData.xp = math.max(0, skillData.xp - Config.SkillDecayAmount)
                            
                            -- If XP is 0 and level > 1, decrease level
                            if skillData.xp == 0 and skillData.level > 1 then
                                skillData.level = skillData.level - 1
                                -- Set XP to 75% of the new level threshold
                                local newThreshold = Config.Skills[skillName].levelThreshold * skillData.level
                                skillData.xp = math.floor(newThreshold * 0.75)
                                
                                -- Notify player
                                TriggerClientEvent('kingz-skills:client:skillDecayed', playerId, skillName, skillData.level)
                            end
                            
                            skillsChanged = true
                        end
                    end
                end
                
                -- Save if skills changed
                if skillsChanged then
                    Player.PlayerData.skills = skills
                    SavePlayerData(Player)
                end
            end
        end
    end
end)

-- Initialize player data on join
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    -- Initialize default skills and reputation
    local skills = {}
    local rep = {}
    
    -- Initialize default skills
    for skillName, skillData in pairs(Config.Skills) do
        skills[skillName] = {xp = 0, level = 1}
    end
    
    -- Initialize default reputation
    for repName, repData in pairs(Config.Reputation) do
        rep[repName] = 0
    end
    
    -- Try to load from database
    MySQL.single('SELECT skills, reputation FROM players WHERE citizenid = ?', {Player.PlayerData.citizenid}, function(result)
        if result then
            if result.skills and result.skills ~= '{}' and result.skills ~= 'null' then
                local success, dbSkills = pcall(function() return json.decode(result.skills) end)
                if success and type(dbSkills) == 'table' then
                    -- Merge with default skills (to ensure new skills are added)
                    for skillName, skillData in pairs(dbSkills) do
                        skills[skillName] = skillData
                    end
                end
            end
            
            if result.reputation and result.reputation ~= '{}' and result.reputation ~= 'null' then
                local success, dbRep = pcall(function() return json.decode(result.reputation) end)
                if success and type(dbRep) == 'table' then
                    -- Merge with default rep (to ensure new rep categories are added)
                    for repName, repValue in pairs(dbRep) do
                        rep[repName] = repValue
                    end
                end
            end
        end
        
        -- Set the player data
        Player.PlayerData.skills = skills
        Player.PlayerData.reputation = rep
        
        -- Debug output
        print("^2[kingz-skills] Player loaded with data:^7")
        print("^3Skills:^7")
        dumpTable(skills)
        print("^3Reputation:^7")
        dumpTable(rep)
        
        -- Save to ensure database is updated with any new skills/rep
        SavePlayerData(Player)
    end)
end)

-- Add a command to reset skills (for testing)
QBCore.Commands.Add('resetskills', 'Reset all skills and reputation (Admin Only)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player.PlayerData.admin then return end
    
    -- Initialize default skills
    local skills = {}
    for skillName, skillData in pairs(Config.Skills) do
        skills[skillName] = {xp = 0, level = 1}
    end
    
    -- Initialize default reputation
    local rep = {}
    for repName, repData in pairs(Config.Reputation) do
        rep[repName] = 0
    end
    
    Player.PlayerData.skills = skills
    Player.PlayerData.reputation = rep
    SavePlayerData(Player)
    
    TriggerClientEvent('kingz-skills:client:skillsReset', source)
end, 'admin')

-- Add a command to add skill XP (for testing)
QBCore.Commands.Add('addskill', 'Add XP to a skill (Admin Only)', {{name = 'skill', help = 'Skill name'}, {name = 'amount', help = 'XP amount'}}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player.PlayerData.admin then return end
    
    local skillName = args[1]
    local amount = tonumber(args[2]) or 10
    
    if not Config.Skills[skillName] then
        TriggerClientEvent('kingz-skills:client:notification', source, 'Invalid skill name!', 'error')
        return
    end
    
    TriggerEvent('kingz-skills:updateSkill', source, skillName, amount)
    TriggerClientEvent('kingz-skills:client:notification', source, 'Added ' .. amount .. ' XP to ' .. skillName, 'success')
end, 'admin')

-- Add a command to add reputation (for testing)
QBCore.Commands.Add('addrep', 'Add reputation (Admin Only)', {{name = 'category', help = 'Reputation category'}, {name = 'amount', help = 'Amount'}}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player.PlayerData.admin then return end
    
    local repCategory = args[1]
    local amount = tonumber(args[2]) or 10
    
    if not Config.Reputation[repCategory] then
        TriggerClientEvent('kingz-skills:client:notification', source, 'Invalid reputation category!', 'error')
        return
    end
    
    TriggerEvent('kingz-skills:updateRep', source, repCategory, amount)
    TriggerClientEvent('kingz-skills:client:notification', source, 'Added ' .. amount .. ' reputation to ' .. repCategory, 'success')
end, 'admin')

-- Set skill level and XP directly (for testing)
QBCore.Commands.Add('setskill', 'Set skill level and XP (Admin Only)', {{name = 'skill', help = 'Skill name'}, {name = 'level', help = 'Level'}, {name = 'xp', help = 'XP'}}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player.PlayerData.admin then return end
    
    local skillName = args[1]
    local level = tonumber(args[2]) or 1
    local xp = tonumber(args[3]) or 0
    
    if not Config.Skills[skillName] then
        TriggerClientEvent('kingz-skills:client:notification', source, 'Invalid skill name!', 'error')
        return
    end
    
    -- Ensure skills is a table
    local skills = Player.PlayerData.skills
    if type(skills) == "string" then
        skills = json.decode(skills) or {}
    end
    
    -- Initialize if not exists
    if type(skills) ~= "table" then skills = {} end
    
    -- Set skill level and XP
    skills[skillName] = {level = level, xp = xp}
    
    -- Update player data
    Player.PlayerData.skills = skills
    SavePlayerData(Player)
    
    -- Force update client data
    TriggerClientEvent('QBCore:Player:SetPlayerData', source, Player.PlayerData)
    
    TriggerClientEvent('kingz-skills:client:notification', source, 'Set ' .. skillName .. ' to level ' .. level .. ' with ' .. xp .. ' XP', 'success')
end, 'admin')

-- Set reputation value directly (for testing)
QBCore.Commands.Add('setrep', 'Set reputation value (Admin Only)', {{name = 'category', help = 'Reputation category'}, {name = 'value', help = 'Value'}}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player.PlayerData.admin then return end
    
    local repCategory = args[1]
    local value = tonumber(args[2]) or 0
    
    if not Config.Reputation[repCategory] then
        TriggerClientEvent('kingz-skills:client:notification', source, 'Invalid reputation category!', 'error')
        return
    end
    
    -- Ensure reputation is a table
    local rep = Player.PlayerData.reputation
    if type(rep) == "string" then
        rep = json.decode(rep) or {}
    end
    
    -- Initialize if not exists
    if type(rep) ~= "table" then rep = {} end
    
    -- Set reputation value
    rep[repCategory] = value
    
    -- Update player data
    Player.PlayerData.reputation = rep
    SavePlayerData(Player)
    
    -- Force update client data
    TriggerClientEvent('QBCore:Player:SetPlayerData', source, Player.PlayerData)
    
    TriggerClientEvent('kingz-skills:client:notification', source, 'Set ' .. repCategory .. ' reputation to ' .. value, 'success')
end, 'admin')

-- Callbacks for challenges
QBCore.Functions.CreateCallback('kingz-skills:getSkillChallenges', function(source, cb, skillName)
    cb(exports['kingz-skills']:GetSkillChallenges(source, skillName))
end)

QBCore.Functions.CreateCallback('kingz-skills:startChallenge', function(source, cb, skillName, challengeIndex)
    local success, message = exports['kingz-skills']:StartChallenge(source, skillName, challengeIndex)
    cb(success, message)
end)

-- Register server event for challenge progress updates
RegisterServerEvent('kingz-skills:updateChallengeProgress')
AddEventHandler('kingz-skills:updateChallengeProgress', function(skillName, challengeIndex, amount, failed)
    local src = source
    exports['kingz-skills']:UpdateChallengeProgress(src, skillName, challengeIndex, amount, failed)
end)

-- Callback for reputation effects
QBCore.Functions.CreateCallback('kingz-skills:getAllReputationEffects', function(source, cb)
    cb(exports['kingz-skills']:GetAllReputationEffects(source))
end)
