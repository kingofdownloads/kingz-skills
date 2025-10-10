-- Initialize QBCore
local QBCore = nil
Citizen.CreateThread(function()
    while QBCore == nil do
        QBCore = exports['qb-core']:GetCoreObject()
        Citizen.Wait(0)
    end
end)

-- Function to count table keys (since table.keys doesn't exist)
local function countTableKeys(tbl)
    if type(tbl) ~= 'table' then return 0 end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Function to refresh player data
function RefreshPlayerData()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        print("^2[kingz-skills] Refreshing player data^7")
    end)
end

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

-- Function to get reputation status and color
local function GetReputationStatus(value)
    local status, colorScheme
    
    if value > 75 then
        status = "Very High"
        colorScheme = "green"
    elseif value > 50 then
        status = "High"
        colorScheme = "green"
    elseif value > 25 then
        status = "Positive"
        colorScheme = "green"
    elseif value > 0 then
        status = "Slightly Positive"
        colorScheme = "green"
    elseif value == 0 then
        status = "Neutral"
        colorScheme = "yellow"
    elseif value > -25 then
        status = "Slightly Negative"
        colorScheme = "red"
    elseif value > -50 then
        status = "Negative"
        colorScheme = "red"
    elseif value > -75 then
        status = "Low"
        colorScheme = "red"
    else
        status = "Very Low"
        colorScheme = "red"
    end
    
    return status, colorScheme
end

-- Command to check skills/rep (using ox_lib context menu)
RegisterCommand('showskills', function()
    if not QBCore then return end
    
    -- Show loading spinner while fetching data
    lib.progressCircle({
        duration = 500,
        position = 'bottom',
        label = 'Loading skills data...',
        useWhileDead = true,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    })
    
    QBCore.Functions.TriggerCallback('kingz-skills:getPlayerData', function(data)
        if not data then 
            lib.notify({
                id = 'skills_error',
                title = 'Skills System',
                description = 'No skills data available',
                position = 'top-right',
                style = {
                    backgroundColor = '#141517',
                    color = '#C1C2C5',
                    ['.description'] = {
                        color = '#909296'
                    }
                },
                icon = 'ban',
                iconColor = '#ff0000',
                type = 'error'
            })
            return 
        end
        
        -- Debug output
        print("^2[kingz-skills] Received player data:^7")
        print("^3Skills:^7")
        dumpTable(data.skills)
        print("^3Reputation:^7")
        dumpTable(data.rep)
        
        -- Create menu options for ox_lib context menu
        local options = {}
        
        -- Skills section
        if data.skills and type(data.skills) == 'table' and next(data.skills) then
            -- Add skills category header
            table.insert(options, {
                title = '🎯 Skills',
                description = 'Your character\'s abilities and expertise',
                metadata = {
                    {label = 'Total Skills', value = countTableKeys(data.skills)},
                },
                disabled = true
            })
            
            -- Add skills to menu with progress bars
            for skillName, skillData in pairs(data.skills) do
                local configSkill = Config.Skills[skillName]
                if configSkill and type(skillData) == 'table' then
                    -- Calculate progress percentage
                    local threshold = configSkill.levelThreshold * (skillData.level or 1)
                    local progress = math.floor(((skillData.xp or 0) / threshold) * 100)
                    
                    -- Add icon if available
                    local icon = configSkill.icon or "star"
                    
                    table.insert(options, {
                        title = configSkill.label,
                        description = configSkill.description,
                        progress = progress,
                        colorScheme = configSkill.color or 'blue',
                        metadata = {
                            {label = 'Level', value = skillData.level or 1},
                            {label = 'XP', value = (skillData.xp or 0) .. '/' .. threshold},
                            {label = 'Progress', value = progress .. '%'},
                        },
                        icon = icon,
                        onSelect = function()
                            TriggerEvent('kingz-skills:client:showSkillDetails', {
                                skillName = skillName,
                                skillData = skillData,
                                configSkill = configSkill
                            })
                        end
                    })
                end
            end
        else
            -- No skills found
            table.insert(options, {
                title = 'No Skills Found',
                description = 'You haven\'t developed any skills yet.',
                disabled = true,
                icon = 'circle-exclamation'
            })
        end
        
        -- Reputation section
        if data.rep and type(data.rep) == 'table' and next(data.rep) then
            -- Add reputation category header
            table.insert(options, {
                title = '👥 Reputation',
                description = 'How different groups perceive you',
                metadata = {
                    {label = 'Total Reputation Categories', value = countTableKeys(data.rep)},
                },
                disabled = true
            })
            
            -- Add reputation to menu with visual indicators
            for repName, repValue in pairs(data.rep) do
                local configRep = Config.Reputation[repName]
                if configRep then
                    -- Create a visual indicator of reputation
                    local status, colorScheme = GetReputationStatus(repValue)
                    local icon = configRep.icon or "star"
                    
                    -- Calculate normalized progress (0-100)
                    local normalizedValue = ((repValue - configRep.min) / (configRep.max - configRep.min)) * 100
                    
                    table.insert(options, {
                        title = configRep.label,
                        description = status,
                        progress = normalizedValue,
                        colorScheme = colorScheme,
                        metadata = {
                            {label = 'Value', value = repValue},
                            {label = 'Range', value = configRep.min .. ' to ' .. configRep.max},
                        },
                        icon = icon
                    })
                end
            end
        else
            -- No reputation found
            table.insert(options, {
                title = 'No Reputation Found',
                description = 'You haven\'t gained any reputation yet.',
                disabled = true,
                icon = 'circle-exclamation'
            })
        end
        
        -- Add reputation effects button
        table.insert(options, {
            title = '👁️ View Active Reputation Effects',
            description = 'See how your reputation affects gameplay',
            arrow = true,
            icon = 'eye',
            onSelect = function()
                TriggerEvent('kingz-skills:client:showReputationEffects')
            end
        })
        
        -- Add skill check button
        table.insert(options, {
            title = '🎲 Perform Skill Check',
            description = 'Test your skills with a chance of success based on level',
            arrow = true,
            icon = 'dice',
            onSelect = function()
                TriggerEvent('kingz-skills:client:performSkillCheck')
            end
        })
        
        -- Register and show the context menu
        lib.registerContext({
            id = 'kingz_skills_menu',
            title = 'Kingz Skills & Reputation',
            options = options
        })
        
        lib.showContext('kingz_skills_menu')
    end)
end, false)

