local input = require 'mp.input'

local function show_menu()

    -- Menu entries: {Label, Command}
    local menu = {
        {"Playlist", "script-binding select/select-playlist"},
        {"Subtitles", "script-binding select/select-sid"},
        {"Secondary subtitles", "script-binding select/select-secondary-sid"},
        {"Subtitle lines", "script-message select-subtitle-lines-fixed"},
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

local function select_subtitle_lines_fixed()
    local sub = mp.get_property_native("current-tracks/sub")

    if sub == nil then
        show_warning("No subtitle is loaded.")
        return
    end

    if sub.external and sub["external-filename"]:find("^edl://") then
        sub["external-filename"] = sub["external-filename"]:match('https?://.*')
                                    or sub["external-filename"]
    end

    local r = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        args = sub.external
            and {"ffmpeg", "-loglevel", "error", "-i", sub["external-filename"],
                "-f", "srt", "-map_metadata", "-1", "-fflags", "+bitexact", "-"}
            or {"ffmpeg", "-loglevel", "error", "-i", mp.get_property("path"),
                "-map", "s:" .. sub["id"] - 1, "-f", "srt", "-map_metadata",
                "-1", "-fflags", "+bitexact", "-"}
    })

    if r.error_string == "init" then
        show_error("Failed to extract subtitles: ffmpeg not found.")
        return
    elseif r.status ~= 0 then
        show_error("Failed to extract subtitles.")
        return
    end

    -- Data storage
    local sub_times = {}
    local sub_lines = {}
    local delay = mp.get_property_native("sub-delay")
    local time_pos = mp.get_property_native("time-pos") - delay
    local duration = mp.get_property_native("duration", math.huge)
    local default_index = 0

    local output = r.stdout:gsub("\r\n", "\n") .. "\n\n"

    for block in output:gmatch("(.-)\n\n") do
        -- Updated Pattern: Capture Start Time, End Time, and Text Content
        -- Matches: Index -> newline -> (StartTime) --> (EndTime) -> newline -> (Text)
        local s_time_str, e_time_str, text_content = block:match("^[^\n]+\n(.-)%s%-%->%s(.-)\n(.*)")

        if text_content then
            local merged = text_content:gsub("\n", " ")
            merged = merged:match("^%s*(.-)%s*$")

            if merged and merged ~= "" then
                -- Store the full data object
                local h, m, s, ms = s_time_str:match("(%d+):(%d+):(%d+),(%d+)")
                local s_time = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
                table.insert(sub_times, s_time)

                s_time_str = mp.format_time(s_time, math.max(s_time, duration) >= 60 * 60 and "%H:%M:%S" or "%M:%S")
                
                -- Store just the text for the input menu
                table.insert(sub_lines,  s_time_str .. " " .. merged)
                
                if sub_times[default_index + 1] <= time_pos then
                    default_index = default_index + 1
                end
            end
        end
    end

    input.select({
        prompt = "Select a subtitle line:",
        items = sub_lines,
        default_item = default_index,
        submit = function(index)
            if mp.get_property_native("current-tracks/video/image") ~= false then
                delay = delay + 0.1
            end
            mp.commandv("seek", sub_times[index] + delay, "absolute")
        end
    })
end

mp.register_script_message("reset-video", reset_video)
mp.register_script_message("menu_popup", show_menu)
mp.register_script_message("select-subtitle-lines-fixed", select_subtitle_lines_fixed)