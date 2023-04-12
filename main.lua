require 'math'

function love.load()
	-- t = configuration
	debug = false  -- true
	
	started = false
	victory = false
	defeat = false
	
	-- Initial graphics setup:
	-- set the background color to a nice blue
	-- love.graphics.setBackgroundColor(0.41, 0.53, 0.97)
	love.graphics.setBackgroundColor(0, 0, 0)
	-- love.window.setMode(screen_width, screen_height) -- set the window dimensions
	--love.window.setFullscreen(true, "exclusive")
	
	-- Mouse configuration:
	love.mouse.setGrabbed(false)
	is_mouse_button_down = {[1] = false, [2] = false}

	-- Player's starting configuration:
	launchers = {}
	launchers.UW = {
		button = 1,
		--color = {[0] = 0, [1] = 1, [2] = 0},
		color = {r = 0, g = 1, b = 0},
		width = 30,
		height = 30,
		can_fire = true, 
		x = 100,
		y = 10,
		missiles = 12, --
		reload_time = 1,
		reload_timer = 0,
		max_detonation_y = love.graphics.getHeight() * 0.85,
		explosion_radius = 70,
		cost = 10,
	}
	launchers.MRV_missiles = {
		button = 2,
		color = {r = 0, g = 1, b = 0.5},
		width = 30,
		height = 30,
		can_fire = true, 
		x = 200,
		y = 10,
		missiles = 4,
		reload_time = 1.5,
		reload_timer = 0,
		max_detonation_y = love.graphics.getHeight() * 0.8,
		explosion_radius = 45,
		cost = 60,
		warheads = 4,
	}
	missiles = {UW = {}, MRV_warheads = {}, MRV_missiles = {}}
	explosions = {UW = {}, MRV_warheads = {}, antimissiles = {}}
	cost = 0
	
	-- Physics configuration:
	meter = 1  -- the lenght of a meter in our world will be 1px
	love.physics.setMeter(meter)  
	-- create a world for the bodies to exist in with horizontal gravity
	-- of 0 and vertical gravity of 9.81
	world = love.physics.newWorld(0, 9.81 * meter, true)
	
	window_width = love.graphics:getWidth()
	window_height = love.graphics:getHeight()

	-- Ground configuration:
	local ground_depth = 50
	ground = {color = {r = 0.28, g = 0.63, b = 0.05}}  -- Set the drawing color to green for the ground
	-- the shape (the rectangle we create next) anchors to the body from its center
	ground.body = love.physics.newBody(
		world, 
		math.floor(window_width / 2), 
		window_height - math.floor(ground_depth / 2)
	)
	-- make a rectangular shape
	ground.shape = love.physics.newRectangleShape(window_width, ground_depth)
	-- attach the shape to the body
	ground.fixture = love.physics.newFixture(ground.body, ground.shape)

	-- Airdefence configuration:
	AA = {}
	local launchers_n = 3
	for i=1, launchers_n do
		AA[i] = {
			is_active = true,
			can_fire = true,
			missiles = 8,
			antimissiles_in_flight = 0,
			-- missiles_in_flight = 0,
			reload_time = 1,
			reload_timer = 0,
			color_basic = {r = 0.5, g = 0.7, b = 0},
			color_destroyed = {r = 1, g = 0, b = 0},
			body = love.physics.newBody(
				world, 
				math.floor((window_width * 0.95 / (launchers_n - 1)) * (i - 1) + window_width * 0.025), 
				math.floor(window_height - ground_depth * 1.25), 
				'static'
			),
			shape = love.physics.newRectangleShape(
				math.floor(window_width * 0.04),
				math.floor(window_height * 0.05)
			)
		}
		AA[i]['fixture'] = love.physics.newFixture(AA[i].body, AA[i].shape)
	end
	antimissiles = {}
	
	-- Bases configuration:
	bases = {}
	local base_groups_n = 2
	local bases_per_group_n = 3
	local group_width = math.floor(window_width * 0.8 / base_groups_n)
	local base_halfwidth = math.floor(group_width / bases_per_group_n / 2)
	for i=1, base_groups_n do
		for j=1, bases_per_group_n do
			base = {
				is_active = true,
				color_basic = {r = 0.8, g = 0.5, b = 0.1},
				color_destroyed = {r = 1, g = 0, b = 0},
				body = love.physics.newBody(
					world,
					group_width * (i - 1) + math.floor(window_width * 0.05 * (2 * (i - 1) + 1) + base_halfwidth * (2 * (j - 1) + 1)),
					math.floor(window_height - ground_depth * 1.15),
					'static'
				),
				shape = love.physics.newRectangleShape(
					math.floor(window_width * 0.05),
					math.floor(window_height * 0.035)
				)
			}
			base.fixture = love.physics.newFixture(base.body, base.shape)
			table.insert(bases, base)
		end
	end
	
	-- Audio setup:
	atomic_punk = love.audio.newSource('Atomic-Punk.ogg', 'static')
	defeat_sound = love.audio.newSource('Wilhelm-scream.ogg', 'static')
	victory_song = love.audio.newSource('Indian-Music-_-Safar-ASHUTOSH-_-No-Copyright-Free-Music.ogg', 'static')