-- Keybind to open menu
RegisterKeyMapping('showskills', 'Open Skills Menu', 'keyboard', Config.MenuKeybind)

-- Show skill details with ox_lib
RegisterNetEvent('kingz-skills:client:showSkillDetails', function(data)
    if not QBCore then return end
    
    local skillName = data.skillName
    local skillData = data.skillData
    local configSkill = data.configSkill
    
    if not skillName or not skillData or not configSkill then
        lib.notify({
            title = 'Skills System',
            description = 'Invalid skill data',
            type = 'error'
        })
        return
    end
    
    -- Get perks for this skill
    QBCore.Functions.TriggerCallback('kingz-skills:getSkillPerks', function(perks)
        local options = {}
        
        -- Add skill description
        table.insert(options, {
            title = 'Description',
            description = configSkill.description or "No description available",
            disabled = true,
            icon = 'circle-info'
        })
        
        -- Add current level and XP with progress bar
        local threshold = configSkill.levelThreshold * (skillData.level or 1)
        local progress = math.floor(((skillData.xp or 0) / threshold) * 100)
        
        table.insert(options, {
            title = 'Current Progress',
            description = 'Level: ' .. (skillData.level or 1) .. ' | XP: ' .. (skillData.xp or 0) .. '/' .. threshold,
            progress = progress,
            colorScheme = configSkill.color or 'blue',
            disabled = true,
            icon = 'chart-line'
        })
        
        -- Add challenges button
        if Config.SkillChallenges and Config.SkillChallenges[skillName] then
            table.insert(options, {
                title = '🏆 Skill Challenges',
                description = 'View and start challenges for this skill',
                arrow = true,
                icon = 'trophy',
                onSelect = function()
                    TriggerEvent('kingz-skills:client:showChallenges', skillName)
                end
            })
        end
        
        -- Add perks
        if perks and type(perks) == 'table' and next(perks) then
            table.insert(options, {
                title = '💎 Skill Perks',
                description = 'Special abilities unlocked by leveling up',
                disabled = true,
                icon = 'gem'
            })
            
            for level, perk in pairs(perks) do
                if type(perk) == 'table' then
                    local unlocked = (skillData.level or 1) >= level
                    
                    table.insert(options, {
                        title = perk.name or "Level " .. level .. " Perk",
                        description = perk.description or "",
                        metadata = {
                            {label = 'Status', value = unlocked and 'Unlocked' or 'Locked'},
                            {label = 'Required Level', value = level},
                        },
                        disabled = true,
                        icon = unlocked and 'check' or 'lock',
                        iconColor = unlocked and 'green' or 'red'
                    })
                end
            end
        end
        
        -- Register and show the context menu
        lib.registerContext({
            id = 'kingz_skill_details',
            title = configSkill.label .. ' Details',
            menu = 'kingz_skills_menu',
            options = options
        })
        
        lib.showContext('kingz_skill_details')
    end, skillName)
end)

