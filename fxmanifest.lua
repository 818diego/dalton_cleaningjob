fx_version 'cerulean'
game 'gta5'

author 'Dalton Life'
description 'Cleaning Job System'
version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'config/config.lua',
    'client/exp.lua',
    'client/main.lua',
    'client/locales.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/config.lua',
    'server/exp.lua',
    'server/main.lua'
}

files {
    'locales/**.json',
}

dependencies {
    'qbx_core',
    'ox_target',
    'ox_lib'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
