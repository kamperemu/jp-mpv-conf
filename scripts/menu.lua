local mp = require 'mp'
local input = require 'mp.input'

local function show_menu()

    -- Menu entries: {Label, Command}
    local menu = {
        {"Playlist", "script-binding select/select-playlist"},
        {"Subtitles", "script-binding select/select-sid"},
        {"Secondary subtitles", "script-binding select/select-secondary-sid"},
        {"Subtitle lines", "script-binding select/select-subtitle-line"},
        {"Audio tracks", "script-binding select/select-aid"},
        {"Key bindings", "script-binding select/select-binding"},
    }

    local labels = {}
    local commands = {}

    for _, entry in ipairs(menu) do
        labels[#labels + 1] = entry[1]
        commands[#commands + 1] = entry[2]
    end

    input.select({
        prompt = "",
        items = labels,
        keep_open = true,
        submit = function(i)
            mp.command(commands[i])
        end,
    })
end

mp.add_key_binding("MOUSE_BTN2", "menu_popup", show_menu)