-- Show skill challenges menu with ox_lib
RegisterNetEvent('kingz-skills:client:showChallenges', function(skillName)
    if not QBCore then return end
    
    QBCore.Functions.TriggerCallback('kingz-skills:getSkillChallenges', function(challenges)
        if not challenges or type(challenges) ~= 'table' or next(challenges) == nil then
            lib.notify({
                id = 'no_challenges',
                title = 'Skills System',
                description = 'No challenges available for this skill',
                position = 'top-right',
                style = {
                    backgroundColor = '#141517',
                    color = '#C1C2C5',
                    ['.description'] = {
                        color = '#909296'
                    }
                },
                icon = 'triangle-exclamation',
                iconColor = '#ff9900',
                type = 'error'
            })
            return
        end
        
        local options = {}
        
        -- Add challenges
        for i, challenge in ipairs(challenges) do
            if type(challenge) == 'table' then  -- Make sure challenge is a table
                local status, colorScheme, icon
                
                if challenge.completed then
                    status = "Completed"
                    colorScheme = "green"
                    icon = "trophy"
                elseif challenge.active then
                    if challenge.failed then
                        status = "Failed"
                        colorScheme = "red"
                        icon = "xmark"
                    else
                        status = "Active (" .. (challenge.progress or 0) .. "/" .. (challenge.target or 0) .. ")"
                        colorScheme = "blue"
                        icon = "spinner"
                    end
                else
                    status = "Available"
                    colorScheme = "yellow"
                    icon = challenge.icon or "flag-checkered"
                end
                
                local metadata = {
                    {label = 'Status', value = status},
                    {label = 'Reward', value = (challenge.reward or 0) .. ' XP'},
                }
                
                if challenge.levelRequired and challenge.levelRequired > 1 then
                    table.insert(metadata, {label = 'Required Level', value = challenge.levelRequired})
                end
                
                if challenge.oneTime then
                    table.insert(metadata, {label = 'One-time', value = 'Yes'})
                end
                
                if challenge.active and not challenge.completed and not challenge.failed then
                    table.insert(metadata, {label = 'Progress', value = (challenge.progress or 0) .. '/' .. (challenge.target or 0)})
                end
                
                table.insert(options, {
                    title = challenge.name or "Challenge " .. i,
                    description = challenge.description or "",
                    progress = challenge.active and challenge.target and challenge.progress and ((challenge.progress / challenge.target) * 100) or nil,
                    colorScheme = colorScheme,
                    metadata = metadata,
                    icon = icon,
                    disabled = challenge.completed or challenge.active,
                    onSelect = function()
                        if not challenge.completed and not challenge.active then
                            TriggerEvent('kingz-skills:client:handleChallenge', {
                                skillName = skillName,
                                challengeIndex = i,
                                challenge = challenge
                            })
                        end
                    end
                })
            end
        end
        
        -- If no valid challenges were found
        if #options == 0 then
            table.insert(options, {
                title = 'No Valid Challenges',
                description = 'No properly formatted challenges available',
                disabled = true,
                icon = 'circle-exclamation'
            })
        end
        
        -- Register and show the context menu
        lib.registerContext({
            id = 'kingz_skill_challenges',
            title = Config.Skills[skillName] and Config.Skills[skillName].label or skillName .. ' Challenges',
            menu = 'kingz_skill_details',
            options = options
        })
        
        lib.showContext('kingz_skill_challenges')
    end, skillName)
end)

-- Handle challenge selection with ox_lib
RegisterNetEvent('kingz-skills:client:handleChallenge', function(data)
    if not QBCore then return end
    
    local skillName = data.skillName
    local challengeIndex = data.challengeIndex
    local challenge = data.challenge
    
    if not skillName or not challengeIndex or not challenge or type(challenge) ~= 'table' then
        lib.notify({
            title = 'Challenge',
            description = 'Invalid challenge data',
            type = 'error'
        })
        return
    end
    
    if challenge.completed then
        lib.notify({
            id = 'challenge_completed',
            title = 'Challenge',
            description = 'You have already completed this challenge',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'circle-check',
            iconColor = '#00ff00',
            type = 'error'
        })
        return
    end
    
    if challenge.active then
        lib.notify({
            id = 'challenge_active',
            title = 'Challenge',
            description = 'This challenge is already active',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'spinner',
            iconColor = '#0000ff',
            type = 'error'
        })
        return
    end
    
    -- Use alert dialog to confirm challenge start
    local alert = lib.alertDialog({
        header = 'Start Challenge',
        content = 'Do you want to start the "' .. (challenge.name or "Challenge") .. '" challenge?\n\n' .. (challenge.description or ""),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Start Challenge',
            cancel = 'Cancel'
        }
    })
    
    if alert ~= 'confirm' then return end
    
    -- Start the challenge
    QBCore.Functions.TriggerCallback('kingz-skills:startChallenge', function(success, message)
        if success then
            lib.notify({
                id = 'challenge_started',
                title = 'Challenge Started',
                description = message,
                position = 'top-right',
                style = {
                    backgroundColor = '#141517',
                    color = '#C1C2C5',
                    ['.description'] = {
                        color = '#909296'
                    }
                },
                icon = 'play',
                iconColor = '#00ff00',
                type = 'success'
            })
            
            -- For challenges with duration, start a timer
            if challenge.duration then
                -- Start tracking for timed challenges
                -- This is just an example for the speed challenge
                if challenge.minSpeed then
                    -- Use ox_lib progress circle for timed challenges
                    lib.notify({
                        id = 'speed_challenge',
                        title = 'Speed Challenge',
                        description = 'Maintain ' .. challenge.minSpeed .. ' km/h for ' .. challenge.duration .. ' seconds',
                        position = 'top-right',
                        style = {
                            backgroundColor = '#141517',
                            color = '#C1C2C5',
                            ['.description'] = {
                                color = '#909296'
                            }
                        },
                        icon = 'gauge-high',
                        iconColor = '#0000ff',
                        type = 'inform',
                        duration = 5000
                    })
                    
                    Citizen.CreateThread(function()
                        local startTime = GetGameTimer()
                        local endTime = startTime + (challenge.duration * 1000)
                        local failedChallenge = false
                        
                        -- Start progress circle
                        lib.progressCircle({
                            duration = challenge.duration * 1000,
                            position = 'bottom',
                            label = 'Maintaining Speed...',
                            useWhileDead = false,
                            canCancel = false,
                            disable = {
                                car = false,
                            },
                        })
                        
                        while GetGameTimer() < endTime and not failedChallenge do
                            Citizen.Wait(1000)
                            
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle == 0 then
                                failedChallenge = true
                                TriggerServerEvent('kingz-skills:updateChallengeProgress', skillName, challengeIndex, 0, true)
                                lib.notify({
                                    id = 'challenge_failed_vehicle',
                                    title = 'Challenge Failed',
                                    description = 'You left the vehicle',
                                    position = 'top-right',
                                    style = {
                                        backgroundColor = '#141517',
                                        color = '#C1C2C5',
                                        ['.description'] = {
                                            color = '#909296'
                                        }
                                    },
                                    icon = 'car',
                                    iconColor = '#ff0000',
                                    type = 'error'
                                })
                                break
                            end
                            
                            local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                            if speed < challenge.minSpeed then
                                failedChallenge = true
                                TriggerServerEvent('kingz-skills:updateChallengeProgress', skillName, challengeIndex, 0, true)
                                lib.notify({
                                    id = 'challenge_failed_speed',
                                    title = 'Challenge Failed',
                                    description = 'Speed dropped below ' .. challenge.minSpeed .. ' km/h',
                                    position = 'top-right',
                                    style = {
                                        backgroundColor = '#141517',
                                        color = '#C1C2C5',
                                        ['.description'] = {
                                            color = '#909296'
                                        }
                                    },
                                    icon = 'gauge-simple',
                                    iconColor = '#ff0000',
                                    type = 'error'
                                })
                                break
                            end
                            
                            -- Show remaining time every 5 seconds
                            local remaining = math.ceil((endTime - GetGameTimer()) / 1000)
                            if remaining % 5 == 0 then
                                lib.notify({
                                    id = 'challenge_progress_time',
                                    title = 'Speed Challenge',
                                    description = 'Maintain speed: ' .. remaining .. ' seconds remaining',
                                    position = 'top-right',
                                    style = {
                                        backgroundColor = '#141517',
                                        color = '#C1C2C5',
                                        ['.description'] = {
                                            color = '#909296'
                                        }
                                    },
                                    icon = 'clock',
                                    iconColor = '#0000ff',
                                    type = 'inform'
                                })
                            end
                        end
                        
                        if not failedChallenge then
                            TriggerServerEvent('kingz-skills:updateChallengeProgress', skillName, challengeIndex, 1, false)
                        end
                    end)
                end
            end
        else
            lib.notify({
                id = 'challenge_error',
                title = 'Challenge',
                description = message,
                position = 'top-right',
                style = {
                    backgroundColor = '#141517',
                    color = '#C1C2C5',
                    ['.description'] = {
                        color = '#909296'
                    }
                },
                icon = 'circle-exclamation',
                iconColor = '#ff0000',
                type = 'error'
            })
        end
    end, skillName, challengeIndex)
