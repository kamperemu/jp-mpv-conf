# MPV Configuration Files for Mining to Anki

Just my personal config files for mining to anki in [mpv](https://mpv.io/), a free, open-source, & cross-platform media player. \
Apart from mining scripts the configuration also includes minimalist UI, gpu acceleration, font configurations, subtitle configurations, autoloading subtitles, video configurations and autoloading videos. 

> Before you start using this, please take your time to read this whole README as common issues can be easily solved by simply reading carefully.

## Installation

### Windows
- Get shinchiro (git) build from https://mpv.io/installation/ or https://github.com/shinchiro/mpv-winbuild-cmake/releases. You want to get the 7z starting with 
mpv-x86_64-v3 (click show all to make it visible).
- Extract the 7z to a folder of your choice. You won't be able to move to another folder or delete the files without reinstalling so choose wisely.
- Go to the installer folder and right click on mpv-install.bat to run as adminstrator. Follow the prompts to install.
- You can update mpv by running updater.bat as administrator. Follow the prompts. Once initial run of updater.bat has completed your update settings will be preserved and you only need to run updater.bat as administrator for future updates.
- Open %appdata% and create a folder called mpv.
- Download the zip of this repository and move it to the %appdata%\mpv folder. Then "Extract Here" using 7zip.

### Linux
- Install mpv from https://mpv.io/installation/ using a package manager of your choice.
- Download and extract contents of this repository into ~/.config/mpv.

### MacOS
- Untested for MacOS.
- Install mpv from https://mpv.io/installation/.
- Download and extract contents of this repository into ~/.config/mpv.
- Replace mpv_websocket binary with relevant binary from https://github.com/kuroahna/mpv_websocket/releases.
- Go to script-opts/mpv2anki.conf and set image_format to png.

## Mining
- Open video file with subtitles in mpv (subtitle files will auto load if they are in the same folder with same name as video file).
- Open [TexthookerUI](https://renji-xd.github.io/texthooker-ui/) (download offline version [here](https://raw.githubusercontent.com/Renji-XD/texthooker-ui/main/docs/index.html)) and connect to the websocket port.
- Wait for unknown word and add it to anki through texthooker and yomitan.
- Tab back to MPV and Ctrl + a to send paused sentence audio and image (align paused subtitle appropriately).
- Resume watching after updated note message popup.

## Interface and Keybinds
- The user interface is minimal and customizable. 
- The progress bar visibility reacts to cursor proximity to the bottom of the screen. 
- Press right click to pull up a menu. The menu has GUI for playlist, subtitles, secondary subtitles, subtitle lines, audio tracks and keybindings.
### Optional: Advanced configuration
- Refer to the [manual](https://mpv.io/manual/master/) to edit mpv.conf for general configuration.
- Refer to [manual](https://mpv.io/manual/master/) to edit keybinds in input.conf.
- Edit script config files in script-opts folder by using the comments.
- Edit menu items by modifying the menu.lua file in the scripts folder. 

## Scripts
- [mfpbar](https://codeberg.org/NRK/mpv-toolbox/src/branch/master/mfpbar) - progress-bar with minimal visual-clutter, features, as well as code-size.
- [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) - Automatically load playlist entries before and after the currently playing file, by scanning the directory.
- [mpv_websocket](https://github.com/kuroahna/mpv_websocket) - Uses websocket to send subtitle text to [texthooker UI](https://github.com/Renji-XD/texthooker-ui) so you can use a pop up dictionary.
- [mpv2anki](https://raw.githubusercontent.com/kamperemu/jp-mpv-conf/refs/heads/master/scripts/mpv2anki.lua) - Automatically sends current screenshot and sentence audio to previously made anki card.
- [menu](https://raw.githubusercontent.com/kamperemu/jp-mpv-conf/refs/heads/master/scripts/mpv2anki.lua) - Simple GUI menu for basic tasks.

## Additional Credits
- [mpv2anki](https://raw.githubusercontent.com/kamperemu/jp-mpv-conf/refs/heads/master/scripts/mpv2anki.lua) script is originally from [Acacreon Script](https://mega.nz/folder/349ziIYT#gtEzi4UtnyDVr4_wJAvBlg), however it is heavily modified from the original script.
- [menu](https://github.com/mpv-player/mpv/blob/master/player/lua/select.lua) script uses code from [select.lua](https://github.com/mpv-player/mpv/blob/master/player/lua/select.lua).
- Inspired by [Zabooby's mpv config](https://github.com/Zabooby/mpv-config).

## Contributions
Feel free to send a pull request for anything.
