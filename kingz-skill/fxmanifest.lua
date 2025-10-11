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

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'mysql-compat.lua',
    'server/main.lua'
}

client_script 'client/main.lua'

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib'
}

lua54 'yes'