end)

-- Show reputation effects menu with ox_lib
RegisterNetEvent('kingz-skills:client:showReputationEffects', function()
    if not QBCore then return end
    
    QBCore.Functions.TriggerCallback('kingz-skills:getAllReputationEffects', function(effects)
        if not effects or type(effects) ~= 'table' or not next(effects) then
            lib.notify({
                id = 'no_rep_effects',
                title = 'Reputation',
                description = 'No active reputation effects',
                position = 'top-right',
                style = {
                    backgroundColor = '#141517',
                    color = '#C1C2C5',
                    ['.description'] = {
                        color = '#909296'
                    }
                },
                icon = 'circle-exclamation',
                iconColor = '#ff0000',
                type = 'error'
            })
            return
        end
        
        local options = {}
        
        -- Add effects
        for repCategory, repEffects in pairs(effects) do
            if type(repEffects) == 'table' then
                local configRep = Config.Reputation[repCategory]
                if configRep then
                    table.insert(options, {
                        title = configRep.label .. ' Effects',
                        description = 'Active effects from your reputation',
                        disabled = true,
                        icon = configRep.icon or 'star'
                    })
                    
                    for effectType, effectData in pairs(repEffects) do
                        if type(effectData) == 'table' then
                            for effectName, effectValue in pairs(effectData) do
                                local effectText = effectName .. ": " .. (effectValue > 0 and "+" or "") .. (effectValue * 100) .. "%"
                                local colorScheme = effectValue > 0 and 'green' or 'red'
                                
                                table.insert(options, {
                                    title = effectType:gsub("^%l", string.upper),
                                    description = effectText,
                                    metadata = {
                                        {label = 'Source', value = configRep.label .. ' Reputation'},
                                        {label = 'Effect', value = effectText},
                                    },
                                    colorScheme = colorScheme,
                                    icon = 'wand-magic-sparkles',
                                    disabled = true
                                })
                            end
                        end
                    end
                end
            end
        end
        
        -- If no valid effects were found
        if #options == 0 then
            table.insert(options, {
                title = 'No Reputation Effects',
                description = 'No active reputation effects found',
                disabled = true,
                icon = 'circle-exclamation'
            })
        end
        
        -- Register and show the context menu
        lib.registerContext({
            id = 'kingz_reputation_effects',
            title = 'Active Reputation Effects',
            menu = 'kingz_skills_menu',
            options = options
        })
        
        lib.showContext('kingz_reputation_effects')
    end)
end)

