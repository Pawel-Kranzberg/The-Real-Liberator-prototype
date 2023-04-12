-- Configuration
-- configuration = {}

function love.conf(t)
	t.window.title = "The Real Liberator" -- the title of the game window (string)
	t.version = "11.4"         -- the LÖVE version this game was made for (string)
	
	t.audio.mixwithsystem = false
	
	t.window.width = 800
	t.window.height = 600
	-- t.window.resizable = true
	
	t.modules.joystick = false

	-- For Windows debugging
	t.console = false
	
	-- custom settings
	-- t.timers = {}
	-- t.timers.Unitary_Warhead = 1
	-- t.timers.MIRV = 1.5
	-- t.timers.S400 = 5	
	
	-- configuration = t
end