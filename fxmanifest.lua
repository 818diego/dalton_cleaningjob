fx_version 'cerulean'
game 'gta5'

author 'Dalton Life'
description 'Cleaning Job System'
version '0.1'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    'config/config.lua',
    'client/main.lua',
    'client/locales.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/config.lua',
    'server/main.lua'
}

files {
    'locales/**.json',
}

dependencies {
    'qbx_core',
    'oxmysql',
    'ox_target',
    'ox_lib'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