-- Perform a skill check using ox_lib
RegisterNetEvent('kingz-skills:client:performSkillCheck', function()
    if not QBCore then return end
    
    -- Get player data
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.skills or type(PlayerData.skills) ~= 'table' then
        lib.notify({
            id = 'no_skills_data',
            title = 'Skill Check',
            description = 'No skills data available',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'circle-exclamation',
            iconColor = '#ff0000',
            type = 'error'
        })
        return
    end
    
    -- Show skill selection menu
    local options = {}
    for skillName, skillData in pairs(PlayerData.skills) do
        if type(skillData) == 'table' then
            local configSkill = Config.Skills[skillName]
            if configSkill then
                table.insert(options, {
                    label = configSkill.label,
                    description = 'Level ' .. (skillData.level or 1),
                    icon = configSkill.icon or 'star',
                    value = skillName
                })
            end
        end
    end
    
    if #options == 0 then
        lib.notify({
            id = 'no_skills_available',
            title = 'Skill Check',
            description = 'No skills available for testing',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'circle-exclamation',
            iconColor = '#ff0000',
            type = 'error'
        })
        return
    end
    
    local input = lib.inputDialog('Skill Check', {
        {
            type = 'select',
            label = 'Select Skill',
            options = options,
            required = true
        },
        {
            type = 'select',
            label = 'Difficulty',
            options = {
                { value = 'easy', label = 'Easy' },
                { value = 'medium', label = 'Medium' },
                { value = 'hard', label = 'Hard' }
            },
            default = 'medium',
            required = true
        }
    })
    
    if not input then return end
    
    local skillName = input[1]
    local difficulty = input[2]
    
    if not skillName or not difficulty or not PlayerData.skills[skillName] then
        lib.notify({
            title = 'Skill Check',
            description = 'Invalid selection',
            type = 'error'
        })
        return
    end
    
    local skillLevel = PlayerData.skills[skillName].level or 1
    
    -- Calculate success chance based on skill level and difficulty
    local baseChance = {
        easy = 50,
        medium = 30,
        hard = 10
    }
    
    local skillBonus = skillLevel * 5 -- 5% per level
    local successChance = math.min(95, math.max(5, baseChance[difficulty] + skillBonus))
    
    -- Perform the skill check
    local success = lib.skillCheck({'easy', 'medium', 'hard'}, {'w', 'a', 's', 'd'})
    
    if success then
        -- Award XP for successful skill check
        local xpReward = {
            easy = 5,
            medium = 10,
            hard = 20
        }
        
        TriggerServerEvent('kingz-skills:updateSkill', skillName, xpReward[difficulty])
        
                lib.notify({
            id = 'skill_check_success',
            title = 'Skill Check Successful',
            description = 'You earned ' .. xpReward[difficulty] .. ' XP in ' .. Config.Skills[skillName].label,
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'check-circle',
            iconColor = '#00ff00',
            type = 'success'
        })
    else
        lib.notify({
            id = 'skill_check_failed',
            title = 'Skill Check Failed',
            description = 'You failed the ' .. Config.Skills[skillName].label .. ' skill check',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'times-circle',
            iconColor = '#ff0000',
            type = 'error'
        })
    end
end)

-- Notification handlers with ox_lib
RegisterNetEvent('kingz-skills:client:notification', function(message, type)
    lib.notify({
        id = 'skills_notification',
        title = 'Skills System',
        description = message,
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = type == 'success' and 'check-circle' or type == 'error' and 'times-circle' or 'info-circle',
        iconColor = type == 'success' and '#00ff00' or type == 'error' and '#ff0000' or '#0000ff',
        type = type or 'inform'
    })
end)

-- Skill level up notification
RegisterNetEvent('kingz-skills:client:skillLevelUp', function(skillName, newLevel)
    local configSkill = Config.Skills[skillName]
    if not configSkill then return end
    
    -- Show a more advanced notification with animation
    lib.notify({
        id = 'skill_levelup_' .. skillName,
        title = 'Skill Level Up!',
        description = 'Your ' .. configSkill.label .. ' skill increased to level ' .. newLevel,
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = configSkill.icon,
        iconColor = configSkill.color or '#0284c7',
        type = 'success'
    })
    
    -- Play a sound effect
    PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", 1)
    
    -- Show a text UI for a few seconds
    lib.showTextUI('SKILL LEVEL UP: ' .. configSkill.label .. ' ' .. newLevel, {
        position = "top-center",
        icon = configSkill.icon,
        style = {
            borderRadius = 0,
            backgroundColor = '#141517',
            color = 'white'
        }
    })
    
    -- Hide the text UI after a few seconds
    Citizen.SetTimeout(3000, function()
        lib.hideTextUI()
    end)
    
    -- Check for new perks
    if Config.SkillPerks[skillName] and Config.SkillPerks[skillName][newLevel] then
        local perk = Config.SkillPerks[skillName][newLevel]
        
        -- Show alert dialog for new perk
        Citizen.SetTimeout(500, function()
            lib.alertDialog({
                header = 'New Perk Unlocked!',
                content = 'You unlocked: ' .. perk.name .. '\n\n' .. perk.description,
                centered = true,
                cancel = false,
            })
        end)
    end
end)

