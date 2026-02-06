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
        {"Grab multiple lines", "script-message grab-multiple-lines"},
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

-- this function doesn't necessarily belong here, but this is a convenient place
local function reset_video()
    mp.set_property_number("video-zoom", 0)
    mp.set_property_number("panscan", 0)
    mp.set_property_number("pan-x", 0)
    mp.set_property_number("pan-y", 0)
    mp.set_property_number("video-align-x", 0)
    mp.set_property_number("video-align-y", 0)
end

mp.register_script_message("reset-video", reset_video)
mp.register_script_message("menu_popup", show_menu)
