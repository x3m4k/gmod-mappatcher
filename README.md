# MapPatcher Enhanced
An enhanced version of an addon I liked.
#### Original Description
An easy-to-use tool which allows server staff to patch various exploits within maps.
Multiple exploits exist in maps that allow players to get out of the map when they're not supposed to. This tool allows for server staff to patch such exploits in less than a minute. Aside from exploit patching, this tool also allows you to block off parts of a map using forcefields, or setup teleport points, making your map one of a kind.

# ! This addon will not work if the original MapPatcher is enabled
## How to migrate from the original MapPatcher addon
MapPatcher Enhanced stores data in separate directory "mappatcher_enhanced", just copy all files from<br>"\<gmod dir>/garrysmod/data/mappatcher/" to "\<gmod dir>/garrysmod/data/mappatcher_enhanced"

#### Original Addon
* Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=1572250342
* Repository: https://github.com/h3xcat/gmod-mappatcher

#### Enhanced version
* Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3032883716
* Repository: https://github.com/x3m4k/gmod-mappatcher

## To Clone
This repo uses submodules so you have to use `git` command to get complete addon. Using the "Download ZIP" will give an incomplete addon!

**Command:** `git clone https://github.com/x3m4k/gmod-mappatcher.git --recurse-submodules`

## Steam Workshop

https://steamcommunity.com/sharedfiles/filedetails/?id=3032883716

## Video Demo (original addon)
https://www.youtube.com/watch?v=48pFpVRVkpY

## Features (original)

* Ability to view map playerclip brushes, makes finding map exploits 100 times easier.
* No resource files, meaning no impact on download time on join. The textures are generated through Lua.
* Gamemode independent tool, should work with most gamemodes.
* Translation support.

## Features (enhanced)
* Grid-placement system
  * Use G+ and G- key combinations to increase and decrease grid size by 1 unit. By holding shift, you can change size by 8 units per time.
  * By default, grid system is based on 16 units grid, starting at point 0,0,0. In most cases, this is inconvenient (grid skips your desired spot). To make sure grid is starting at your point, turn off grid system, place a point (with LMB) where you want to start grid, then turn on grid system and grid origin will be at your spot. 
* Context menu (to open, press RMB on object's name)<br><img width="500" src="https://i.imgur.com/FkaC6pw.png">
  * Inside context menu you can:
    * Insert object of any type inside (stacking them in one place)
    * Change class of the object

## Available Brush Types (original)

* **Custom** - A combination of various other tools + extra. Probably something I should have done initially.
* **Player Clip** - Collides with players but nothing else.
* **Prop Clip** - Blocks props.
* **Bullet Clip** - Blocks bullets but nothing else.
* **Clip** - Blocks everything.
* **Force Field** - Clip with sound and texture.
* **Hurt** - Damages players over time, various time intervals are customizable through the menu.
* **Kill** - Kills anyone on touch.
* **Remove** - Removes any entities that touches it.
* **Teleport** - Teleport player to given destination.
* **TP Target** - Teleport target used by teleport brush. 

## New Brush Types (enhanced)
* **[x3m4k] Push** - Push the objects (and players) out.
* **[x3m4k] Kill** - Kill/delete specified objects when touched.
* **[x3m4k] Clip** - Multipurpose clip tool.

## New Point Types (enhanced)
* **[x3m4k] Ladder** - A simple ladder with customizable height and model.

## Commands

`mappatcher` - Opens the mappatcher editor.

`mappatcher_draw 0/1` - Enables the drawing of objects and clip brushes outside the editor.

## Setup

Just drop the folder into addons folder. If you have ULX or ServerGuard installed, you can setup access through admin mod, otherwise you can change permissions in mappatcher/lua/mappatcher/config.lua.

## Screenshots

![](https://i.imgur.com/lbOL3GR.png)
![](https://i.imgur.com/NNwDeBc.png)
![](https://i.imgur.com/Jgmj4So.png)