-- Reputation change notification
RegisterNetEvent('kingz-skills:client:repChanged', function(repCategory, amount, newValue)
    local configRep = Config.Reputation[repCategory]
    if not configRep then return end
    
    local changeType = amount > 0 and 'increased' or 'decreased'
    local absAmount = math.abs(amount)
    
    lib.notify({
        id = 'rep_change_' .. repCategory,
        title = 'Reputation Changed',
        description = 'Your ' .. configRep.label .. ' reputation ' .. changeType .. ' by ' .. absAmount .. ' to ' .. newValue,
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = configRep.icon,
        iconColor = configRep.color or '#0284c7',
        type = amount > 0 and 'success' or 'error'
    })
    
    -- Show a text UI for reputation milestones
    if (newValue == 50 or newValue == 100 or newValue == -50 or newValue == -100) then
        local status = ""
        if newValue == 50 then status = "Respected"
        elseif newValue == 100 then status = "Highly Respected"
        elseif newValue == -50 then status = "Disliked"
        elseif newValue == -100 then status = "Hated"
        end
        
        lib.showTextUI('REPUTATION MILESTONE: ' .. configRep.label .. ' ' .. status, {
            position = "top-center",
            icon = configRep.icon,
            style = {
                borderRadius = 0,
                backgroundColor = '#141517',
                color = 'white'
            }
        })
        
        -- Hide the text UI after a few seconds
        Citizen.SetTimeout(3000, function()
            lib.hideTextUI()
        end)
        
        -- Check for new reputation effects
        if (newValue == 50 or newValue == -50) and Config.ReputationEffects[repCategory] then
            local effects = newValue > 0 and Config.ReputationEffects[repCategory].high or Config.ReputationEffects[repCategory].low
            
            if effects and type(effects) == 'table' then
                -- Show alert dialog for new effects
                Citizen.SetTimeout(500, function()
                    local content = 'Your ' .. configRep.label .. ' reputation has unlocked new effects:\n\n'
                    
                    for effectType, effectData in pairs(effects) do
                        if type(effectData) == 'table' then
                            for effectName, effectValue in pairs(effectData) do
                                content = content .. '- ' .. effectType:gsub("^%l", string.upper) .. ': ' .. effectName .. ' ' .. (effectValue > 0 and "+" or "") .. (effectValue * 100) .. '%\n'
                            end
                        end
                    end
                    
                    lib.alertDialog({
                        header = 'New Reputation Effects!',
                        content = content,
                        centered = true,
                        cancel = false,
                    })
                end)
            end
        end
    end
end)

-- Skill decay notification
RegisterNetEvent('kingz-skills:client:skillDecayed', function(skillName, newLevel)
    local configSkill = Config.Skills[skillName]
    if not configSkill then return end
    
    lib.notify({
        id = 'skill_decay_' .. skillName,
        title = 'Skill Decayed',
        description = 'Your ' .. configSkill.label .. ' skill decayed to level ' .. newLevel .. ' due to inactivity',
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = configSkill.icon,
        iconColor = configSkill.color or '#0284c7',
        type = 'error'
    })
end)

-- Skills reset notification
RegisterNetEvent('kingz-skills:client:skillsReset', function()
    lib.notify({
        id = 'skills_reset',
        title = 'Skills Reset',
        description = 'All your skills and reputation have been reset',
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = 'rotate',
        iconColor = '#0000ff',
        type = 'inform'
    })
end)

-- Challenge notifications
RegisterNetEvent('kingz-skills:client:challengeStarted', function(skillName, challengeIndex)
    if not Config.SkillChallenges or not Config.SkillChallenges[skillName] or not Config.SkillChallenges[skillName][challengeIndex] then
        return
    end
    
    local challenge = Config.SkillChallenges[skillName][challengeIndex]
    
    lib.notify({
        id = 'challenge_start_' .. skillName .. '_' .. challengeIndex,
        title = 'Challenge Started',
        description = challenge.name .. ': ' .. challenge.description,
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = challenge.icon or 'trophy',
        iconColor = '#ffaa00',
        type = 'inform'
    })
end)

RegisterNetEvent('kingz-skills:client:challengeProgress', function(skillName, challengeIndex, progress, target)
    if not Config.SkillChallenges or not Config.SkillChallenges[skillName] or not Config.SkillChallenges[skillName][challengeIndex] then
        return
    end
    
    local challenge = Config.SkillChallenges[skillName][challengeIndex]
    
    lib.notify({
        id = 'challenge_progress_' .. skillName .. '_' .. challengeIndex,
        title = 'Challenge Progress',
        description = challenge.name .. ': ' .. progress .. '/' .. target,
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = challenge.icon or 'trophy',
        iconColor = '#0000ff',
        type = 'inform'
    })
end)

