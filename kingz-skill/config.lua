Config = {} -- This line must be at the top of the file!

-- Skills Configuration (expanded with more skills)
Config.Skills = {
    -- Original skills
    ['mining'] = { 
        label = 'Mining', 
        maxLevel = 10, 
        xpPerAction = 10, 
        levelThreshold = 100,
        description = "Ability to mine resources more efficiently",
        icon = "pickaxe",
        color = "#c2410c"
    },
    ['hacking'] = { 
        label = 'Hacking', 
        maxLevel = 10, 
        xpPerAction = 15, 
        levelThreshold = 150,
        description = "Skill at breaking digital security systems",
        icon = "laptop-code",
        color = "#0284c7"
    },
    ['driving'] = { 
        label = 'Driving', 
        maxLevel = 10, 
        xpPerAction = 5, 
        levelThreshold = 80, 
        xpPerKm = 10,
        description = "Ability to handle vehicles with precision",
        icon = "car",
        color = "#0891b2"
    },
    ['fishing'] = { 
        label = 'Fishing', 
        maxLevel = 10, 
        xpPerAction = 8, 
        levelThreshold = 90,
        description = "Skill at catching fish and aquatic creatures",
        icon = "fish",
        color = "#0ea5e9"
    },
    ['shooting'] = { 
        label = 'Shooting', 
        maxLevel = 10, 
        xpPerAction = 5, 
        levelThreshold = 120,
        description = "Accuracy and proficiency with firearms",
        icon = "gun",
        color = "#7e22ce"
    },
    
    -- New skills
    ['lockpicking'] = { 
        label = 'Lockpicking', 
        maxLevel = 10, 
        xpPerAction = 12, 
        levelThreshold = 110,
        description = "Ability to pick locks on doors and vehicles",
        icon = "unlock",
        color = "#6d28d9"
    },
    ['crafting'] = { 
        label = 'Crafting', 
        maxLevel = 10, 
        xpPerAction = 15, 
        levelThreshold = 130,
        description = "Skill at creating and repairing items",
        icon = "hammer",
        color = "#a16207"
    },
    ['cooking'] = { 
        label = 'Cooking', 
        maxLevel = 10, 
        xpPerAction = 8, 
        levelThreshold = 90,
        description = "Ability to prepare food with various effects",
        icon = "utensils",
        color = "#b91c1c"
    },
    ['stealth'] = { 
        label = 'Stealth', 
        maxLevel = 10, 
        xpPerAction = 10, 
        levelThreshold = 100,
        description = "Ability to move undetected and pick pockets",
        icon = "user-ninja",
        color = "#1e293b"
    },
    ['strength'] = { 
        label = 'Strength', 
        maxLevel = 10, 
        xpPerAction = 7, 
        levelThreshold = 120,
        description = "Physical power affecting melee damage and carrying capacity",
        icon = "dumbbell",
        color = "#b45309"
    },
    ['stamina'] = { 
        label = 'Stamina', 
        maxLevel = 10, 
        xpPerAction = 6, 
        levelThreshold = 100,
        description = "Endurance affecting running speed and duration",
        icon = "person-running",
        color = "#15803d"
    },
    ['herbalism'] = { 
        label = 'Herbalism', 
        maxLevel = 10, 
        xpPerAction = 9, 
        levelThreshold = 95,
        description = "Knowledge of plants and ability to create remedies",
        icon = "leaf",
        color = "#16a34a"
    }
}