end


function love.update(dt)
	-- Easy way to exit the game:
	if love.keyboard.isDown('escape') then
		love.event.push('quit')
	end
	
	if not started and love.keyboard.isDown('space') then started = true end
	
	if victory and not victory_song:isPlaying() then
		victory_song:play()
	elseif defeat and not defeat_sound:isPlaying() then
		defeat_sound:play()
	elseif not atomic_punk:isPlaying() then 
		atomic_punk:play() 
	end

	world:update(dt) -- this puts the world into motion
	
	-- Explosions handling:
	local are_explosions = false
	for k, v in pairs(explosions) do
		local explosions_temp = {}
		local next = next  -- For efficiency, cf. https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
		if next(v) then			
			are_explosions = true
			for _, e in ipairs(v) do
				local explosion_x, explosion_y = e['body']:getPosition()
				local radius = e['shape']:getRadius()
				if radius < e['explosion_radius'] - 2 then
					radius = radius + 2
					e['shape']:setRadius(radius)
					table.insert(explosions_temp, e)
				else
					-- e['shape']:destroy()
					e['body']:destroy()
				end
				for _, ov in pairs(missiles) do
					for _, o in ipairs(ov) do
						local object_x, object_y = o['body']:getPosition()
						local distance = get_distance(explosion_x, explosion_y, object_x, object_y)
						if distance <= radius then
							o['is_active'] = false
							-- o['shape']:destroy()
							-- o['body']:destroy()
						end
					end
				end
				for _, o in ipairs(antimissiles) do
					local object_x, object_y = o['body']:getPosition()
					local distance = get_distance(explosion_x, explosion_y, object_x, object_y)
					if distance <= radius then
						o['is_active'] = false
						-- o['shape']:destroy()
						-- o['body']:destroy()
					end
				end
				if k ~= 'antimissiles' then
					for _, t in ipairs({AA, bases}) do
						for _, o in ipairs(t) do
							local object_x, object_y = o['body']:getPosition()
							local distance = get_distance(explosion_x, explosion_y, object_x, object_y)
							if distance <= radius then
								o['is_active'] = false
							end
						end
					end
				end
			end
		end
		explosions[k] = explosions_temp
	end
	
	-- Bases handling:
	local active_bases = 0
	for _, v in ipairs(bases) do
		if v.is_active then
			active_bases = active_bases + 1
		end
	end
	if not victory and active_bases == 0 then
		victory = true
		love.audio.stop()
	end
	
	-- Reloading of Player's launchers:

	local are_missiles_in_stock = reload(dt, launchers)
	-- print(are_missiles_in_stock)
	
	-- Missile flight handling:
	local are_missiles_in_flight = false
	for _, v in ipairs(AA) do
		v.missiles_in_flight = 0
	end
	for k, v in pairs(missiles) do
		local missiles_temp = {}
		local next = next  -- For efficiency, cf. https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
		if next(v) then
			are_missiles_in_flight = true
			for _, m in ipairs(v) do
				if not m.is_active then
				elseif m.body:getY() < m['detonation_y'] then
					local velocity_x, velocity_y = m.body:getLinearVelocity()
					m.body:setAngle(-math.atan(velocity_x / velocity_y))
					table.insert(missiles_temp, m)
					local AA_sector_ID = math.min(#AA, math.floor(math.min(window_width, math.max(0, m.body:getX())) / (window_width / #AA)) + 1)
					AA[AA_sector_ID].missiles_in_flight = AA[AA_sector_ID].missiles_in_flight + 1
				else
					if k == 'MRV_missiles' then
						local velocity_x, velocity_y = m.body:getLinearVelocity()
						local position_x, position_y = m.body:getPosition()
						local median = (1 + launchers[k]['warheads']) / 2
						for n=1, launchers[k]['warheads'] do
							local turn = ((n - median) / median) * 1.05
							-- print(turn)
							local warhead = {
								is_active = true,
								detonation_y = 510, -- to configuration
								color = launchers[k]['color'],
								explosion_radius = launchers[k]['explosion_radius'],
								body = love.physics.newBody(world, position_x, position_y, 'dynamic'),
								shape = love.physics.newPolygonShape(-2, 0, 0, 5, 2, 0), -- to configuration								
							}
							warhead['fixture'] = love.physics.newFixture(warhead.body, warhead.shape, 1)
							warhead.body:applyLinearImpulse(
								15000 * turn, 
								30000 * (1 - math.abs(turn))
							)
							-- warhead.body:setLinearVelocity(
								-- velocity_x * 1.0 * turn, 
								-- velocity_y * 1.0 * (1 - math.abs(turn))
							-- )
							table.insert(missiles['MRV_warheads'], warhead)
						end
					else
						local position_x, position_y = m.body:getPosition()
						explosion = {
							color = {r = 1, g = 0.9, b = 0.9}, -- to configuration
							explosion_radius = m['explosion_radius'],
							body = love.physics.newBody(world, position_x, position_y, 'kinematic'),
							shape = love.physics.newCircleShape(4)
						}
						explosion['fixture'] = love.physics.newFixture(explosion.body, explosion.shape)
						table.insert(explosions[k], explosion)
					end
					-- v[i] = nil
				end
			end
		end
		missiles[k] = missiles_temp
	end

	-- Airdefence handling:
	-- Antimissiles handling:
	for _, v in ipairs(AA) do
		v.antimissiles_in_flight = 0
	end
	local antimissiles_temp = {}
	for _, am in ipairs(antimissiles) do		
		if not am.is_active then
		else
			local position_x, position_y = am.body:getPosition()
			am.duration = am.duration - 1
			local target = {x = nil, y = nil, min_distance = math.huge}
			for _, v in pairs(missiles) do
				local next = next  -- For efficiency, cf. https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
				if next(v) then
					for _, m in ipairs(v) do
						local m_x, m_y = m.body:getPosition()
						local distance = get_distance(position_x, position_y, m_x, m_y)
						if distance < target.min_distance then
							target.x = m_x
							target.y = m_y
							target.min_distance = distance
						end
					end
				end
			end
			if target.min_distance <= am['explosion_radius'] then
				explosion = {
					color = {r = 1, g = 0.75, b = 0}, -- to configuration
					explosion_radius = am['explosion_radius'],
					body = love.physics.newBody(world, position_x, position_y, 'kinematic'),
					shape = love.physics.newCircleShape(2)
				}
				explosion['fixture'] = love.physics.newFixture(explosion.body, explosion.shape)
				table.insert(explosions['antimissiles'], explosion)
			elseif am.duration <= 0 then
			elseif position_y > window_height * 0.9 then
			else
				local velocity_x = 0
				local velocity_y = -1000
				if target.x ~= nil then
					-- print('TURN')
					local distance_x = position_x - target.x
					local distance_y = position_y - target.y
					local total_distance = math.abs(distance_x) + math.abs(distance_y)
					velocity_x = -1000 * distance_x / total_distance
					velocity_y = -1000 * distance_y / total_distance					
				end
				-- print(velocity_x, velocity_y)
				am['body']:setLinearVelocity(velocity_x, velocity_y)
				-- local velocity_x, velocity_y = am.body:getLinearVelocity()
				am.body:setAngle(-math.atan(velocity_x / velocity_y))
				table.insert(antimissiles_temp, am)
				local AA_sector_ID = math.min(#AA, math.floor(math.min(window_width, math.max(0, position_x)) / (window_width / #AA)) + 1)
				AA[AA_sector_ID].antimissiles_in_flight = AA[AA_sector_ID].antimissiles_in_flight + 1
			end
		end
	end
	antimissiles = antimissiles_temp
	-- Airdefence launchers handling:
	for _, e in ipairs(explosions['antimissiles']) do
		local position_x, position_y = e.body:getPosition()
		local AA_sector_ID = math.min(#AA, math.floor(math.min(window_width, math.max(0, position_x)) / (window_width / #AA)) + 1)
		AA[AA_sector_ID].antimissiles_in_flight = AA[AA_sector_ID].antimissiles_in_flight + 1
	end
	-- local are_antimissiles_in_stock = false
	for _, v in pairs(AA) do
		if v.is_active then
			-- Reloading of airdefence launchers:
			-- print(k, v['missiles'])
			if v['can_fire'] then
				if v['missiles_in_flight'] > v['antimissiles_in_flight'] then
					local position_x, position_y = v.body:getPosition()
					antimissile = {
						is_active = true,
						color = {r = 0, g = 0.1, b = 0.7},  -- to configuration
						explosion_radius = 30,  -- to configuration
						duration = 270,  -- to configuration
						body = love.physics.newBody(world, position_x, position_y - 10, 'dynamic'),
						shape = love.physics.newPolygonShape(-2, 0, 0, -5, 2, 0), -- to configuration
					}
					antimissile['fixture'] = love.physics.newFixture(antimissile.body, antimissile.shape)
					antimissile['body']:setLinearVelocity(0, -1000)  -- to configuration
					table.insert(antimissiles, antimissile)
					v['can_fire'] = false
					v['missiles'] = v['missiles'] - 1
				end
			elseif v['missiles'] > 0 then
				-- are_antimissiles_in_stock = true
				v['reload_timer'] = v['reload_timer'] - dt
				if v['reload_timer'] < 0 then
					v['can_fire'] = true
					v['reload_timer'] = 0
				end
			end
		end
	end
	-- are_antimissiles_in_stock = reload(dt, AA, are_antimissiles_in_stock)

	-- Mouse action handling:
	local is_action = false
	for i=1, 2 do
		if love.mouse.isDown(i) 
			and started
			and not (victory or defeat)
			then
			is_action = true
			is_mouse_button_down[i] = true
		else
			is_mouse_button_down[i] = false
		end		
	end
	-- for k, v in pairs(is_mouse_button_down) do print(k, v) end
	-- if love.mouse.isDown({1, 2}) then
	if is_action then
		local x, y = love.mouse.getPosition()
		if y < love.graphics.getHeight() / 10 then  -- to configuration
			for _, v in pairs(launchers) do
				if is_mouse_button_down[v['button']] then
					-- print(v['button'])
					v['x'] = math.min(
						math.max(0, x - math.floor(v['width'] / 2)),
						window_width - v['width']
					)
				end
			end
		else
			for k, v in pairs(launchers) do
				if is_mouse_button_down[v['button']] then
					if v['can_fire'] then
						-- print('shoot', v['button'])
						-- Launch a missile:						
						local missile_x = v.x + math.floor(v['width'] / 2)
						local missile_y = v.y + v.height
						local delta_x = (missile_x - x)
						local delta_y = (missile_y - y)
						local delta_total = math.abs(delta_x) + math.abs(delta_y)
						-- local angle = math.atan(delta_x / delta_y)
						local missile = {
							is_active = true,
							detonation_y = math.min(y, launchers[k]['max_detonation_y']),
							color = launchers[k]['color'],
							explosion_radius = launchers[k]['explosion_radius'],
							body = love.physics.newBody(world, missile_x, missile_y, "dynamic"),
							shape = love.physics.newPolygonShape(-4, 0, 0, 10, 4, 0), -- to configuration
						}
						missile['fixture'] = love.physics.newFixture(missile.body, missile.shape, 1)
						missile.body:setAngle(-math.atan(delta_x / delta_y))
						missile.body:applyLinearImpulse(
							-50000 * (delta_x / delta_total), 
							-50000 * (delta_y / delta_total)
						)					
						table.insert(missiles[k], missile)
						v['can_fire'] = false
						launchers[k]['reload_timer'] = launchers[k]['reload_time']
						launchers[k]['missiles'] = launchers[k]['missiles'] - 1
						cost = cost + launchers[k]['cost']
					end
				end
			end
		end		
	end
	
	if not defeat and not victory
		and not are_missiles_in_stock
		and not are_missiles_in_flight
		and not are_explosions
		then
		defeat = true
		love.audio.stop()
	end

	if (victory or defeat) and love.keyboard.isDown('space') then
		launchers.UW.can_fire = true
		launchers.UW.x = 100
		launchers.UW.missiles = 12
		launchers.UW.reload_timer = 0
		launchers.MRV_missiles.x = 200
		launchers.MRV_missiles.can_fire = true
		launchers.MRV_missiles.missiles = 4
		launchers.MRV_missiles.reload_timer = 0
		missiles = {UW = {}, MRV_warheads = {}, MRV_missiles = {}}
		explosions = {UW = {}, MRV_warheads = {}, antimissiles = {}}
		cost = 0
		for _, v in ipairs(AA) do
			v.is_active = true
			v.can_fire = true
			v.missiles = 8
			v.antimissiles_in_flight = 0
			-- v.missiles_in_flight = 0  -- already done by missile handling
			v.reload_timer = 0
		end
		antimissiles = {}
		for _, v in ipairs(bases) do
			v.is_active = true
		end
		victory = false
		defeat = false
		love.audio.stop()
	end
end

function love.draw()
	-- Start & end:
	if not started then
		love.graphics.setColor(1, 0, 0)
		love.graphics.print('The Real Liberator', window_width/2-45, window_height/2-90)
		love.graphics.print(string.format('Use missiles to destroy the %d enemy bases!', #bases), window_width/2-100, window_height/2-60)
		love.graphics.print('Use mouse buttons on the screen top to set missile entry points.', window_width/2-150, window_height/2-40)
		love.graphics.print('Use mouse buttons below to set entry angles and burst heigths.', window_width/2-150, window_height/2-20)
		love.graphics.print("Press 'space' to start.", window_width/2-50, window_height/2)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print('Game design & coding by Paweł Kranzberg', window_width/2-100, window_height/2+30)
		love.graphics.print('Main music theme (Atomic Punk) by Karl Casey @ White Bat Audio', window_width/2-160, window_height/2+50)
	elseif victory or defeat then
		love.graphics.setColor(1, 1, 1)
		if victory then
			love.graphics.print('You have won, congratulations!', window_width/2-70, window_height/2-20)
		else
			love.graphics.print('You have lost, take the L!', window_width/2-70, window_height/2-20)
		end
		-- love.graphics.setColor(1, 1, 1)
		love.graphics.print("Press 'space' to restart.", window_width/2-50, window_height/2)
	end
	
	-- Draw the player's launchers:
	for k, v in pairs(launchers) do
		-- print(k)
		-- print(v.color['r'])
		--love.graphics.setColor(v.color[0], v.color[1], v.color[2])
		love.graphics.setColor(v.color['r'], v.color['g'], v.color['b'])
		love.graphics.polygon('fill', v.x, v.y, v.x + v.width, v.y, v.x + math.floor(v.width / 2), v.y + v.height)
		love.graphics.setColor(0, 0, 0)  -- to configuration
		love.graphics.print(v['missiles'], v.x + 9, v.y + 1)
	end

	-- Draw the missiles:
	for _, v in pairs(missiles) do
		local next = next  -- For efficiency, cf. https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
		if next(v) then
			for _, m in ipairs(v) do
				love.graphics.setColor(m.color.r, m.color.g, m.color.b)
				love.graphics.polygon('fill', m.body:getWorldPoints(m.shape:getPoints()))
			end
		end
	end

	-- Draw the antimissiles:
	for _, m in pairs(antimissiles) do
		love.graphics.setColor(m.color.r, m.color.g, m.color.b)
		love.graphics.polygon('fill', m.body:getWorldPoints(m.shape:getPoints()))
	end

	-- Draw the bases:
	draw_buildings(bases)	
	
	-- Draw the airdefence launchers:
	draw_buildings(AA)
	
	-- Draw the explosions:
	for _, v in pairs(explosions) do
		local next = next  -- For efficiency, cf. https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
		if next(v) then
			for _, e in ipairs(v) do
				love.graphics.setColor(e.color.r, e.color.g, e.color.b)
				love.graphics.circle('fill', e.body:getX(), e.body:getY(), e.shape:getRadius())
			end
		end
	end	
	
	-- Draw the ground:
	love.graphics.setColor(ground.color['r'], ground.color['g'], ground.color['b'])
	-- Draw a "filled in" polygon using the ground's coordinates:
	love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints()))
	
	-- Print the score:
	love.graphics.setColor(0.76, 0.18, 0.05)
	love.graphics.print(string.format('Cost: $%d.00', cost), window_width/2-50, 50)

	if debug then
		love.graphics.setColor(1, 1, 1)
		-- fps = tostring(love.timer.getFPS())
		-- love.graphics.print("FPS: "..fps, 50, 50)
		love.graphics.print(
			string.format('FPS: %.2f', love.timer.getFPS()), 20, 50
		)
	end
end

function draw_buildings(buildings)
	for _, v in pairs(buildings) do
		if v.is_active then
			love.graphics.setColor(v.color_basic['r'], v.color_basic['g'], v.color_basic['b'])
		else 
			love.graphics.setColor(v.color_destroyed['r'], v.color_destroyed['g'], v.color_destroyed['b'])
		end
		love.graphics.polygon('fill', v.body:getWorldPoints(v.shape:getPoints()))
	end
end

function reload(dt, launchers)
	local is_stock = false
	for _, v in pairs(launchers) do
		-- print(k, v['missiles'])
		if v['can_fire'] then
			is_stock = true
		elseif v['missiles'] > 0 then
			is_stock = true
			v['reload_timer'] = v['reload_timer'] - dt
			if v['reload_timer'] < 0 then
				v['can_fire'] = true
				v['reload_timer'] = 0
			end
		end
	end
	return is_stock
end

function get_distance(x1, y1, x2, y2)
	return (math.abs(x1 - x2)^2 + math.abs(y1 - y2)^2)^(1/2)
end