RegisterNetEvent('kingz-skills:client:challengeCompleted', function(skillName, challengeIndex, reward)
    if not Config.SkillChallenges or not Config.SkillChallenges[skillName] or not Config.SkillChallenges[skillName][challengeIndex] then
        return
    end
    
    local challenge = Config.SkillChallenges[skillName][challengeIndex]
    
    -- Show notification
    lib.notify({
        id = 'challenge_complete_' .. skillName .. '_' .. challengeIndex,
        title = 'Challenge Completed!',
        description = challenge.name .. ': Earned ' .. reward .. ' XP',
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = challenge.icon or 'trophy',
        iconColor = '#ffaa00',
        type = 'success'
    })
    
    -- Play a sound effect
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
    
    -- Show a text UI for a few seconds
    lib.showTextUI('CHALLENGE COMPLETED: ' .. challenge.name, {
        position = "top-center",
        icon = challenge.icon or 'trophy',
        style = {
            borderRadius = 0,
            backgroundColor = '#141517',
            color = 'white'
        }
    })
    
    -- Hide the text UI after a few seconds
    Citizen.SetTimeout(3000, function()
        lib.hideTextUI()
    end)
    
    -- Show alert dialog with reward details
    Citizen.SetTimeout(500, function()
        lib.alertDialog({
            header = 'Challenge Completed!',
            content = 'You completed the "' .. challenge.name .. '" challenge!\n\nReward: ' .. reward .. ' XP',
            centered = true,
            cancel = false,
        })
    end)
end)

RegisterNetEvent('kingz-skills:client:challengeFailed', function(skillName, challengeIndex, reason)
    if not Config.SkillChallenges or not Config.SkillChallenges[skillName] or not Config.SkillChallenges[skillName][challengeIndex] then
        return
    end
    
    local challenge = Config.SkillChallenges[skillName][challengeIndex]
    
    lib.notify({
        id = 'challenge_fail_' .. skillName .. '_' .. challengeIndex,
        title = 'Challenge Failed',
        description = challenge.name .. ': ' .. reason,
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = challenge.icon or 'trophy',
        iconColor = '#ff0000',
        type = 'error'
    })
    
    -- Play a sound effect
    PlaySoundFrontend(-1, "ScreenFlash", "WastedSounds", 1)
end)

-- Listen for player data updates
RegisterNetEvent('QBCore:Player:SetPlayerData')
AddEventHandler('QBCore:Player:SetPlayerData', function(val)
    -- This event is triggered when player data changes
    print("^2[kingz-skills] Received updated player data^7")
    
    -- You can add specific handling for skills/rep updates here if needed
end)

-- Event Hooks: Driving XP (tracks distance driven)
local isDriving = false
local lastPos = vector3(0, 0, 0)
local distanceDriven = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Check every second
        
        if not QBCore then
            Citizen.Wait(1000)
            goto continue
        end
        
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
            if not isDriving then
                isDriving = true
                lastPos = GetEntityCoords(ped)
            end
            local currentPos = GetEntityCoords(ped)
            local dist = #(currentPos - lastPos)
            distanceDriven = distanceDriven + dist
            lastPos = currentPos
            
            if distanceDriven >= 1000 then  -- Every 1km (1000 units ~1km in GTA)
                TriggerServerEvent('kingz-skills:updateSkill', 'driving', Config.Skills['driving'].xpPerKm or 10)
                distanceDriven = 0
                lib.notify({
                    id = 'driving_xp',
                    title = 'Driving XP',
                    description = 'Gained XP for traveling 1km!',
                    position = 'top-right',
                    style = {
                        backgroundColor = '#141517',
                        color = '#C1C2C5',
                        ['.description'] = {
                            color = '#909296'
                        }
                    },
                    icon = 'car',
                    iconColor = Config.Skills['driving'].color or '#0891b2',
                    type = 'success'
                })
            end
        else
            isDriving = false
            distanceDriven = 0
        end
        
        ::continue::
    end
end)

-- Event Hooks: Shooting XP example (awards XP on weapon fire)
AddEventHandler('CEventGunShot', function(entities, eventEntity, args)
    if not QBCore then return end
    
    -- Check if player fired (simplified; integrate with your weapon scripts for accuracy)
    if eventEntity == PlayerPedId() then
        TriggerServerEvent('kingz-skills:updateSkill', 'shooting', Config.Skills['shooting'].xpPerAction)
        lib.notify({
            id = 'shooting_xp',
            title = 'Shooting XP',
            description = 'Gained XP from firing a weapon!',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'gun',
            iconColor = Config.Skills['shooting'].color or '#7e22ce',
            type = 'success'
        })
    end
end)

-- Stamina skill integration with running
local isRunning = false
local runningTime = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Check every second
        
        if not QBCore then
            Citizen.Wait(1000)
            goto continue
        end
        
        local ped = PlayerPedId()
        
        if IsPedRunning(ped) or IsPedSprinting(ped) then
            if not isRunning then
                isRunning = true
            end
            
            runningTime = runningTime + 1
            
            -- Every 30 seconds of running, gain stamina XP
            if runningTime >= 30 then
                TriggerServerEvent('kingz-skills:updateSkill', 'stamina', Config.Skills['stamina'].xpPerAction or 6)
                runningTime = 0
                lib.notify({
                    id = 'stamina_xp',
                    title = 'Stamina XP',
                    description = 'Gained XP from running!',
                    position = 'top-right',
                    style = {
                        backgroundColor = '#141517',
                        color = '#C1C2C5',
                        ['.description'] = {
                            color = '#909296'
                        }
                    },
                    icon = 'person-running',
                    iconColor = Config.Skills['stamina'].color or '#15803d',
                    type = 'success'
                })
            end
        else
            isRunning = false
        end
        
        ::continue::
    end
