------------- Instructions -------------
-- Open your anime with japanese subtitles in MPV
-- Wait for unknown word and add it to anki through yomitan
-- Tab back to MPV and Ctrl + a
-- Done. The lines, their respective Audio and the current paused image will be added to the back of the card.
-- Make sure to edit user config in script-opts/mpv2anki.conf
----------------------------------------

------------- Credits -------------
-- This original script was made by users of 4chan's Daily Japanese Thread (DJT) on /jp/
-- The second version of the script can be found here https://mega.nz/folder/349ziIYT#gtEzi4UtnyDVr4_wJAvBlg
-- The current version of the script removes clipboard copy so websocket can be used (https://github.com/kuroahna/mpv_websocket)
------------------------------------

local options = {
  -- Anki fields
  front_field = "Expression",
  sentence_field = "Sentence",
  sentence_audio_field = "SentenceAudio",
  image_field = "Picture",
  -- Optional padding and fade settings in seconds.
  audio_clip_fade = 0.2,
  audio_clip_padding = 0.75,
  -- Optional screenshot image format.
  image_format = "webp",
  -- Optional mpv volume to affect Anki card volume.
  use_mpv_volume = false,
  -- Optional play after anki update
  auto_play_anki = true
}

local input = require 'mp.input'
local utils = require 'mp.utils'
local msg = require 'mp.msg'
mp.options = require "mp.options"
mp.options.read_options(options, "mpv2anki")

local debug_mode = false
local prefix

if unpack ~= nil then table.unpack = unpack end

local function dlog(...)
  if debug_mode then
    print(...)
  end
end

local function get_name(s, e)
  return mp.get_property("filename"):gsub('%W','').. tostring(s) .. tostring(e)
end

local function create_audio(s, e)

  if s == nil or e == nil then
    return
  end

  local name = get_name(s, e)
  local destination = utils.join_path(prefix, name .. '.mp3')
  s = s - options.audio_clip_padding
  local t = e - s + options.audio_clip_padding
  local source = mp.get_property("path")
  local aid = mp.get_property("aid")

  local tracks = mp.get_property_native("track-list")
  for _, track in ipairs(tracks) do
    if track["type"] == "audio" and track["selected"] then
      if track["external-filename"] then
        source = track["external-filename"]
        aid = 'auto'
      end
      break
    end
  end

  local cmd = {
    'run',
    'mpv',
    source,
    '--loop-file=no',
    '--video=no',
    '--no-ocopy-metadata',
    '--no-sub',
    '--audio-channels=1',
    string.format('--start=%.3f', s),
    string.format('--length=%.3f', t),
    string.format('--aid=%s', aid),
    string.format('--volume=%s', options.use_mpv_volume and mp.get_property('volume') or '100'),
    string.format("--af-append=afade=t=in:curve=ipar:st=%.3f:d=%.3f", s, options.audio_clip_fade),
    string.format("--af-append=afade=t=out:curve=ipar:st=%.3f:d=%.3f", s + t - options.audio_clip_fade, options.audio_clip_fade),
    string.format('-o=%s', destination)
  }
  mp.commandv(table.unpack(cmd))
  dlog(utils.to_string(cmd))
end

local function create_screenshot(s, e)
  local source = mp.get_property("path")
  local img = utils.join_path(prefix, get_name(s,e) .. '.' .. options.image_format)

  local cmd = {
    'run',
    'mpv',
    source,
    '--loop-file=no',
    '--audio=no',
    '--no-ocopy-metadata',
    '--no-sub',
    '--frames=1',
  }
  if options.image_format == 'webp' then
    table.insert(cmd, '--ovc=libwebp')
    table.insert(cmd, '--ovcopts-add=lossless=0')
    table.insert(cmd, '--ovcopts-add=compression_level=6')
    table.insert(cmd, '--ovcopts-add=preset=drawing')
  elseif options.image_format == 'png' then
    table.insert(cmd, '--vf-add=format=rgb24')
    table.insert(cmd, '--ovc=png')
  end
  table.insert(cmd, '--vf-add=scale=480*iw*sar/ih:480')
  table.insert(cmd, string.format('--start=%.3f', mp.get_property_number("time-pos")))
  table.insert(cmd, string.format('-o=%s', img))
  mp.commandv(table.unpack(cmd))
  dlog(utils.to_string(cmd))
end

local function anki_connect(action, params)
  local request = utils.format_json({action=action, params=params, version=6})
  local args = {'curl', '-s', 'localhost:8765', '-X', 'POST', '-d', request}

  local result = utils.subprocess({ args = args, cancellable = true, capture_stderr = true })
  dlog(result.stdout)
  dlog(result.stderr)
  return utils.parse_json(result.stdout)
end

local function add_to_last_added(ifield, afield, tfield)
  local added_notes = anki_connect('findNotes', {query='added:1'})["result"]
  table.sort(added_notes)
  local noteid = added_notes[#added_notes]
  local note = anki_connect('notesInfo', {notes={noteid}})

  if note ~= nil then
    local word = note["result"][1]["fields"][options.front_field]["value"]
	word = word:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
	tfield = tfield:gsub(word, "<b>%0</b>")
    local new_fields = {
      [options.sentence_audio_field]=afield,
      [options.sentence_field]=tfield,
      [options.image_field]=ifield
    }

    anki_connect('updateNoteFields', {
      note={
        id=noteid,
        fields=new_fields
      }
    })

    mp.osd_message("Updated note: " .. word, 3)
    msg.info("Updated note: " .. word)
  end
end

local function get_extract()
  prefix = anki_connect('getMediaDirPath')["result"]
  dlog(prefix)
  local lines = mp.get_property_native("sub-text")
  dlog(lines)

  if lines == nil or lines == "" then
    local time_pos = math.min(mp.get_property_number("time-pos"))
    create_screenshot(time_pos, time_pos)
    local ifield = '<img src='.. get_name(time_pos,time_pos) ..'.' .. options.image_format .. '>'
    add_to_last_added(ifield, "", "")
    return
  end 

  local sub_delay = mp.get_property_native("sub-delay")
  local audio_delay = mp.get_property_native("audio-delay")
  local s = math.min(mp.get_property_number('sub-start') + sub_delay - audio_delay)
  local e = math.max(mp.get_property_number('sub-end') + sub_delay - audio_delay)
  dlog(string.format('s=%d, e=%d', s, e))
  if options.auto_play_anki then
    mp.set_property_bool("pause", false)
  end

  if e ~= 0 then
    create_screenshot(s, e)
    create_audio(s, e)
    local ifield = '<img src='.. get_name(s,e) ..'.' .. options.image_format .. '>'
    local afield = "[sound:".. get_name(s,e) .. ".mp3]"
    local tfield = lines:gsub("\n", "<br />")
    add_to_last_added(ifield, afield, tfield)
  end
end

local function get_multiple_extract(tfield, s, e)
	if options.auto_play_anki then
    mp.set_property_bool("pause", false)
  end
  prefix = anki_connect('getMediaDirPath')["result"]
  dlog(prefix)

  create_screenshot(s, e)
  create_audio(s, e)
  local ifield = '<img src='.. get_name(s,e) ..'.' .. options.image_format .. '>'
  local afield = "[sound:".. get_name(s,e) .. ".mp3]"
  local tfield = tfield
  add_to_last_added(ifield, afield, tfield)
end

local function ex()
  if debug_mode then
    get_extract()
  else
    pcall(get_extract)
  end
end

local function exm(tfield, s, e)
  if debug_mode then
    get_multiple_extract(tfield, s, e)
  else
    pcall(get_multiple_extract, tfield, s, e)
  end
end

local function grab_multiple_lines()
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
    local sub_data = {}
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
            merged = merged:gsub("<.->", "")                -- Strip HTML tags
                           :gsub("\\h+", " ")               -- Replace '\h' tag
                           :gsub("{[\\=].-}", "")           -- Remove ASS formatting
                           :gsub("^%s*(.-)%s*$", "%1")      -- Strip whitespace
                           :gsub("^m%s[mbl%s%-%d%.]+$", "") -- Remove graphics code

            if merged and merged ~= "" then
                local sh, sm, ss, sms = s_time_str:match("(%d+):(%d+):(%d+),(%d+)")
                local s_time = tonumber(sh) * 3600 + tonumber(sm) * 60 + tonumber(ss)
                local eh, em, es, ems = e_time_str:match("(%d+):(%d+):(%d+),(%d+)")
                local e_time = tonumber(eh) * 3600 + tonumber(em) * 60 + tonumber(es)
                -- Store the full data object
                table.insert(sub_data, {
                    text = merged,
                    start_sec = s_time,
                    end_sec = e_time
                })
                
				s_time_str = mp.format_time(s_time, math.max(s_time, duration) >= 60 * 60 and "%H:%M:%S" or "%M:%S")
                -- Store just the text for the input menu
                table.insert(sub_lines,  s_time_str .. " " .. merged)

                if s_time <= time_pos then
                    default_index = default_index + 1
                end
            end
        end
    end
  
    if default_index == 0 then
        default_index = 1
    end

-- UI Selection
    input.select({
        prompt = "Select the FIRST line:",
        items = sub_lines,
        default_item = default_index,
        submit = function(start_index)
			-- Create a new list for the second menu containing only lines
            -- from the start_index onwards (removing previous lines)
            local end_selection_items = {}
			for i = start_index, #sub_lines do
                table.insert(end_selection_items, sub_lines[i])
            end
			
			-- Open the second menu
			input.select({
                prompt = "Select the LAST line:",
                items = end_selection_items,
                default_item = 1,
                submit = function (relative_end_index)
					-- Calculate the absolute index of the last line
                    local end_index = start_index + relative_end_index - 1
					
                    -- Create the final list of lines (removing everything after end_index)
					local result_lines = {}
					for i = start_index, end_index do
						table.insert(result_lines, sub_data[i].text)
					end
					tfield = table.concat(result_lines, "<br />")

					local start_time = sub_data[start_index].start_sec
					local end_time = sub_data[end_index].end_sec

					exm(tfield, start_time, end_time)
                end,
            })
        end
    })
end

mp.register_script_message("update-anki-card", ex)
mp.register_script_message("grab-multiple-lines", grab_multiple_lines)
