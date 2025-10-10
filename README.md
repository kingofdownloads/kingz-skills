# kingz-skills
'Kingz Skills - Hybrid Skill and Rep System for QBCore'
Kingz Skills - Advanced RPG Skills & Reputation System for FiveM
Description
Kingz Skills is a comprehensive skills and reputation system for FiveM servers using the QBCore framework. This resource provides a modern, feature-rich progression system that allows players to develop their character's abilities over time through gameplay activities, enhancing the roleplaying experience and adding depth to your server.

Built with ox_lib for a sleek, responsive UI, Kingz Skills offers an immersive way to track character development with beautiful notifications, progress bars, and interactive menus.

Features
Skills System
Multiple Skill Categories: Includes driving, shooting, strength, stamina, mining, crafting, cooking, lockpicking, and more
Experience-Based Progression: Players earn XP through relevant activities
Leveling System: Skills improve from level 1 to 10 with increasing XP requirements
Perk System: Unlock special abilities and bonuses at specific skill levels
Skill Decay: Optional system to decrease unused skills over time
Visual Progress Tracking: Beautiful UI showing skill levels and progress
Reputation System
Faction-Based Reputation: Track standing with different groups (police, criminals, civilians, etc.)
Dynamic Effects: Reputation influences gameplay mechanics
Positive/Negative Scale: Reputation ranges from -100 to 100
Milestone Effects: Special effects unlock at reputation thresholds
Challenges System
Skill-Specific Challenges: Complete tasks to earn bonus XP
Timed Challenges: Some challenges require maintaining conditions for a duration
One-Time Challenges: Special achievements that can only be completed once
Progress Tracking: Visual indicators for challenge completion
Advanced UI Features
Interactive Menus: Built with ox_lib for a modern, responsive interface
Animated Notifications: Beautiful notifications for skill ups and achievements
Progress Bars: Visual representation of skill and reputation progress
Skill Checks: Mini-game system to test skills with difficulty based on level
Alert Dialogs: Important information presented in styled dialog boxes
Text UI: Temporary overlays for significant events
Integration & Extensibility
Easy Integration: Simple exports to add to existing resources
Job Requirements: Set skill requirements for specific jobs
Bonus System: Jobs can provide bonus XP for related skills
Configurable: Extensive configuration options for all features
Developer-Friendly: Well-documented code with examples for integration
Technical Details
Built for QBCore framework
Uses ox_lib for UI components
Database integration with oxmysql
Optimized for performance with minimal resource usage
Comprehensive error handling and type checking
Extensive configuration options
Commands
/showskills - Opens the skills menu (also bound to 'K' key by default)
/testskills - Tests the skills system and adds sample XP
/checkskills - Shows current skills and reputation in console
/resetskills - Admin command to reset all skills and reputation
/addskill [skillname] [amount] - Admin command to add XP to a skill
/addrep [category] [amount] - Admin command to add reputation
/setskill [skillname] [level] [xp] - Admin command to set skill level and XP
/setrep [category] [value] - Admin command to set reputation value
Dependencies
QBCore framework
ox_lib
oxmysql
Installation
Ensure you have the required dependencies installed
Place the kingz-skills folder in your resources directory
Run the included SQL script to add necessary database columns
Add ensure kingz-skills to your server.cfg (after ox_lib)
Configure the settings in config.lua to match your server's needs
Restart your server or use refresh followed by ensure kingz-skills
Integration Examples
Kingz Skills can be easily integrated with other resources:

lua


-- Add XP to a skill
TriggerServerEvent('kingz-skills:updateSkill', 'skillname', amount)

-- Add reputation
TriggerServerEvent('kingz-skills:updateRep', 'category', amount)

-- Check if player has a perk
exports['kingz-skills']:HasPerk(source, 'skillname', perkLevel)

-- Check if player meets job requirements
exports['kingz-skills']:MeetsJobRequirements(source, 'jobname')

-- Get reputation effect
exports['kingz-skills']:GetReputationEffect(source, 'category', 'effectType')
Screenshots
[Insert screenshots here]

License
This resource is licensed under the MIT License. See the LICENSE file for details.

Credits
Developed by [Kingofdownloads]
UI powered by ox_lib