end)

-- Strength skill integration with melee combat
AddEventHandler('CEventMeleeAction', function(entities, eventEntity, args)
    if not QBCore then return end
    
    if eventEntity == PlayerPedId() then
        TriggerServerEvent('kingz-skills:updateSkill', 'strength', Config.Skills['strength'].xpPerAction or 7)
        lib.notify({
            id = 'strength_xp',
            title = 'Strength XP',
            description = 'Gained XP from melee combat!',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'dumbbell',
            iconColor = Config.Skills['strength'].color or '#b45309',
            type = 'success'
        })
    end
end)

-- Apply stamina perk effects to player
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)  -- Check every 5 seconds
        
        if not QBCore then
            Citizen.Wait(1000)
            goto continue
        end
        
        -- Get player data
        local playerData = QBCore.Functions.GetPlayerData()
        if not playerData or not playerData.skills then
            Citizen.Wait(1000)
            goto continue
        end
        
        -- Check if player has stamina skill
        local staminaSkill = playerData.skills.stamina
        if not staminaSkill then
            goto continue
        end
        
        -- Apply stamina effects based on level
        local staminaLevel = staminaSkill.level or 1
        local staminaMultiplier = 1.0
        
        -- Level 5 perk: Endurance
        if staminaLevel >= 5 then
            staminaMultiplier = 1.15
        end
        
        -- Level 10 perk: Marathon Runner
        if staminaLevel >= 10 then
            staminaMultiplier = 1.3
        end
        
        -- Apply stamina multiplier (this is just an example, actual implementation depends on your stamina system)
        -- For vanilla GTA, we can modify the player's sprint speed
        SetRunSprintMultiplierForPlayer(PlayerId(), staminaMultiplier)
        
        ::continue::
    end
end)

-- Apply strength perk effects to player
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)  -- Check every 5 seconds
        
        if not QBCore then
            Citizen.Wait(1000)
            goto continue
        end
        
        -- Get player data
        local playerData = QBCore.Functions.GetPlayerData()
        if not playerData or not playerData.skills then
            Citizen.Wait(1000)
            goto continue
        end
        
        -- Check if player has strength skill
        local strengthSkill = playerData.skills.strength
        if not strengthSkill then
            goto continue
        end
        
        -- Apply strength effects based on level
        local strengthLevel = strengthSkill.level or 1
        local damageMultiplier = 1.0
        
        -- Level 5 perk: Strong Build
        if strengthLevel >= 5 then
            damageMultiplier = 1.1
        end
        
        -- Level 10 perk: Powerhouse
        if strengthLevel >= 10 then
            damageMultiplier = 1.25
        end
        
        -- Apply strength multiplier to melee damage
        -- For vanilla GTA, we can modify the player's melee damage
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), damageMultiplier)
        
        ::continue::
    end
end)

-- Simple test command to verify the resource is working and add test XP/rep
RegisterCommand('testskills', function()
    if not QBCore then return end
    
    print('^2[kingz-skills] Test command triggered^7')
    lib.notify({
        id = 'test_skills',
        title = 'Skills System',
        description = 'Testing skills system...',
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = 'vial',
        iconColor = '#0000ff',
        type = 'inform'
    })
    
    -- Show loading spinner
    lib.progressCircle({
        duration = 1000,
        position = 'bottom',
        label = 'Testing skills...',
        useWhileDead = true,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    })
    
    -- Debug output
    print('^2[kingz-skills] Triggering updateSkill event for mining (10 XP)^7')
    TriggerServerEvent('kingz-skills:updateSkill', 'mining', 10)
    
    Citizen.Wait(100)
    
    print('^2[kingz-skills] Triggering updateRep event for criminal (5 rep)^7')
    TriggerServerEvent('kingz-skills:updateRep', 'criminal', 5)
    
    -- Wait for server to process and save
    Citizen.Wait(500)
    
    -- Refresh player data
    RefreshPlayerData()
    
    -- Wait a bit more and then show the skills menu
    Citizen.Wait(500)
    ExecuteCommand('showskills')
end, false)

-- Command to directly check current skills and reputation values
RegisterCommand('checkskills', function()
    if not QBCore then return end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    print("^2[kingz-skills] Current Skills:^7")
    if PlayerData.skills and type(PlayerData.skills) == 'table' then
        for skillName, skillData in pairs(PlayerData.skills) do
            if type(skillData) == 'table' then
                print(skillName .. ": Level " .. (skillData.level or 1) .. ", XP " .. (skillData.xp or 0))
            end
        end
    else
        print("No skills data found")
    end
    
    print("^2[kingz-skills] Current Reputation:^7")
    if PlayerData.reputation and type(PlayerData.reputation) == 'table' then
        for repName, repValue in pairs(PlayerData.reputation) do
            print(repName .. ": " .. repValue)
        end
    else
        print("No reputation data found")
    end
    
    lib.notify({
        id = 'check_skills',
        title = 'Skills Check',
        description = 'Check console for current skills and reputation',
        position = 'top-right',
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = 'magnifying-glass',
        iconColor = '#0000ff',
        type = 'inform'
    })
end, false)