-- Reputation Configuration (based on cw-rep)
Config.Reputation = {
    ['criminal'] = { 
        label = 'Criminal Rep', 
        min = -100, 
        max = 100, 
        gainPerAction = 5, 
        lossPerAction = -5, 
        icon = "user-secret",
        color = "#7f1d1d"
    },
    ['civilian'] = { 
        label = 'Civilian Rep', 
        min = -100, 
        max = 100, 
        gainPerAction = 5, 
        lossPerAction = -5, 
        icon = "user",
        color = "#1e40af"
    },
    ['police'] = { 
        label = 'Police Rep', 
        min = -100, 
        max = 100, 
        gainPerAction = 10, 
        lossPerAction = -10, 
        icon = "shield-halved",
        color = "#1d4ed8"
    },
    ['medical'] = { 
        label = 'Medical Rep', 
        min = -100, 
        max = 100, 
        gainPerAction = 8, 
        lossPerAction = -8, 
        icon = "staff-snake",
        color = "#be123c"
    },
    ['mechanic'] = { 
        label = 'Mechanic Rep', 
        min = -100, 
        max = 100, 
        gainPerAction = 7, 
        lossPerAction = -7, 
        icon = "wrench",
        color = "#0f766e"
    },
    ['business'] = { 
        label = 'Business Rep', 
        min = -100, 
        max = 100, 
        gainPerAction = 6, 
        lossPerAction = -6, 
        icon = "briefcase",
        color = "#854d0e"
    },
}

-- Bonuses: How rep affects skills (e.g., high criminal rep boosts hacking XP gain)
Config.RepBonuses = {
    ['hacking'] = { repCategory = 'criminal', bonusMultiplier = 1.5 },
    ['shooting'] = { repCategory = 'police', bonusMultiplier = 1.2 },
    ['lockpicking'] = { repCategory = 'criminal', bonusMultiplier = 1.3 },
    ['cooking'] = { repCategory = 'civilian', bonusMultiplier = 1.2 },
    ['crafting'] = { repCategory = 'mechanic', bonusMultiplier = 1.4 },
    ['herbalism'] = { repCategory = 'medical', bonusMultiplier = 1.3 },
}

-- UI Settings
Config.MenuKeybind = 'K'  -- Key to open skills menu (uses RegisterKeyMapping)

-- Skill Perks System
Config.SkillPerks = {
    ['mining'] = {
        [3] = { name = "Basic Mining Efficiency", description = "10% chance to get extra ore", effect = function(Player) 
            return math.random(100) <= 10
        end },
        [5] = { name = "Intermediate Mining", description = "20% chance to get extra ore", effect = function(Player) 
            return math.random(100) <= 20
        end },
        [8] = { name = "Advanced Mining", description = "30% chance to get extra ore", effect = function(Player) 
            return math.random(100) <= 30
        end },
        [10] = { name = "Master Miner", description = "50% chance to get extra ore", effect = function(Player) 
            return math.random(100) <= 50
        end }
    },
    ['lockpicking'] = {
        [3] = { name = "Nimble Fingers", description = "10% less lockpick breakage", effect = function(Player) 
            return math.random(100) <= 10
        end },
        [6] = { name = "Skilled Lockpicker", description = "25% less lockpick breakage", effect = function(Player) 
            return math.random(100) <= 25
        end },
        [10] = { name = "Master Locksmith", description = "50% less lockpick breakage", effect = function(Player) 
            return math.random(100) <= 50
        end }
    },
    ['hacking'] = {
        [4] = { name = "Code Breaker", description = "Extra time on hacking minigames", effect = function(Player) 
            return 5 -- Extra seconds
        end },
        [8] = { name = "Elite Hacker", description = "Simplified hacking puzzles", effect = function(Player) 
            return true
        end }
    },
    ['cooking'] = {
        [3] = { name = "Home Cook", description = "Food items restore 10% more", effect = function(Player) 
            return 1.1 -- Multiplier
        end },
        [7] = { name = "Chef", description = "Food items restore 25% more", effect = function(Player) 
            return 1.25 -- Multiplier
        end },
        [10] = { name = "Master Chef", description = "Food items restore 50% more", effect = function(Player) 
            return 1.5 -- Multiplier
        end }
    },
    ['strength'] = {
        [5] = { name = "Strong Build", description = "Carry 10% more weight", effect = function(Player) 
            return 1.1 -- Multiplier
        end },
        [10] = { name = "Powerhouse", description = "Carry 25% more weight", effect = function(Player) 
            return 1.25 -- Multiplier
        end }
    },
    ['stamina'] = {
        [5] = { name = "Endurance", description = "Run 15% longer", effect = function(Player) 
            return 1.15 -- Multiplier
        end },
        [10] = { name = "Marathon Runner", description = "Run 30% longer", effect = function(Player) 
            return 1.3 -- Multiplier
        end }
    }
}

