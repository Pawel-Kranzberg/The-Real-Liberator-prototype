# The Real Liberator
#### Video Demo: https://youtu.be/jKniDknX5_c
#### Description:
'***The Real Liberator***' is an arcade game in the 1980s style, developed using Lua with LÖVE in late December 2022 by Paweł Kranzberg from Warsaw, Poland. It is based on Atari's classic '***Missile Command***' shoot'em up game from 1980, but offers a reverse experience: instead of defending against a nuclear attack, the player has an opportunity to attack the pesky defenders. Finally ;-) !

The game title is a play on the Atari's arcade spiritual successor to '***Missile Command***', that was called '***Liberator***' (1982). The original '***Liberator***' was touted as an opposite of '***Missile Command***', but its gameplay was quite different from it. '***The Real Liberator***' more closely matches the '***Missile Command***' style.

The player's objective in the game is destruction of six enemy bases, that are defended by three anti-missile batteries. In order to complete it, The player can launch up to 12 'regular' missiles with unitary warheads, and up to 4 'MRV' (multiple reentry vehicle) missiles with 4 warheads each. The regular missiles are operated with the left mouse button, while MRVs - with the right mouse button. The game tracks the cost of spent missiles - the fewer missiles the player uses to rain destruction from above, the more impressive their performance is.  

The project directory contains the following files:
* **conf.lua** - LÖVE basic configuration customization file. Of note, the file serves to:
    * define the game window size, and 
	* disable the LÖVE joystick module (as joystick is not yet supported in the game), in order to speed up the game initialization.
* **main.lua** - The main game program, comprising the classic Lua with LÖVE fuctions: *load*, *update* and *draw*, as well as custom functions:
    * *draw_buildings* - for, well, drawing of enemy buildings (bases and anti-missile batteries),
    * *reload* - for reloading of the player's missile launchers,
	* *get_distance* - for calculations of 2D Euclidean distances, in particular between anti-missiles and missiles, as part of anti-missiles' self-guidance.
* Three audio files in the OGG format, used with their respective owners' permissions:
    * **Atomic-Punk.ogg** - 'Atomic Punk' song by Karl Casey @ White Bat Audio, used as the games' main musical theme.
	* **Indian-Music-_-Safar-ASHUTOSH-_-No-Copyright-Free-Music.ogg** - Indian-style song, used as the victory theme.
    * **Wilhelm-scream.ogg** - Rendition of the 'Wilhelm scream' cliche sound effect, used as the defeat theme.	
* **README.md** - The markdown documentation file that you are currently reading.

I hope that you will enjoy '***The Real Liberator***'. Have fun :-)