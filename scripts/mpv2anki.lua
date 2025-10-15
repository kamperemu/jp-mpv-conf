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
  use_mpv_volume = false
}

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
  
  local tracks_count = mp.get_property_number("track-list/count")
  for i = 1, tracks_count do
    local track_type = mp.get_property(string.format("track-list/%d/type", i))
    local track_selected = mp.get_property(string.format("track-list/%d/selected", i))
    if track_type == "audio" and track_selected == "yes" then
      if mp.get_property(string.format("track-list/%d/external-filename", i), o) ~= o then
        source = mp.get_property(string.format("track-list/%d/external-filename", i))
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

  local sub_delay = mp.get_property_native("sub-delay")
  local audio_delay = mp.get_property_native("audio-delay")
  local s = math.min(mp.get_property_number('sub-start') + sub_delay - audio_delay)
  local e = math.max(mp.get_property_number('sub-end') + sub_delay - audio_delay)
  dlog(string.format('s=%d, e=%d', s, e))

  if e ~= 0 then
    create_screenshot(s, e)
    create_audio(s, e)
    local ifield = '<img src='.. get_name(s,e) ..'.' .. options.image_format .. '>'
    local afield = "[sound:".. get_name(s,e) .. ".mp3]"
    local tfield = string.gsub(string.gsub(lines,"\n+", "<br />"), "\r", "")
    add_to_last_added(ifield, afield, tfield)
  end
end

local function ex()
  if debug_mode then
    get_extract()
  else
    pcall(get_extract)
  end
end

mp.add_key_binding("ctrl+a", "update-anki-card", ex)
mp.add_key_binding("ctrl+A", ex)
