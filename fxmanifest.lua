fx_version 'adamant'
game 'gta5'

author 'PRATNOKEN'
description 'Admin Menu for ESX'
version '1.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/script.js',
    'web/style.css'
}

dependencies {
    'ox_lib',
    'es_extended'
}