-- Skill Decay System
Config.EnableSkillDecay = true  -- Set to false to disable skill decay
Config.SkillDecayInterval = 24  -- Hours between decay checks
Config.SkillDecayAmount = 5     -- XP to decay per interval
Config.SkillDecayExemptLevel = 3 -- Skills below this level won't decay

-- Job Skill Bonuses and Requirements
Config.JobSkillBonuses = {
    ['police'] = {
        ['shooting'] = 1.5,  -- 50% more shooting XP for police
        ['driving'] = 1.3    -- 30% more driving XP for police
    },
    ['ambulance'] = {
        ['herbalism'] = 1.5, -- 50% more herbalism XP for medics
        ['stamina'] = 1.2    -- 20% more stamina XP for medics
    },
    ['mechanic'] = {
        ['crafting'] = 1.5,  -- 50% more crafting XP for mechanics
        ['strength'] = 1.2   -- 20% more strength XP for mechanics
    }
}

Config.JobSkillRequirements = {
    ['police'] = {
        ['shooting'] = 3,    -- Require shooting level 3 for police job
        ['driving'] = 2      -- Require driving level 2 for police job
    },
    ['ambulance'] = {
        ['herbalism'] = 2    -- Require herbalism level 2 for ambulance job
    },
    ['mechanic'] = {
        ['crafting'] = 2     -- Require crafting level 2 for mechanic job
    }
}

-- Skill Challenges System
Config.SkillChallenges = {
    ['mining'] = {
        {
            name = "Ore Hunter",
            description = "Mine 50 ores in one day",
            target = 50,
            reward = 100,  -- XP reward
            timeLimit = 24, -- Hours
            icon = "gem"
        },
        {
            name = "Deep Digger",
            description = "Reach level 5 in mining",
            levelRequired = 5,
            reward = 200,  -- XP reward
            oneTime = true, -- Can only be completed once
            icon = "mountain"
        }
    },
    ['driving'] = {
        {
            name = "Road Warrior",
            description = "Drive 50km without crashing",
            target = 50,
            reward = 150,
            failOnCrash = true,
            icon = "road"
        },
        {
            name = "Speed Demon",
            description = "Maintain 100+ km/h for 2 minutes",
            duration = 120, -- Seconds
            minSpeed = 100,
            reward = 200,
            icon = "gauge-high"
        }
    },
    ['lockpicking'] = {
        {
            name = "Master Thief",
            description = "Successfully pick 10 locks without failing",
            target = 10,
            reward = 150,
            failOnMistake = true,
            icon = "key"
        }
    }
}

-- Reputation Effects System
Config.ReputationEffects = {
    ['criminal'] = {
        high = { -- Effects when reputation > 50
            ['lockpicking'] = { timeBonus = 5 }, -- Extra 5 seconds on lockpicking
            ['stealth'] = { detectionReduction = 0.2 } -- 20% less likely to be detected
        },
        low = { -- Effects when reputation < -50
            ['police'] = { responseTime = 1.5 }, -- Police respond 50% faster
            ['civilian'] = { prices = 1.2 } -- 20% higher prices at stores
        }
    },
    ['police'] = {
        high = {
            ['shooting'] = { damageBonus = 0.1 }, -- 10% more damage with firearms
            ['driving'] = { speedBonus = 0.15 } -- 15% higher top speed
        },
        low = {
            ['criminal'] = { respect = -0.2 } -- 20% less respect from criminals
        }
    },
    ['civilian'] = {
        high = {
            ['prices'] = { discount = 0.1 }, -- 10% discount at stores
            ['jobs'] = { payBonus = 0.15 } -- 15% more pay from civilian jobs
        }
    },
    ['medical'] = {
        high = {
            ['healing'] = { effectBonus = 0.2 }, -- 20% more effective healing
            ['herbalism'] = { qualityBonus = 0.15 } -- 15% better quality items
        }
    }
}
