fx_version 'cerulean'
game 'gta5'

author 'Kingz Development ;)'
description 'Kingz Skills - Hybrid Skill and Rep System for QBCore with ox_lib UI'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'qb-core',
    'oxmysql',  -- For database interactions
    'ox_lib'    -- For enhanced UI
}

lua54 'yes'
