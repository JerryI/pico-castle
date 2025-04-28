pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
 
game_running = true

projectiles = {}

levels = {
	[1] = {
		tl = {80, 0},     
		br= {127, 14},


		bgcol = 0,
		dark = 3,

		bgsprites = {
			{40, 3, 2, 32, 32, 0, false, false, true}, --moon
			{44, 3, 2, 32, 48, 0, false, false, true}
		},

		portals = {
			{0,0, 2,14,   2,    -1,0,   true,        30, nil}
		},

		lights = {
			{
				239,
				43,
				true,
				{14, 14, 14},
				{40, 40, 40},
				{64, 63, 52},
				{46, 45, 45}
			},
			{
				240,
				54,
				false,
				{16, 13, 11},
				false
			},
			{
				335,
				43,
				true,
				{14, 14, 14},
				{40, 40, 40},
				{64, 63, 52},
				{46, 45, 45}
			},
			{
				336,
				54,
				false,
				{16, 13, 11},
				false
			}
		}
	},
	[2] = {
		tl = {50, 0},     
		br= {80, 14},

		bgcol = 0,
		dark = 3,

		bgsprites = {
			{40, 3, 2, 32, 32, 0, false, false, true}, --moon
			{44, 3, 2, 32, 48, 0, false, false, true}
		},

		portals = {
			{0,0, 0,14,   3,    -1,0,   true,        50, false},
			{29,0, 31,14,   1,    1,0,   true,        0, nil}
		}
	},
	[3] = {
		tl = {0, 0},     
		br= {50, 18},

		portals = {
			{50,0, 51,14,   2,    1,0,   true,        0, 5}
		},


		bgcol = 0,
		dark = 3,

		bgmap = {
			tl = {0, 19},     
			br= {37, 24},
			dark = 0,
			of = {4,0}
		}
	}		
}

mstash = {}
function stashrestore() 
	for m in all(mstash) do
		mset(m[1], m[2], m[3])
		del(mstash, m)
	end
end

function setLevel(index)
	level = levels[index]
	level.time = 0
	projectiles = {}
	init_torches(level.lights)
	enemy_init()	
end


function add_tree(bgsprites, x, y, s)
	add(bgsprites,{97,2,1,x,y,0,false,false,nil,s,s})
	add(bgsprites,{112,4,1,x-8,y+8,0,false,false,nil,s,s})
	add(bgsprites,{36,4,2,x-8,y+16,0,false,false,nil,s,s})
end




function normalize_bbox(b)
	local x0 = min(b[1], b[3])
	local y0 = min(b[2], b[4])
	local x1 = max(b[1], b[3])
	local y1 = max(b[2], b[4])
	return {x0, y0, x1, y1}
end

function bbox_collide_dir(a, b)
	a = normalize_bbox(a)
	b = normalize_bbox(b)

	if a[3] < b[1] or a[1] > b[3] or a[4] < b[2] or a[2] > b[4] then
		return 0
	end

	local dx1 = a[3] - b[1]
	local dx2 = b[3] - a[1]
	local dy1 = a[4] - b[2]
	local dy2 = b[4] - a[2]

	local min_dx = min(dx1, dx2)
	local min_dy = min(dy1, dy2)

	if min_dx < min_dy then
		return (dx1 < dx2) and 4 or 6
	else
		return (dy1 < dy2) and 8 or 2
	end
end

function angledmap(x, y, width_top, width_bottom, length, angle, offsetx, offsety, sx, sy, layer)
		local rad = angle / 360 * (2 * 3.1476) +   0.05*sin(level.time * 0.0002)
		local dx = cos(rad)
		local dy = sin(rad)
	
		-- calculate the number of steps based on screen-space distance
		local steps = length
		for i = 0, steps do
			local progress = i / steps
			local beam_width = width_top + (width_bottom - width_top) * progress
	
			local px = x + dx * i
			local py = y + dy * i
			local half_w = beam_width / 2
	
			tline(px - half_w, py, px + half_w, py,
				  (px - half_w) / 8 + offsetx, py / 8 + offsety, 0.125, 0, layer)
		end
end

-- circle map function
function circmap(x, y, r, offsetx, offsety, sx, sy, layer)
	if not ( abs(x - cam.x - 64) < 64+32 and abs(y - cam.y - 64) < 64+32) then return end;
	for y2 = -r, r do
		local x2 = sqrt(abs(y2*y2 - r*r))
		tline(x - x2, y + y2, x + x2, y + y2, (x - x2)/8 + offsetx, (y + y2)/8 + offsety, 0.125, 0, layer)
	end
end

function circmapx(x, y, r, offsetx, offsety, sx, sy, layer)
	if not ( abs(x - cam.x - 64) < 64+32 and abs(y - cam.y - 64) < 64+32) then return end;
	for y2 = -r, r, 2 do
		local x2 = sqrt(abs(y2*y2 - r*r))
		tline(x - x2, y + y2, x + x2, y + y2, (x - x2)/8 + offsetx, (y + y2)/8 + offsety, 0.125, 0, layer)
	end
end



function _init()
	--transform all lights
	--for level in all(levels) do for l in all(level.lights) do l.x += level.tl[0]; l.y += level.tl[1] end; end;
	--prepare levels
	for i=0, 9 do
		local x = flr(rnd(10)-4)
		local y = flr(56 + rnd(4)-2)
		add_tree(levels[1].bgsprites,13 * i + x, y,0.2)
		add_tree(levels[2].bgsprites,13 * i + x + 2*128*0.2-2, y,0.2)
	end
	
	for i=0, 9 do
		local x = flr(rnd(24)-12)
		local y = flr(69 + rnd(4)-2)
		add_tree(levels[1].bgsprites,30 * i + x, y,0.4)
		add_tree(levels[2].bgsprites,30 * i + x + 2*128*0.4-5, y,0.4)
	end


	--set level
	setLevel(1)
	-- init_particles(64)
	
	poke(0x5f2d, 0x1)
end


penum = 2.0
tick = 0

cam = {
	offset = {x = 0, y = 0},
	state = 0,
	x = 0,
	y = 0,
	init = false
}

lvl_tr = false
lock_transition = false
lvl_tr_cnt = 9999

function _update()

	if lvl_tr then 
		cam.x += 2*lvl_tr[6];
		cam.y += 2*lvl_tr[7];

		update_ui();
		camera(cam.x + cam.offset.x, cam.y + cam.offset.y)
		

		if lvl_tr_cnt <= 0 then 
			
			stashrestore() 
			setLevel(lvl_tr[5])
			
			lock_transition = true;
			if lvl_tr[9] then 
				plr.x = (level.tl[1]+lvl_tr[9])*8;
			end
			if lvl_tr[10] then 
				plr.y = (level.tl[2]+lvl_tr[10])*8;
			end			
			lvl_tr = false
		end

		lvl_tr_cnt -= 2;
		return
	end

	update_ui();

	if not cam.init then
		cam.x = plr.x - 64
		cam.y = plr.y - 64
		cam.init = true
	end

	update_lights()
	update_torches()
	update_player()

	
	level.time += 1;

	cam.x = plr.x - 64
	cam.y = flr(cam.y * 0.9 - 0.1 * (cam.y - plr.y + 64))

	if cam.x < level.tl[1]*8 then 
		cam.x = level.tl[1]*8
	elseif cam.x > level.br[1]*8 - 128 then 
		cam.x = level.br[1]*8 - 128
	end 

	if cam.y < level.tl[2]*8 then 
		cam.y = level.tl[2]*8
	elseif cam.y > level.br[2]*8 then 
		cam.y = level.br[2]*8
	end 	


	camera(cam.x + cam.offset.x, cam.y + cam.offset.y)

--{0,0, 1,13,   2,    -1,0,   true}
	local transition_possible = false;
	for p in all(level.portals) do
		if p[8] then 
			local int = bbox_collide_dir(player_collizionbox(), {8*(p[1]+level.tl[1]), 8*(p[2]+level.tl[2]), 8*(p[3]+level.tl[1]), 8*(p[4]+level.tl[2])});
			if int != 0 then 
				transition_possible = true;
				if not lock_transition then
					lvl_tr = p;
					lvl_tr_cnt = 128;
				end
			end
		end
	end

	if not transition_possible and lock_transition then 
		lock_transition = false;
	end

	tick += 1



	if game_running then 
		update_projectiles()
	end
end

ui_pts = {}
function draw_ui()
	rectfill(11+1,11,12+plr.life_a,14, 2)

	line(11, 10, 40, 10, 6)

	line(10,10, 10,14, 1)
	line(11,11, 11,14, 1)
	line(40,10, 40,14, 1)

	for p in all(ui_pts) do 
		local c = 8;
		if flr(p[2]) == 10 then c=7 end
		pset(p[1], p[2], c)
	end
	
end

function update_ui() 
	for p in all(ui_pts) do 
		p[2] += rnd(1)-0.5;
		p[1] += rnd(1);
		if p[2] > 14 then p[2] = 14 end 
		if p[2] < 10 then p[2] = 10 end 
		if p[1] > 12+plr.life_a then del(ui_pts, p) end 
	end

	if rnd(10) > 9 then add(ui_pts, {12, 13 + rnd(4)-2 }) end
	plr.life_a = 0.8*plr.life_a + 0.2*(20*plr.life/70.0)
end

function _draw()
	cls(level.bgcol)
	resetpal()


	for s in all(level.bgsprites) do
		if s[9] then
			spr(s[1], s[4] + cam.x, s[5] + cam.y, s[2], s[3], s[7], s[8])
		else
			spr(
				s[1],
				(s[4] + cam.x) + (s[10] or 0) * (level.tl[1]*8 - cam.x),
				(s[5] + cam.y) + (s[11] or 0) * (level.tl[2]*8 - cam.y),
				s[2], s[3], s[7], s[8]
			)
		end
	end




	
	dark(level.dark)


	map(level.tl[1], level.tl[2], level.tl[1]*8, level.tl[2]*8, level.br[1]-level.tl[1], level.br[2]-level.tl[2])
	if lvl_tr then 
		local level = levels[lvl_tr[5]];
		map(level.tl[1], level.tl[2], level.tl[1]*8, level.tl[2]*8, level.br[1]-level.tl[1], level.br[2]-level.tl[2])
		dark(1)
		map(level.tl[1], level.tl[2], level.tl[1]*8, level.tl[2]*8, level.br[1]-level.tl[1], level.br[2]-level.tl[2], 0x10)
	end

		---resetpal()
		--map(level.tl[1], level.tl[2], level.tl[1]*8, level.tl[2]*8, level.br[1]-level.tl[1], level.br[2]-level.tl[2], 0x8)
		dark(1)
		map(level.tl[1], level.tl[2], level.tl[1]*8, level.tl[2]*8, level.br[1]-level.tl[1], level.br[2]-level.tl[2], 0x10)
	

		dark(2)

		for t in all(lights) do
			if t.window then 
				angledmap(t.x, t.y, t.win_top[1], t.win_bottom[1], t.height[1], t.angle[1], 0, 0, 0)
			else
				circmap(t.x, t.y, t.radius[1], 0, 0, 0, 0, 0)
			end
		end

		circmapx(plr.x + 4, plr.y + 4, 15 + penum, 0, 0, 0, 0, 0)

		resetpal()
		dark(1)

		for t in all(lights) do
			if t.window then 
				angledmap(t.x, t.y, t.win_top[2], t.win_bottom[2], t.height[2], t.angle[2], 0, 0, 0)
			else
				circmap(t.x, t.y, t.radius[2], 0, 0, 0, 0, 0)
			end
		end

		resetpal()

		for t in all(lights) do
			if t.window then 
				--.offset.x - background.x / 8.0, background.offset.y - background.y / 8.0, 0, 0, background.layer)
				angledmap(t.x, t.y, t.win_top[3], t.win_bottom[3], t.height[3], t.angle[3], 0, 0, 0)
			else
				--circmap(t.x, t.y, t.radius[3], background.offset.x - background.x / 8.0, background.offset.y - background.y / 8.0, 0, 0, background.layer)
				local s = level.bgmap; 
				if s then		
					--dark(s.dark)
					
					circmap(t.x, t.y, t.radius[3], s.tl[1]+s.of[1] - 0.2*cam.x/8.0, s.tl[2]+s.of[2] - 0.8*cam.y/8.0 - (s.br[2]-s.tl[2]),0,0)
					circmap(t.x, t.y, t.radius[3], s.tl[1]+s.of[1] - 0.2*cam.x/8.0, s.tl[2]+s.of[2] - 0.8*cam.y/8.0,0,0)
				end				
				circmap(t.x, t.y, t.radius[3], 0, 0, 0, 0, 0)
			end
		end

	draw_torches()

	dark(1)

	draw_projectiles()
	
	dark(1)
	
	draw_player()

	-- show stats
	camera() -- reset camera for ui
	--print("fps: "..stat(7), 90, 1, 7)
	--print("cpu: "..flr(stat(1) * 100).."%", 90, 9, 7)

	draw_ui()

	if tick <= 50 then print("Z jump", 64, 32, 14) end
	if tick <= 60 then print("X sword", 64, 40, 14) end
	if tick <= 70 then print("A shield", 64, 48, 14) end
end
-->8

-->8
time = 0

dpal = {0,1,1,2,1,13,6,2,4,9,3,13,5,2,9}

function resetpal()
	pal()
	palt(0, false)
	palt(14, true)
end

-- function to darken the palette
function dark(l)
	l = l or 0
	if l > 0 then
		for i = 0, 15 do
			local col = dpal[i] or 0
			for a = 1, l - 0.5 do
				col = dpal[col]
			end
			pal(i, col)
		end
	end
end

-- progressive green-tint palette map
gpal = {
	-- step 1
	[0] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
	-- step 2
	[1] = {0,11,3,3,3,11,11,3,3,3,11,11,3,3,3,3},
	-- step 3 (closer to final green)
	--[2] = {11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11}
}

function tint_green(level)
	level = mid(0, level, 3) -- clamp between 0 and 3
	for i = 0, 15 do
		local col = gpal[level][i] or i
		pal(i, col)
	end
end

-- progressive red-tint palette map
rpal = {
	-- step 0: original palette
	[0] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
	-- step 1: mid tint toward reddish hues
	[1] = {1,1,2,4,4,8,8,9,9,8,8,4,8,8,8,8},
	-- step 2: stronger red tint
	--[2] = {8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8}
}

function tint_red(level)
	level = mid(0, level, 2) -- clamp between 0 and 2
	for i = 0, 15 do
		local col = rpal[level][i] or i
		pal(i, col)
	end
end

function init_torches(init)
	particles = {}
	lights = {};
	for l in all(init) do 
		if l[3] == false then
			add(lights, {x=l[1]+level.tl[1]*8, y=l[2]+level.tl[2]*8, radius=l[4],_radius=l[4],flicker=l[5]})
		else
			add(lights, {x=l[1]+level.tl[1]*8, y=l[2]+level.tl[2]*8, window=true, win_top=l[4], win_bottom=l[5], height=l[6], angle=l[7]})
		end
	end

	for i = level.tl[1], level.br[1] do
		for j = level.tl[2], level.br[2] do
			local l = mget(i, j)

			if l == 91 or l == 75 then
				local light = {
					x = i * 8 + 5,
					y = j * 8 + 4,
					radius = {20, 15, 10},
					_radius = {20, 15, 10},
					flicker = true
				};

				add(lights, light)

				create_projectile(4, {
					x = i * 8 + 5,
					y = j * 8 + 4,
					mx = i*8,
					my = j*8,
					spr = 91,
					light = light
				});
				
				if l == 75 then
				
					mset(i, j, mget(i,j+1))
					add(mstash, {i,j,75});
				
				else
					add(mstash, {i,j,91});
					mset(i, j, mget(i,j+1))

				end

			elseif l == 92 then
				local light = {
					x = i * 8 + 2,
					y = j * 8 + 4,
					radius = {20, 15, 10},
					_radius = {20, 15, 10},
					flicker = true
				};

				add(lights, light)

				create_projectile(4, {
					x = i * 8 + 2,
					y = j * 8 + 4,
					mx = i*8,
					my = j*8,
					spr = 92,
					light = light
				})

				mset(i, j, mget(i,j+1))
				add(mstash, {i,j,92});
			elseif l == 221 then
				create_projectile(5, {
					x = i * 8 + 2,
					y = j * 8 + 4
				})
				
				mset(i, j, mget(i+1,j))
				add(mstash, {i,j,221});
			end

			if fget(l, 5) then
				add(lights, {
					x = i * 8 + 4,
					y = j * 8 + 4,
					radius = {20, 15, 10},
					_radius = {20, 15, 10},
					flicker = true
				})
			end

			if l == 23 then
				add(lights, {
					x = i * 8 + 4,
					y = j * 8 + 4,
					window = true,
					win_top = {10,10,10},
					win_bottom = {60,50,40},
					height = {64,63,62},
					angle = {45,45,45}
				})
			end

			if l == 7 then
				add(lights, {
					x = i * 8 + 4,
					y = j * 8 + 4,
					window = true,
					win_top = {10,10,10},
					win_bottom = {60,50,40},
					height = {64,63,52},
					angle = {45,45,45}
				})
			end

			if l == 22 then 
				plr.x = i * 8;
				plr.y = j * 8;
				mset(i,j, mget(i+1,j))
				add(mstash, {i,j,22});
			end
		end
	end
end

lights_tick = 0

function update_lights()
	lights_tick += 1

	if lights_tick % 3 == 0 then
		for t in all(lights) do
			if t.flicker then
				t.radius = {
					t._radius[1] + rnd(3) + 1,
					t._radius[2] + rnd(3),
					t._radius[3] + rnd(3) + 1
				}
			end
		end
	end
end

function update_torches()
	time += 0.01
	wind = 0.1 * sin(time * cos(0.1 * time))

	for p in all(particles) do
		p.l -= 1
		p.y -= 0.7 - p.vy

		if p.l < 6 then
			p.x += p.vx
			p.r += 0.04
		end

		p.vx *= 1.1

		if p.l < 10 then p.c = 8 end
		if p.l < 8  then p.c = 9 end
		if p.l < 3  then p.c = 15 end
		if p.l < 1  then p.c = 0 end

		if p.l < 0 then
			del(particles, p)
		end
	end
end

function draw_torches()
	for i in all(particles) do
		rectfill(i.x - i.r, i.y - i.r, i.x + i.r, i.y + i.r, i.c)
	end
end
-->8
-- plr states
idle = 0
walk = 1
attack = 2
spell = 3
hit = 4
shield = 5
death = 6
stairs = 7


-- change plr state and reset animation
function set_animation(state)
    if plr.state != state then
        plr.state = state
        plr.anim_frame = 0
        plr.anim_timer = 0
    end
end

function can_move_x(delta)
    local test_x = plr.x + delta
    local box = player_collizionbox()

    -- shift the box by delta
    box[1] += delta
    box[3] += delta

    return not (
        solid(box[1], box[2]) or solid(box[1], box[4]-1) or
        solid(box[3]-1, box[2]) or solid(box[3]-1, box[4]-1)
    )
end

-- plr damage
function _player_damage(box, dmg)
    if plr.invinsible > 0 then return 0 end
    
    local pbox = player_shieldbox();
    
    if pbox then
    	local dir = bbox_collide_dir(pbox, box)
    
    	if dir == 4 then
    		if can_move_x(-2) then
                plr.x += -2
            end
    		plr.blocked = true
    		set_animation(hit);
    		plr.invinsible = 10;
			sfx(3)
    		
    		
    		return 2;
    		
    	elseif dir == 6 then
    		if can_move_x(2) then
                plr.x += 2
            end
    		plr.blocked = true
    		set_animation(hit) 
    			
    		plr.invinsible = 10;
			sfx(3)
    		
    		
    		return 2; 
    		  	
    	end
    	
    	
    	 	
    end
    
    --fuck()
    
    pbox = player_hitbox()
    
    local dir = bbox_collide_dir(pbox, box);
    
    if dir == 4 then
        if can_move_x(-2) then
            plr.x -= 2
        end
    		plr.blocked = true
    		set_animation(hit);
    		plr.tint_red = true;
    		plr.invinsible = 10;
    		plr.life -= abs(dmg);
			sfx(2)
    		
    		return 1;
    elseif dir == 6 then
        if can_move_x(2) then
            plr.x += 2
        end
    		plr.blocked = true
    		set_animation(hit);
    		plr.tint_red = true;
    		plr.invinsible = 10;
    		plr.life -= abs(dmg);
			sfx(2)
    		
    		return 1;
    end 
    
    return 0
    
end

function player_collizionbox() 
    local box;
                        
                        if plr.dir > 0 then	
                             box = {plr.x+4, plr.y+1, plr.x + 10, plr.y + 14};
                        else
                             box = {plr.x+5, plr.y+1, plr.x + 11, plr.y + 14};
                        end
                        return box;
    end

function player_hitbox() 
local box;
					
					if plr.dir > 0 then	
						 box = {plr.x+2, plr.y+1, plr.x + 11, plr.y + 15};
					else
						 box = {plr.x+4, plr.y+1, plr.x + 13, plr.y + 15};
					end
					return box;
end

function player_swordbox() 
local box;
					
					if plr.dir > 0 then	
						 box = {plr.x+15, plr.y+3, plr.x + 23, plr.y + 14};
					else
						 box = {plr.x+1, plr.y+3, plr.x - 8, plr.y + 14};
					end
					return box;
end

function player_shieldbox() 
if plr.state != shield then return false end;
local frames = plr.animations[plr.state].frames;
--print(plr.animations[plr.state].frames)

if plr.anim_frame+1 < #frames then return false; end;



local box;
					
if plr.dir > 0 then	
	box = {plr.x+8, plr.y, plr.x + 16, plr.y + 14};
else
	box = {plr.x+7, plr.y, plr.x - 1, plr.y + 14};
end
					
					return box;
end

-- plr object
plr = {
    x = 104,
    y = 2 ,
    hitbox = {0, 0, 1,1},
    dx = 0, dy = 0,
    life = 20,
	life_a = 0,
    stair_dx = 0,
    stair_dy = 0,
    stair_grace = 0,
    blocked = false,
    w = 10, h = 16,
    invinsible = 0,
    dash_cool = 0,
    on_ground = false,
    spd = 1.2,
    jmp = -4.601,
    dir = 1,
    state = idle,
    spell = 0,
    anim_timer = 0,
    anim_frame = 0,

    animations = {
        [idle] = {
            speed = 0,
            loop = true,
            frames = {
                {tl=228, tr=229, bl=244, br=245}
            }
        },
        [walk] = {
            speed = 0.2,
            loop = true,
            frames = {
                {tl=230, tr=231, bl=246, br=247},
                {tl=232, tr=233, bl=248, br=249},
                {tl=228, tr=229, bl=244, br=245}
            }
        },
        [attack] = {
            speed = 0.2,
            loop = false,
            frames = {
                {tl=234, tr=235, bl=250, br=251},
                {tl=236, tr=237, bl=252, br=253, ox=16, oy=8, overlay=254}
            }
        },
        [spell] = {
            speed = 0.2,
            loop = false,
            frames = {
                --{tl=230, tr=231, bl=246, br=247},
                {tl=234, tr=235, bl=250, br=251},
                {tl=236, tr=239, bl=252, br=255}
            }
        },
        
                
        [hit] = {
            speed = 0.3,
            loop = false,
            frames = {
                {tl=234, tr=235, bl=250, br=251}
            }
        },
        
        [shield] = {
            speed = 0.2,
            loop = false,
            frames = {
                {tl=232, tr=233, bl=248, br=249},
                {tl=226, tr=227, bl=242, br=243}
            }
        },
        
        [death] = {
        				speed = 0.1,
        				loop = false,
        				frames = {
        								{tl=232, tr=233, bl=248, br=249},
        								{tl=234, tr=235, bl=250, br=251},
        								{tl=198, tr=199, bl=214, br=215}
        								
        				}
        },
        [stairs] = {
            speed = 0.15,
            loop = true,
            frames = {
                {tl=228, tr=229, bl=244, br=245} -- reuse idle
            }
        },        
        
    },

    damage = _player_damage
}


function solid(x, y)
    local tile = mget(flr(x / 8), flr(y / 8))
    return fget(tile, 0)
end

function spikesq(x, y)
	local s = mget(flr(x / 8), flr(y / 8))
    return s == 204 or s == 14
end



function update_animation()
    local anim = plr.animations[plr.state] or plr.animations[idle]
    plr.anim_timer += anim.speed

    if anim.speed > 0 and plr.anim_timer >= 1 then
        plr.anim_timer = 0
        plr.anim_frame += 1

        if plr.anim_frame >= #anim.frames then
            if anim.loop then
                plr.anim_frame = 0
            else
                plr.anim_frame = #anim.frames - 1

                -- one-shot animations end
                if plr.state == attack or plr.state == hit then
                    set_animation(idle)
                end

				if plr.state == death then 
					extcmd('reset')
				end
                
                -- spell ends in spell logic
                plr.tint_green = false
            	plr.tint_red = false
            end
        end
    end
end

debug_hitbox = false


function update_player()
    local moving = false

				-- cooldown after damage or shield
				if plr.invinsible > 0 then
					plr.invinsible -= 1
				end
				
				
				-- ⬇️eath and aimation
				if not game_running then
					update_animation()	
					return
				end
				
				if plr.life < 0 then
					game_running = false
					plr.tint_red = true
					set_animation(death)
					
					return
				end


    -- movement
    if not plr.blocked and (plr.state != shield or (plr.state == shield and plr.anim_frame + 2 > #plr.animations[shield].frames)) then
    
    			local spd = plr.spd;
    			if plr.state == shield then
            spd = spd / 3.0;
       end
    
        if btn(0) then
            plr.dir = -1
            
            	plr.dx = -spd

            moving = true
        elseif btn(1) then
            plr.dir = 1
            plr.dx = spd
            moving = true
        else
            plr.dx = 0
        end
    end

    -- set walking/idle
    if not plr.blocked and plr.state != shield and plr.state != attack and plr.state != spell then
        if moving then
            set_animation(walk)
        else
            set_animation(idle)
        end
    end

    -- jump
    if btn(4) and not plr.blocked and plr.on_ground then
        plr.dy = plr.jmp
		sfx(1)
        plr.on_ground = false
    end

-- spell (btnp(5, 1))
if btnp(5, 0) and btn(2) and not plr.blocked and plr.state != attack and plr.state != spell then
    set_animation(spell)
	sfx(6)
    plr.spell = 0
end


-- shield
if not plr.blocked and plr.state != attack and plr.state != spell and plr.on_ground then
    if btn(5,1) and plr.state != shield then 
    	set_animation(shield)
    	plr.spell = 0
    	
    	 
    elseif not btn(5,1) and plr.state == shield then
    	set_animation(idle)
   
    end
end


-- attack (btnp(5, 0))
if btnp(5, 0) and not plr.blocked and plr.state != attack and plr.state != spell then
    set_animation(attack)
	sfx(5)
end

				-- attack someone
				if plr.state == attack and plr.anim_frame > 0 then
					local hitbox = player_swordbox()
					
					debug_hitbox = hitbox;
					if collide_projectiles(hitbox, -10) then
						
						add(particles, {
	  				x = (hitbox[1]+hitbox[3])/2.0 + rnd(4)-2,
	  				y = (hitbox[2]+hitbox[4])/2.0 + rnd(4)-2,
	  				vx = rnd(4)-2,
	  				vy = 0,
	  				c = 12,
	  				l = (8+rnd(3)),
	  				//rnd = {rnd(3), rnd(3), rnd(3)},
	  				r = 0
	  			});

			else 
				
			end
					
					else
						
						debug_hitbox = false
				end
				
				-- invinsible
				if plr.blocked and plr.state == idle then
						plr.blocked = false
				end
				


    -- gravity
if plr.state != stairs then
    plr.dy += 0.35
    if plr.dy > 3 then plr.dy = 3 end
end

    -- horizontal
    local next_x = plr.x + plr.dx
    plr.x = next_x
    local box = player_collizionbox()
    
    -- if collision at next position, cancel movement
    if plr.dx != 0 and (
        solid(box[1], box[2]) or solid(box[1], box[4]-1) or
        solid(box[3]-1, box[2]) or solid(box[3]-1, box[4]-1)
    ) then
        plr.x -= plr.dx
        plr.dx = 0
    end

    --- spikes
    if spikesq(box[1], box[2]) or spikesq(box[1], box[4]-1) then
        plr.damage(player_collizionbox(), -1000)
    end

-- vertical
local next_y = plr.y + plr.dy
plr.y = next_y
local box = player_collizionbox()
debug_collizions = box;

if plr.dy > 0 then
    local ground_check_y = box[4] + 1  -- check 1 pixel below
    if solid(box[1], ground_check_y) or solid(box[3]-1, ground_check_y) then
        plr.y -= plr.dy
        plr.dy = 0
        plr.on_ground = true
        plr.dash_cool -= 1
    else
        plr.on_ground = false
    end
elseif plr.dy < 0 then
    if solid(box[1], box[2]) or solid(box[3]-1, box[2]) then
        plr.y -= plr.dy
        plr.dy = 0
    end
end

    -- spell behavior
    if plr.state == spell then
        plr.spell += 0.2
        if plr.spell > 2 then 
        	plr.tint_green = true
        end;
        if plr.spell > 5 then
            create_projectile(1, {
                x = plr.x + 6,
                y = plr.y + 7,
                dir = plr.dir * 3.0
            })
            plr.spell = 0
            plr.tint_green = false;
            set_animation(idle)
        end
    end
			
    update_animation()
end


function draw_player()
    dark(1)

    local anim = plr.animations[plr.state] or plr.animations[idle]
    local frame_index = min(plr.anim_frame + 1, #anim.frames)
    local frame = anim.frames[frame_index] or anim.frames[1]
    local flip = plr.dir < 0
    local x = plr.x
    local y = plr.y

    -- decide left/right draw order
    local x1 = flip and x + 8 or x       -- "left" sprite
    local x2 = flip and x     or x + 8   -- "right" sprite

				if plr.tint_green then
					tint_green(1);
				end
				
				if plr.tint_red then
					tint_red(1);
				end

    -- draw parts with mirrored positions
    spr(frame.tl, x1, y,     1, 1, flip)
    spr(frame.tr, x2, y,     1, 1, flip)
    spr(frame.bl, x1, y + 8, 1, 1, flip)
    spr(frame.br, x2, y + 8, 1, 1, flip)

    -- optional overlay (e.g., sword)
    -- optional overlay (e.g., sword, glow)
    if frame.overlay then

local ox = frame.ox or 0
local oy = frame.oy or 0

-- if flipped, mirror offset across center (e.g. 8 - ox)
local overlay_x = flip and (x + 8 - ox) or (x + ox)
local overlay_y = y + oy

spr(frame.overlay, overlay_x, overlay_y, 1, 1, flip)

			 end


    resetpal()

    -- spell visual
    if plr.state == spell then
        local shift = flip and 4 or 12
        circ(x + shift, y + 7, 4.0 / (plr.spell+0.2), 11)
        circ(x + shift, y + 7, plr.spell, 11)
    end
end
-->8


-- initialize all enemies from the map
function enemy_init()
	--for i in all(projectiles) do del(projectiles, i) end;

	for i = level.tl[1], level.br[1] do
		for j = level.tl[2], level.br[2] do
			local l = mget(i, j)
			if l == 192 then
			
				local spot = {
					x = i * 8 + 5,
					y = j * 8 + 4,
					radius = {14, 12, 5},
					_radius = {18, 12, 7},
				};
				
				add(lights, spot);
				
				create_projectile(2, {
					x = i * 8 + 5,
					y = j * 8 + 4,
					light = spot
				})
				mset(i, j, mget(i+1,j))
				add(mstash, {i,j,192});
			end
			if l == 196 then
				create_projectile(3, {
					x = i * 8,
					y = j * 8
				})
				mset(i, j, mget(i+1,j))
				add(mstash, {i,j,196});
			end

			if l == 203 then
				create_projectile(6, {
					x = i * 8,
					y = j * 8
				})
				mset(i, j, mget(i+1,j))
				add(mstash, {i,j,203});
			end

			if l == 219 then
				create_projectile(6, {
					x = i * 8,
					y = j * 8,
					flipped = true
				})
				mset(i, j, mget(i+1,j))
				add(mstash, {i,j,219});
			end
		end
	end
end

-- enemy: crawler
function _enemy_crawler_init(data)
	local y = data.y
	local ceiling = false

	if solid(data.x, data.y + 8) then
		-- solid below: it's a ground crawler
		y = data.y
	elseif solid(data.x, data.y - 8) then
		-- solid above: it's a ceiling crawler
		y = data.y
		ceiling = true
	end

	return {
		x = data.x,
		y = y,
		dir = 1,
		light = data.light,
		life = 80,
		alive = true,
		damagable = true,
		hitbox = { data.x-8, y-8, data.x+8, y+16 },
		damage = _enemy_crawler_kill,
		index = 1,
		tick = 1,
		frames = { 192, 194, 224 },
		ceiling = ceiling
	}
end

function _enemy_crawler_kill(b, box, dm)
	local dir = bbox_collide_dir(b.hitbox, box)
	if dir != 0 then
		b.life -= abs(dm)
		
		if dir == 6 then
			b.x += 6;
		else
			b.x -= 6;
		end
		
		return true
	end
	return false
end

function _enemy_crawler_update(s)
	s.tick += 1

	-- set hitbox based on mode
	if s.ceiling then
		s.hitbox = { s.x - 8, s.y - 2, s.x + 4, s.y + 4 }
	else
		s.hitbox = { s.x - 8, s.y + 2, s.x + 4, s.y + 9 }
	end

	local collided = plr.damage(s.hitbox, -10)

	-- === falling logic ===
	if s.falling then
		s.y += 4

		-- check if we hit ground
		if solid(s.x, s.y + 16) then
			s.falling = false
			s.ceiling = false
			s.dir = s.dir;
			s.y = flr((s.y +8) / 8) * 8 - 4  -- align nicely with floor
		end

		s.light.x = s.x
		s.light.y = s.y
		return true
	end

	-- trigger fall if near plr and currently on ceiling
	local dist_x = abs(s.x - (plr.x + 8))
	if s.ceiling and dist_x < 12 then
		s.falling = true
		return true
	end

	-- === normal crawling logic ===

	-- surface check
	local surface_y = s.ceiling and s.y - 8 or s.y + 16
	local on_surface = solid(s.x, surface_y)

	-- ledge check
	local next_x = s.x + s.dir * 8
	local next_y = s.ceiling and s.y - 8 or s.y + 16
	local next_yp = s.ceiling and s.y    or s.y + 9
	local ledge_ahead = solid(next_x, next_y)

	-- turn around if off surface or at ledge or hit plr
	if not on_surface or not ledge_ahead or collided != 0 or solid(next_x, next_yp) then
		s.dir = -s.dir

        if collided != 0 then
			if plr.x > s.x then
				s.dir = 1;
			else
				s.dir = -1;
			end

            s.x -= s.dir * 5
            if collided == 2 then
                s.x -= s.dir * 10
            end
        end

	else
		if flr(rnd(5)) == 2 and abs(plr.x - s.x) < 32 and abs(plr.y - s.y) < 16 then
			if plr.x > s.x then
				s.dir = 1;
			else
				s.dir = -1;
			end
		end
	end

	-- move horizontally
	s.x += s.dir

	-- update light
	s.light.x = s.x
	s.light.y = s.y

	-- animation timing
	if (s.tick % 4 != 0) then return true end
	s.index += 1
	if s.index == 4 then s.index = 1 end

	-- light cleanup if dead
	if s.light and s.life <= 0 then
		sfx(4)
		del(lights, s.light)
		s.light = false
		for i=1,16 do
			add(particles, {
	  				x =  (s.hitbox[1]+s.hitbox[3])/2.0 + rnd(abs(s.hitbox[1]-s.hitbox[3])/2.0)-(abs(s.hitbox[2]-s.hitbox[4]))/4.0,
	  				y =  (s.hitbox[2]+s.hitbox[4])/2.0 + 8 + rnd(abs(s.hitbox[2]-s.hitbox[4])/2.0)-(abs(s.hitbox[2]-s.hitbox[4]))/4.0,
	  				vx = rnd(4)-2,
	  				vy = 0,
	  				c = 12,
	  				l = (8+rnd(3)),
	  				//rnd = {rnd(3), rnd(3), rnd(3)},
	  				r = 0
	  		})
		end
	end

	

	return s.life > 0
end

function _enemy_crawler_draw(s)
	dark(1)

	local vflip = s.ceiling and true or false
	spr(s.frames[s.index], s.x - 8, s.y - 4, 2, 2, s.dir < 0, vflip)
end

-- projectile: plr spell
function _p_spell_init(data)
	return {
		x = data.x,
		y = data.y,
		vx = data.dir,
		dir = data.dir,
		dashed = false,
		sr = 4,
		br = 7,
		index = 0,
		state = 0,
		tint = 1,
		vy = 0
	}
end

function _p_spell_update(s)
	if s.state <= 0 then
		s.x += s.vx
		s.y += s.vy
	end

	s.index += 1
	if s.index > 2 then s.index = 0 end

	local cd = collide_projectiles({ s.x, s.y, s.x + 4, s.y + 3 }, -90)

	if s.dashed then
		s.state += 1
	end

	if solid(s.x, s.y) or cd then
		s.state += 1
		s.dashed = true
	end

	if s.state > 1 then
		s.index = 0
		add(particles, {
			x = s.x,
			y = s.y + 1,
			vx = 0,
			vy = -(rnd(2) - 1) / 5.0,
			c = 12,
			l = 8 + rnd(3),
			r = 0
		})
	end

	if s.state == 1 then
		s.br += 4
		s.sr += 4
	elseif s.state == 5 then
		s.br = 3
		s.sr = 3
	elseif s.state > 9 then
		return false
	end

	return true
end

function _p_spell_draw(s)
		resetpal()
		--circmapx(s.x, s.y, s.sr, background.offset.x - background.x / 8.0, background.offset.y - background.y / 8.0, 0, 0, background.layer)
		tint_green(s.tint)
		circmap(s.x, s.y, s.br, 0, 0, 0, 0)

	spr(205 + s.index, s.x - 4, s.y - 4, 1, 1, s.dir < 0)
end




-- projectile: enemy spell
function _enemy_spell_init(data)
	return {
		x = data.x,
		y = data.y,
		vx = data.dir,
		dir = data.dir,
		dashed = false,
		sr = 4,
		br = 7,
		damagable = true,
		alive = true,
		damage = _enemy_spell_kill,
		index = 0,
		state = 0,
		tint = 1,
		vy = 0
	}
end



function _enemy_spell_kill(e, box, dm) 
	if not e.hitbox then return false end;
	if bbox_collide_dir(e.hitbox, box) != 0 then
		if e.dashed then return false end;
		e.state += 1
		e.dashed = true
		return true
	end
	return false
end

function _enemy_spell_update(s)
	if s.state <= 0 then
		s.x += s.vx
		s.y += s.vy
	end

	s.index += 1
	if s.index > 2 then s.index = 0 end

	s.hitbox = { s.x, s.y, s.x + 4, s.y + 3 };
	local cd = plr.damage(s.hitbox, -10)



	if s.dashed then
		s.state += 1
	end

	if solid(s.x, s.y) or cd != 0 then
		s.state += 1
		s.dashed = true
	end

	if s.state > 1 then
		s.index = 0
		add(particles, {
			x = s.x,
			y = s.y + 1,
			vx = 0,
			vy = -(rnd(2) - 1) / 5.0,
			c = 12,
			l = 8 + rnd(3),
			r = 0
		})
	end

	if s.state == 1 then
		s.br += 4
		s.sr += 4
	elseif s.state == 5 then
		s.br = 3
		s.sr = 3
	elseif s.state > 9 then
		return false
	end

	return true
end

function _enemy_spell_draw(s)
		resetpal()
		--circmapx(s.x, s.y, s.sr, background.offset.x - background.x / 8.0, background.offset.y - background.y / 8.0, 0, 0, background.layer)
		tint_red(s.tint)
		circmap(s.x, s.y, s.br, 0, 0, 0, 0)

	spr(205 + s.index, s.x - 4, s.y - 4, 1, 1, s.dir < 0)
end

--heart
function _heart_init(data)

	return {
		x = data.x,
		y = data.y-8,
		tick = 1,
		frames = {221, 222, 223},
		index = 1
	}
end

function _heart_update(s)

	if s.absorb then 
		plr.tint_green = false;
		return false; 
	end

	if bbox_collide_dir(player_collizionbox(), {s.x+2, s.y+2, s.x+6, s.y+6}) != 0 then 
		plr.tint_green = true;
		plr.life += 30;
		sfx(0)
		s.absorb = true;
		return true;
	end

	s.tick += 1
	if s.tick % 6 != 0 then return true; end

	s.index += 1;
	if s.index > 3 then
		s.index = 1;
	end

	return true
end

function _heart_draw(s)
		resetpal()
		--circmapx(s.x+4, s.y+8, 5, background.offset.x - background.x / 8.0, background.offset.y - background.y / 8.0, 0, 0, background.layer)
		dark(2)
		circmap(s.x+4, s.y+8, 8, 0, 0, 0, 0)
		resetpal()
		circmap(s.x+4, s.y+8, 6, 0, 0, 0, 0)

	spr(s.frames[s.index], s.x, s.y, 1, 1)
end

-- torch
function _torch_init(data)
	
	return {
		x = data.x,
		y = data.y, 
		mx = data.mx,
		my = data.my,
		spr = data.spr,
		alive = true,
		light = data.light,
		damagable = true,
		damage = _torch_kill,
		falling = false
	}
end

function _torch_kill(b, box, dm)
	
	if b.falling then return false end;
	local dir = bbox_collide_dir({b.x-1, b.y-1, b.x + 1, b.y + 2}, box)
	if dir != 0 then
		b.falling = true
		sfx(7)
		return false
	end
	return false
end

function _torch_update(t)
	
	add(particles, {
		x = t.x,
		y = t.y,
		vx = (rnd(2) - 1) / 5.0 + wind,
		vy = (rnd(2) - 1) / 5.0,
		c = 12,
		l = 8 + rnd(3),
		r = 0
	});

	if t.falling then
		if solid(t.x, t.y) then

			del(lights, t.light)
			sfx(8)
			for i=1,10 do
				add(particles, {
						  x =  t.x + rnd(6)-3,
						  y =  t.y + rnd(6)-3,
						  vx = rnd(3)-1.5,
						  vy = 0,
						  c = 12,
						  l = (8+rnd(3)),
						  //rnd = {rnd(3), rnd(3), rnd(3)},
						  r = 0
				  })
			end

			if flr(rnd(6)) == 1 then 
				create_projectile(5, {
					x = t.x,
					y = t.y
				})
			end


			return false
		else
			t.y += 3;
			t.light.y += 3;
		end

	end

	return true;
end

function _torch_draw(t)
	resetpal()
	spr(t.spr, t.mx, t.my)
end

-- head: 

function _enemy_head_init(data)
	local hitbox;
	if data.flipped then 
		hitbox = {data.x+3, data.y+3, data.x + 14, data.y + 13}
	else 
		hitbox = {data.x+3, data.y+3, data.x + 14, data.y + 13}
	end 

	return {
		x = data.x,
		y = data.y,
		flipped = data.flipped,
		state = 1,
		frames = {202, 200, 220},
		frame = 202,
		overlay = false,
		alive = true,
		damagable = true,
		damage = _enemy_head_kill,
		hitbox = hitbox,
		tick = 0,
		dark = 1,
		life = 385
	}
end

function _enemy_head_kill(e, box, dm) 
	if bbox_collide_dir(e.hitbox, box) != 0 then
		e.life -= abs(dm)
		if e.life <= 0 then sfx(4); end
		return true
	end

	return false
end

function _enemy_head_update(s)
	s.tick += 1;

	-- attack plr
	plr.damage(s.hitbox, -10)

	if s.tick == 1 then 
		s.frame = s.frames[2]
	elseif s.tick == 1+20 then 
		s.overlay = s.frames[3]
	end 

	if s.tick > 1+20 then 
		s.dark = s.tick % 2 == 0;

		if s.tick > 1+40+20 and s.tick % 20 == 0 then
			local offset = 4;
			local dir = -2;
			if s.flipped then 
				offset = 10;
				dir = 2;
			end
			sfx(8)
			create_projectile(7, {
				dir = dir,
				vx = 3,
				vy = 0,
				x = s.x + offset,
				y = s.y + 8
			})
		end
	end

	if s.tick > 140 or abs(cam.x - s.x + 64) > 68 or abs(cam.y - s.y + 64) > 48 then 
		s.tick = 0
		s.dark = true
		s.frame = s.frames[1]
		s.overlay = false
	end

	if s.life <= 0 then 
		
		for i=1,16 do
			add(particles, {
	  				x =  (s.hitbox[1]+s.hitbox[3])/2.0 + rnd(abs(s.hitbox[1]-s.hitbox[3])/2.0)-(abs(s.hitbox[2]-s.hitbox[4]))/4.0,
	  				y =  (s.hitbox[2]+s.hitbox[4])/2.0 + 8 + rnd(abs(s.hitbox[2]-s.hitbox[4])/2.0)-(abs(s.hitbox[2]-s.hitbox[4]))/4.0,
	  				vx = rnd(4)-2,
	  				vy = 0,
	  				c = 12,
	  				l = (8+rnd(3)),
	  				//rnd = {rnd(3), rnd(3), rnd(3)},
	  				r = 0
	  		})
		end
		
		return false
	end

	return true
end

function _enemy_head_draw(s)

	if s.dark then dark(1) else
		dark(1)
		if s.flipped then 
			circmap(s.x+7, s.y+8, 12, 0, 0, 0, 0)
		else 
			circmap(s.x+4, s.y+8, 12, 0, 0, 0, 0)
		end
		resetpal()
	end
	spr(s.frame, s.x, s.y, 2,2, s.flipped)
	if s.overlay then 
		if s.flipped then 
			spr(s.overlay, s.x , s.y, 1,1, true)
		else
			spr(s.overlay, s.x + 8, s.y)
		end
		
	end
end

-- seeker enemy: sleeps until plr is close, then homes in
function _enemy_seeker_init(data)
	return {
		x = data.x,
		y = data.y,
		vx = 0,
		vy = 0,
		awake = false,
		frame_index = 1,
		frames = {196, 197, 212},
		life = 3,
		alive = true,
		damagable = true,
		hitbox = {data.x - 6, data.y - 6, data.x + 6, data.y + 6},
		damage = _enemy_seeker_kill,
		index = 1,
		tick = 0,
		frame = 196
	}
end

function _enemy_seeker_kill(e, box, dm)
	if bbox_collide_dir(e.hitbox, box) != 0 then
		e.life -= abs(dm)
		return true
	end
	return false
end

function _enemy_seeker_update(e)
	e.tick += 1
	
	if e.tick % 3 == 0 and e.awake then
		e.frame_index += 1;
		if e.frame_index > 3 then
			e.frame_index = 1
		end
	end

	local px = (plr.x + 8)
	local py = (plr.y + 9) 

	local dx = px - e.x
	local dy = py - e.y
	local dist = sqrt(dx*dx + dy*dy)

	if not e.awake and dist < 54 and abs(dx) < 54 and abs(dy) < 54 then
		e.awake = true
	end
	
	if not e.awake then return true; end

	if e.awake then
		-- normalize and apply gravity-like acceleration
		local acc = 0.2
		local d = max(dist, 1)
		e.vx += acc * dx / d
		e.vy += acc * dy / d

		-- friction or drag
		e.vx *= 0.84
		e.vy *= 0.84

		e.x += e.vx
		e.y += e.vy
	end

	-- update hitbox
	e.hitbox = {e.x - 7, e.y - 7, e.x-1 , e.y-1 }

	-- check collision with plr
	local collided = plr.damage(e.hitbox, -10)
	if collided != 0 then
		e.vx = -e.vx
		e.vy = -e.vy
        
        e.vx *= 2.0;
        e.vy *= 2.0;

        if collided == 2 then
            e.vx *= 4.0;
            e.vy *= 4.0;
        end
	end

	--if not (e.life > 0) then sfx(4) end

	return e.life > 0
end

function _enemy_seeker_draw(e)
	

	if e.awake then
		dark(1)
	else
		dark(2)
	end
	
	spr(e.frames[e.frame_index], e.x - 8, e.y - 8, 1, 1, e.vx < 0)

end



-- collision check against all active projectiles
function collide_projectiles(hitbox, dm)
	local state = false
	for s in all(projectiles) do
		if abs(s.x - cam.x - 64) < 64+32 and abs(s.y - cam.y - 64) < 64+32 then
			if s.alive and s.damagable and s.damage(s, hitbox, dm) then
				state = true
			end
		end
	end
	return state
end

-- public interface (unchanged)
function create_projectile(id, data)
	local ty = _p_types[id]
	local p = ty.init(data)
	p.method = ty
	add(projectiles, p)
end

function update_projectiles()
	for p in all(projectiles) do
		if abs(p.x - cam.x - 64) < 64+32 and abs(p.y - cam.y - 64) < 64+32 then
			if not p.method.update(p) then
				del(projectiles, p)
			end
		end
	end
end

function draw_projectiles()
	for p in all(projectiles) do
		if abs(p.x - cam.x - 64) < 64+32 and abs(p.y - cam.y - 64) < 64+32 then
			p.method.draw(p)
		end
	end
end

-- projectile type definitions
_p_types = {
	{
		init = _p_spell_init,
		update = _p_spell_update,
		draw = _p_spell_draw
	},
	{
		init = _enemy_crawler_init,
		update = _enemy_crawler_update,
		draw = _enemy_crawler_draw
	},
	{
		init = _enemy_seeker_init,
		update = _enemy_seeker_update,
		draw = _enemy_seeker_draw
	},
	{
		init = _torch_init,
		update = _torch_update,
		draw = _torch_draw
	},
	{
		init = _heart_init,
		update = _heart_update,
		draw = _heart_draw
	},
	{
		init = _enemy_head_init,
		update = _enemy_head_update,
		draw = _enemy_head_draw
	},
	{
		init = _enemy_spell_init,
		update = _enemy_spell_update,
		draw = _enemy_spell_draw
	},
}
__gfx__
0000000075d755d5d666666d77777721777777217777772166eeeeee00e00e0099d11111dd11111d99d11111dd11111d333333333333333300000000eeeeeeee
000000005ddddddd6dddddd5766666d276d676d276d666d2e66eeeee000000001111111dd1dd99111111111dd1dd9911313313333133133307000700eeeeeeee
00000000dd7d52d26dddddd57666d6d2766666d276666dd2ee6eeeeee0ee0000119191111ddd999d119191111ddd999d111111131111111306700670eeeeeeee
000000007dddddd26dddddd57d666dd17666d6d1766676d1e666eeee00ee000011d1d1111dd9d19111d1d1111dd9d191132131211321312106500560eeeeeeee
000000005d52d5dd6dddddd5766666d1776666d177d61dd1eee66eee0000e00e1d1dddd1199911911d1dddd119991191332212223322122205500550eeeeeeee
00000000ddddd2d26dddddd5766666d1767666d1766dd1d1eeee66eee0000e0ed1911dd111dd99d9d1911dd111dd99d9233322332333223305100150eeeeeeee
000000005dddddd26dddddd52ddddd112ddddd112ddd1dd1eeeee66e000000eed1d11d19991dd999d1d11d1ddd1dd999123112221231122201000010eeeeeeee
00000000222d2d22d555555d122111101221111012211110eeeeee660000eeee1dddd19999911d1d1dddd1d999d11d1d232223122322231200000000eeeeeeee
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00e00000111119119119dd1111111d99999ddd112211221222112212eeeeeeeeeeeeeeee
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888e00000000dddd1911911911dddddd1999999911dd2112211221122112eeeeeeeeeeeeeeee
0000000000000000eefefeeeeeeffeeeeefefeeeeefeeeeee888888ee0ee000099d1199919991d9999d11d99999d1d991111112311111123eeeeeeeeeeeeeeee
0000000000000000eeeaeeeeeeaeaeeeefeaeeeeefaefeeee88eee8e00ee0000999d1dd999d1d919999d1dd999dd19192112211221122112eeeeeeeeeeeeeeee
0000000000000000eee9afeeeee9efeeeea9eeeeeee9aeeee88eee8e0000e00ed9dd11d191d1d9d9d9dd11ddddd1d9d91111111111111111eeeeeeeeeeeeeeee
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888e00000e0ed1911111111dd99dd1911111111dd99d1121121111211211eeeeeeeeeeeeeeee
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeee000000ee1d11d1d999d9dd991d11d1d999d9dd992111111221111112eeeeeeeeeeeeeeee
0000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eeeee0000eeee111dd191911d9ddd111d1191911d9ddd1112111111121111eeeeeeeeeeeeeeee
77777763666666666666663136366631eeeeeee000000300000000300eeeeeeeeeedd6777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed77767777777eeeeeeee
67363631663633613613131113136631eeeeee00000000030000300000eeeeeeeeeeedd77777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeed77767767777eeeeeeee
66336633631331333311331111333631eeeee0000030000000003000000eeeeeeeeeeedd777666777eeeeeeeeeeeeeeeeeeeeeeeeeedd77777777777eeeeeeee
66366631313133333313331113136631eee000000300000000000300e000eeeeeeeeeeeed776667677eeeeeeeeeeeeeeeeeeeeeeeeeed67677677677eeeeeeee
66666633631331333333331111333631eeeeee0330000000000000000eeeeeeeeeeeeeeedd777777777eeeeeeeeeeeeeeeeeeeeeeeedd6767677677eeeeeeeee
66366631613333333313331113136631eeeeee00000003000000003031eeeeeeeeeeeeeeed6677666777eeeeeeeeeeeeeeeeeeeeeeed67766776777eeeeeeeee
31331331311111111111111111111311eeeeee0300003000000300300330eeeeeeeeeeeedddd666666777eeeeeeeeeeeeeeeeeeeeeed77777667777eeeeeeeee
11111111111111111111111111111111eeeee00000303000000330030000eeeeeeeeeeeeeed66766666777eeeeeeeeeeeeeeeeeeeedd7667777777eeeeeeeeee
77777777666666311333333366666631eeee00000313000300003000000eeeeeeeeeeeeeeedd7776667677eeeeeeeeeeeeeeeeeeeed67677667777eeeeeeeeee
76677766631136111333131116166611eee00003003000300300030000000eeeeeeeeeeeeeed77777767777eeeeeeeeeeeeeeeeeedd7777777667eeeeeeeeeee
76366666333133111311111111333611eeee033000000000300000000000eeeeeeeeeeeeeeed67666776777eeeeeeeeeeeeeeeeeeed767667777eeeeeeeeeeee
66666666333333311311111113136631eee000000000000030000000000eeeeeeeeeeeeeeeedd7666677777eeeeeeeeeeeeeeeeedd766767677eeeeeeeeeeeee
76666666333133111311111111333611ee00033000000000000000000000eeeeeeeeeeeeeeeed77666777777eeeeeeeeeeeeeeedd767767676eeeeeeeeeeeeee
76666666333333111111111113136611e00330000000000000000003000000eeeeeeeeeeeeedd77777777677eeeeeeeeeeeeeedd777776767eeeeeeeeeeeeeee
63313363111111111311111111111311ee00000000000003000003003000000eeeeeeeeeeeeed77767777777eeeeeeeeeeeeedd76777777eeeeeeeeeeeeeeeee
31111131111111111111111111111111e00000000000300000000000030030eeeeeeeeeeeeedd77777776777eeeeeeeeeeedd6777777eeeeeeeeeeeeeeeeeeee
eeeeeee0dddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000eeeeeeee0000000000000000eeeeeeeeee41eeee
eeeeeee00dd6666dd666d00000066266d66666d22266d66666d6632d00000000000000000000000000000000eeeeeeee0000000000000000eeeeeeeeee41eeee
eeeeeeeee0d6666dd6660eeeeee06666d66666d26666d66666d6663d00000000000000000000000000000000eeeeeeee0000000000000000eeeeeeeee4441eee
eeeeeeeee0ddddddddd0eeeeeeee0ddddddddddddddddddddddddddd00000000000000000000000000000000eeeeeeee0000000000000000eeeeeeee214141ee
eeeeeeeeee0dd666660eeeeeeeeee066666d66666d66666d666666d200000000000000000000000000000000eeeee4ee0000000000000000eeeeeeee21ee41ee
eeeeeeeeeee0d666660eeeeeeeeee066666d66666d66666dd66666d600000000000000000000000000000000eeeee4ee0000000000000000eeeeeeee21ee41ee
eeeeeeeeeee0ddddd0eeeeeeeeeeee0ddddddddd000000dddddddddd00000000000000000000000000000000eeee755e0000000000000000eeeeeeee214141ee
eeeeeeeeeee0666d60eeeeeeeeeeee06d66666d1eeeeee0666d6666d00000000000000000000000000000000eeeee6ee0000000000000000eeeeeeeee4441eee
eeeeeeeeeee0666dd0eeeeeeeeeeee06d226660eeeeeeee066d6666d00000000666d66660000000000000000eeeeeeeeeeeeeeee00000000eeeeeeeeee41eeee
eeeeeeeeeee0ddddd0eeeeeeeeeeee0dddddd0eeeeeeeeee0ddddddd00000000dddddddd0000000000000000eeeeeeeeeeeeeeee00000000eeeeeeeeee41eeee
eeeeeeeeeee0d66660eeeeeeeeeeee0666dd60eeeeeeeeee066666d600000000d66666d60000000000000000eeeeeeeeeeeeeeee00000000eeeeeeeee4441eee
eeeeeeeeeee0d66660eeeeeeeeeeee06666d6eeeeeeeeeeee0666dd600000000d66666d60000000000000000eeeeeeeeeeeeeeee00000000eeeeeeee214141ee
eeeeeeeeeee0ddddd0eeeeeeeeeeee0ddddd0eeeeeeeeeeee0dddddd00000000dddddddd0000000000000000eeeee4eeee4eeeee00000000eeeeeeee21ee41ee
eeeeeeeeeee0666dd0eeeeeeeeeeee06d6660eeeeeeeeeeee06d666600000000666d666d0000000000000000eeeee4eeee4eeeee00000000eeeeeeee21ee41ee
eeeeeeeeeee06666d0eeeeeeeeeeee06d6660eeeeeeeeeeee06d666600000000666d666d0000000000000000eeee755ee755eeee00000000eeeeeeee21ee41ee
eeeeeeeeeee0000000eeeeeeeeeeee0000000eeeeeeeeeeee0dddddd00000000dddddddd0000000000000000eeeee6eeee6eeeee00000000eeeeeeeee4441eee
eeeeeeeeeeeeeeee1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee06666d6e06d666dd66666d6dddddd0e00000000eeeeeeeeeeeeeeee000000000000000000000000
eeeeeeeeeeeeeee131eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee06666d6e0ddddddd66666d6666d660e00000000eeeeeeeeeeeeeeee00000000dddd00dddddddd00
eeeeeeeeeeeeeee131eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0dddddde066666ddddddddd666d660e00000000eeeeeeeeeeeeeeee00000000d1110011ddddd100
eeeeeeeeeeeee113330eeeeeeeeeeeeeeeeeeeeeeeeeeeeee06d666de066666d666d666ddddddd0e00000000eeeee0eeee0eeeee000000001111001111dd1100
eeeeeeeeeeee13303000eeeeeeeeeeeeeeeeeeeeeeeeeeeee06d666de0dddddd666d666d6666660e00000000eeeee4eeee4eeeee000000001111001111111100
eeeeeeeeee11313030031eeeeeeeeeeeeeeeeeeeeeeeeeeee0dddddde03d3366dddddddd6666660e00000000eeeee4eeee4eeeee000000000000000000000000
eeeeeeeeeeee13000000311eeeeeeeeeeeeeeeeeeeeeeeeee06666d6e06d3666d66666d6dddddd0e00000000eeee755ee755eeee000000000000000000000000
eeeeeeeeee003003000003300eeeeeeeeeeeeeeeeeeeeeeee06666d6e0000000d66666d6666d660e00000000eeeee6eeee6eeeee0000000000dddddd111000dd
eeeeeeee0003003003030000eeeeeeeeeeeeeeeeeeeeeeeee0dddddde0dddddddddddddd666d660e000000000000000000000000000000000011111111100011
eeeeeee1300003000000300eeeeeeeeeeeeeeeeeeeeeeeeee06d6666e06d6666666d6666dddddd0e000000000000000000000000000000000011111111100011
eeeeeeee000330303030000eeeeeeeeeeeeeeeeeeeeeeeeee06d6666e06d6666666d66666666660e000000000000000000000000000000000011111111100011
eeeeeee00030003000300031eeeeeeeeeeeeeeeeeeeeeeeee0dddddde0dddddddddddddd6666660e000000000000000000000000000000000000000000000000
eeeeee00000003003003000330eeeeeeeeeeeeeeeeeeeeeee06666d6e06666d6d66666d6dddddd0e000000000000000000000000000000000000000000000000
eeee00000000330030000000000eeeeeeeeeeeeeeeeeeeeee06666d6e06666d6d66666d6666d660e00000000000000000000000000000000ddddddddd0011111
eeeeeeee30030000000030000eeeeeeeeeeeeeeeeeeeeeeee0dddddde0dddddddddddddd666d660e0000000000000000000000000000000011111111d0011111
eeeeeeee003003000000030000eeeeeed66666d666666d66666d6666e06d6666666d6666dddddd0e000000000000000000000000000000001111111110011111
000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000eeee12111111111111111111111121ee
dddd00dddddddeeeeee11dddddddd00d0000000000000000000000000000000000000000000000000000000000000000eeee12222222222222222222222221ee
d1110011ddddeeeeeeee11111111d0010000000000000000000000000000000000000000000000000000000000000000eeee1d2dddddddddddddddddddd2d1ee
1111001111deeeeeeeeee111111110010000000000000000000000000000000000000000000000000000000000000000eee1211222d2d2dddddddd2d2221121e
1111001111eeeeeeeeeeee11111110010000000000000000000000000000000000000000000000000000000000000000eee1211222d2dddddddddd2d2211121e
000000001eeeeeeeeeeeeee1000000000000000000000000000000000000000000000000000000000000000000000000eee1211222d2dddddddddd2d2221121e
000000011eeeeeeeeeeeeee1100000000000000000000000000000000000000000000000000000000000000000000000eeee11111111111111111111111111ee
00ddddddeeeeeeeeeeeeeeee1100ddd10000000000000000000000000000000000000000000000000000000000000000eeeeee1111111111111111111111eeee
0011111eeeeeee6666eeeeeee10011110000000001111111111011110111111111101111011111111110111100000000eeeeee1111122222222222211111eeee
0011111eeeee66111111eeeee11011110000000010000000100000001000000010000000100000001000000000000000eeeeee121122dddddddddd221121eeee
001111eeeee611eeee111eeeee1001110000000005511555015511110111111101111111011111110111111100000000eeeeeee11111111111111111111eeeee
000011eeeee11eeeeee11eeeee1100010000000005111151011511110111111101111111011111110111111100000000eeeeeeeee1112212222122111eeeeeee
00001eeeee11eeeeeeee11eeeee100000000000001111111011111110111111101111111011111110111111100000000eeeeeeeee112222dddd222211eeeeeee
dd001eeeee111eeeeee111eeeee100000000000011111000000100001000000000010000111110000001000000000000eeeeeeeee1112d1dddd2d2111eeeeeee
11011eeeee1e1eeeeee1e1eeeee11ddd00000000051101111111111501110111111111110b1101111111111300000000eeeeeeeee1122d2dddd2d2211eeeeeee
1101eeeee11e11eeee11e11eeeee111100000000055101111111115501110111111111110bb10111111111b300000000eeeeeeeee1112d1dddd1d2111eeeeeee
1101eeeee111e1eeee1e111eeeee1111000000000555011111111555011101111111111103bb01111111133300000000000eeeeee1112d1dddd1d2111ee00000
1101eeeee111111ee111111eeeee11110000000055000000100100001100000010000000330000001000000000000000000eeeeee1122d2dddd2d2211ee00000
0001eeeee111111ee111111eeeee1000000000005551011101111555011111110111111133b1011101111b3300000000000eeeeee1112d2dddd2d2111ee00000
0011eeeee11e11111111e11eeeee1100000000000551011101111115011111110111111103b101110111111b00000000000eeeeee1122d1dddd1d2211ee00000
001eeeee11eeee1111eeee11eeeee10000000000051101110111111101111111011111110b1101110111111100000000000eeeeee1112d2dddd1d2111ee00000
001eeeee11eeee6e11eeee11eeeee1000000000000001000000100000000100000010000000010000001000000000000000eeeeee1122d1dddd1d2211ee00000
001eeeee11eeeee61eeeee11eeeee1000000000011110111111011111111011111101111111101111110111100000000000eeeeee1112d2dddd2d2111ee00000
001eeeee11eeeee61eeeee11eeeee1100000000011110111111011111111011111101111111101111110111100000000000eeeeee1122d2dddd2d2211ee00000
011eeeee11eeeee11eeeee11eeeee1100000000000000000000000000000000000000000000000000000000000000000000eeeeee1112d1dddd1d2111ee00000
011eeeee11eeeee11eeeee11eeeee1100000000000000000000000000000000000000000000000000000000000000000000eeeeee1122d2dddd2d2211ee00000
011eeeee11eeeee11eeeee11eeeee1100000000000000000000000000000000000000000000000000000000000000000000eeeeee1112d2dddd2d2111ee00000
011eeeee11eeeee11eeeee11eeeee1100000000000000000000000000000000000000000000000000000000000000000000eeeeee1122d1dddd1d2211ee00000
011eeeee11eeeee11eeeee11eeeee1100000000000000000000000000000000000000000000000000000000000000000000eeeeee1112d2dddd1d2111ee00000
011eeeee11eeeee11eeeee11eeeee1100000000000000000000000000000000000000000000000000000000000000000000eeeeee1122d1dddd1d2211ee00000
011eeeee11eeeee11eeeee11eeeee1100000000000000000000000000000000000000000000000000000000000000000000eeeeee1112d2dddd2d2111ee00000
011eeeee11eeeee11eeeee11eeeee11000000000e0000000000000000000000000000000000000000000000000000000000eeeeee1122d2dddd2d2211ee00000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5666667e5666667eeeeeeeeeeeeeeeeeeeeeeeeeee7776eeeeeeeeeeee6676eeeeeeeeeeeeeeeeeeeeeeeeeeee3eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6666677e6666677eeeeeeeeeeeeeeeeeee7700111155dd6eeeeeeee00055dd6ee7eee7eeeeeeeeeeeeeebeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6610d0ae6610d0aeeeeeeeeeeeeeeeeee7ddddd555555dd1eeeee00555555551e67ee67eeeeeebeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55ddddee55ddddeeeeeeeeeeeeeeeee0d000ddd55000051eeee0dd555500051e65ee56eeeeeeeeeeeeeeeeeeeeeebee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55eeeeee55eeeeeeeeef77eeeeeee00000122500000d1eee0d555550000d1e55ee55ee3b33bbee3333bbeeb333bbe
eeee377eeeeeeeeeeeee377eeeeeeeee1eeee88e1eeee888eeeeeeff77eeeeeee01ee00222200dd1ee0d552055000dd1e51ee15eeeebeeeeeeeeeebeeeeebeee
eee3b7711eeeeeeeeee3b7711eeeeeeee1112ee8e1112eeeeeee110f770eeeeeee1eee000122dd0ee1dd52000222dd0ee10ee01eeeeeeeeeeebeeeeeeeeeeeee
ee3be3bbb1eeeeeeee3bee1bb1eeeeeeeeeeeeeeeeeeeeeeeee011006011eeeeee00eeee0002220ee00020000202220ee00ee00eeeeeeeeeeeeeeeeee3eeeeee
ee1be3beeb3eeeeeee3be3bbe77eeeee5666667eeeeeeeeeee01110001111eeeeeeeeeeee000000ee0ee0eee0000000eee7776eeeeeeeeeeeeeeeeeeeeeeeeee
ee1536bee77eeeeeee1536bee77eeeee6666677eeeeeeeeeee0110060002999eeeeeeeee0000000eeee0ee02000000001155dd6ee111e22eeee122eeeee221ee
e100bb31e77eeeeee110bb3eeeeeef4e6610d0aeeeeeeeeeee01105600244449eeeeeee002000200ee1022252200000255555dd112881887ee12282eee28821e
e103bb331eeeeeeee103bb33eeeff4eee55ddddeeeeeeeeeee11000002405442eeeeee0022222555eee1555555222222549a005128888878e122887eee88821e
e10113bb31eeeeeee10133bb34f4eeeeeee55eeeeeeeeeeeee1101002445742eeeee0002555555ddeeee11555555555d4999a0d128888888e128888eee888821
e1ee133b44ff55eee1e111344554eeee1eeee88eeeeeeeeeee1000052444422eee0022255511ddddeeeee1155555dddd24499dd11288888ee12888eeee888821
ee350003500f054eee30001350004eeee1112ee8eeeeeeeeee10f66522422eee0021115551dddddeeeeeeee1111dddde0124dd0ee12888eee12888eeeee88821
300000000eefe054300000001ee05eeeeeeee88eeeeeeeeeee0777767111eeee055555551eedd11eeeeeeeeeeeedd11e0002220eee128eeeee128eeeeeee821e
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77eeeeeeeeeeeeeeeeeeeeeee000000e77eeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeee6feeeeeeeed676eeeeeeeeeeeed676ee6feeeeeeeeeeeeee6feeeeeeeed67e67eeeeeeeeee0d67eeeeeeeeee559eee67eeeee
eeeeeeeeeeeeeeeeeeeeef777eef7eeeeeeeef777ee6feeeeeeeef777eef7eeeeeeeef777eef7eeeeeeeef777e67eeeeeeeee0f777eeeeeeeeee59ee7e67eeee
eeeeeeeeeeeeeeeeeeeeeff77e017eeeeee00ffd0eef7eeeee121ffd0e017eeeeeeeeff77e017eeeeee00ffd0ef6eeeeeee000ffd0eeeeeeeeeee9ee0ef6eeee
eeeeeeeeeeeeeeeeeeeee0fd0122feeee01210dfde017eeee129210dde01feeeee1210fd0e01feeee1210d0fdee67eeeee12100dfdeeeeeeeeeee9eedee67eee
eeee377eeeeeeeeeeeee0006d2992eeee129210d0001feee012492000011feeee129210dd011feee1292100d0e0f61eee1292010d0eeeeeeeeeefeee0e0f61ee
eee3b7711eeeeeeeeee01100024492ee012492000111feee01dd42100101feeee12492000101feee124920000000182ee1249200000eeeeeeeeeeeee0000182e
ee3be1bbb1eeeeeeeee01101144442ee01dd42101001feee077d4276101f6eee01dd4216101f6eee1dd421001001211ee1dd42101000eeeeeeeeeeee1001211e
ee3be3beeb1eeeeeee011100245742ee077d4276001f6eee00d142d000280eee077d427000280eee77d420700000106ee77d4200000021eeeeeeee7e03007eee
eeb536bee77eeeeeee011006240542ee00d142d000280eee0014927000782eee00d142d000782eee0d1420d000000eeee0d1420000072887777777fe004f1fee
e110b3bee77eeeeeee011056244442ee0014927000782eee1019100000272eee1014927000272eee01492070000eeeeee01492000ee04066ffffffee0006feee
e103bb33eeeeeeeeee11000002442eee0019100000272eeee00101000000eeeee019100000000eee01910000000eeeeee01910000eeeeeeeeeeeeeee0e66eeee
e11113bb3eeff4eeee1101001022eeeee01101001000eeeee0000010100eeeeee001010010000eeee110100010eeeeeeee11010010eeeeeeeeeeeeee10eeeeee
e1e1133b5ff4ff4eee100000101eeeeee0001000101eeeeeee0000001010eeeee000000010100eeee0001000101eeeeeee001000010eeeeeeeeeeeee010eeeee
ee11000350054f4eee1000100010eeeee0010100000eeeeeee0001000000eeeeee00001000000eeee0010100000eeeeeeee10100000eeeeeeeeeeeee000eeeee
310000005e054f4eee000e000000eeeeee0000e00011eeeeee0000e00000eeeeee000e000000eeeeee0000e0001eeeeeee0000ee0001eeeeeeeeeeee0001eeee
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000555555005555550011101111111011111110111111101111111011111110
00000000000000000000000000000000000000000000000000000000000000000000510151005111110000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000511111005111010001111101011111010111110101111101011111010111
00000000000000000000000000000000000000000000000000000000000000000000511101005011100001111101011111010111110101111101011111010111
00000000000000000000000000000000000000000000000000000000000000000000551111005111110000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000515111005111110011101110111011101110111011101110111011101110
00000000001666666666666666666666666666661000000000000000000000000000000000000000000011101110111011101110111011101110111011101110
00000000001122222200000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001122222200000000000000000000001000000000000000000000000000011111100111111001111110011111100111111001111110011111100111
00000000001182228200000000000000000000001000000000000000000000000000100000001000000010000000100000001000000010000000100000001000
00000000001122222200000000000000000000001000000000000000000000000000100000001000000010000000100000001000000010000000100000001000
00000000000000000000000000000000000000000000000000000000000000000000100000001000000010000000100000001000000010000000100000001000
00000000000000000000000000000000000000000000000000000000000000000000100000001000000010000000100000001000000010000000100000001000
00000000000000000000000000000000000000000000000000000000000000000000100000001000000010000000100000001000000010000000100000001000
00000000000000000000000000000000000000000000000000000000000000000000100000001000000010000000100000001000000010000000100000001000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555111111001111111111111100111111000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000051155511100001001101001001000000010000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000051011111000000001000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000051111111000000001000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000051111111000000001000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000010000010000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111001111111100000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010111001101001000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000
00000000000000000000000000000000000dd6777777000000000000000000000000000000000000000000000000110001001000000000000000000000000000
0000000000000000000000000000000000000dd77777777000000000000000000000000000000000000000000000130011001000000000000000000000000000
00000000000000000000000000000000000000dd7776667770000000000000000000000000000000000000000000110000000000000000000000000000000000
0000000000000000000000000000000000000000d776667677000000000000000000000000000000000000000000110000000000000000000000000000000000
0000000000000000000000000000000000000000dd77777777700000000000000000000000000000000077777763666111110000000000000000000000000000
00000000000000000000000000000000000000000d66776667770000000000000000000000000000000067363631663100100000000000000000000000000000
0000000000000000000000000000000000000000dddd666666777000000000000000000000000000000066336633631000000000000000000000000000000000
000000000000000000000000000000000000000000d6676666677700000000000000000000000000410066366631313100000000000000000000000000000000
000000000000000000000000000000000000000000dd777666767700000000000000000000000000410066666633631300000000000000000000000000000000
0000000000000000000000000000000000000000000d777777677770000000000000000000000000410066366631613300000000000000000000000000000000
0000000000000000000000000000000000000000000d676667767770000000000000000000000000410031331331311100000000000000000000000000000000
0000000000000000000000000000000000000000000dd76666777770000000000000000000000014100011111111111110000000000000000000000000000000
00000000000000000000000000000000000000000000d77666777777000000000000000000000011000077777777666665000000000000000000000000000000
0000000000000000000000000000000000000000000dd7777777767700000000000000000000002100007667776663113d000000000000000000000000000000
00000000000000000000000000000000000000000000d77767777777000000000000000000000144100076366666333133000000000000000000000000000000
0000000000000000000000000000000000000000000dd77777776777000000000000000000000041410066666666333333000000000000000000000000000000
00000000000000000000000000000000000000000000d77767777777000000000000000000000000410076666666333133000000000000000000000000000000
00000000000000000000000000000000000000000000d77767767777000000000000000000000000410076666666333333000000000000000000000000000000
0000000000000000000000000000000000000000000dd77777777777000000000000000000000100410063313363111111100000000000000000000000000000
00000000000000000000000000000000000000000000d67677677677000000000000000000000444100031111131111111100000000000000000000000000000
0000000000000000000000000000000000000000000dd676767767700000000000000000000000410000777777636666666d5111110000000000000000000000
0000000000000000000000000000000010000000000d677667767770000000000000000000000041000067363631663633610500000000000000000000000000
0000000000000000000000000000000131000000000d777776677770000000010000000000000444100066336633631331330000000000000000000000000000
000000000000000001000000000000013100000000dd766777777700000000131000000000002141410066366631313133331000000000000000000000000000
000100000000000013100000000001133300000001d6767766777700000000131000000010002100410066666633631331331000000000000000000000000000
00131000000000001310000000001330300000001317777777667000000011333000000131002100411166366631613333333000000000000000000000000000
00131000000000113330000000113130300310001317676677770000000133030000000131002141413331331331311111111000000000000000000000000000
11333000000001330300000000001300000031113330676767700000011313030031011333000444131311111111111111111000000000000000000000000000
33030000000113130300310000003003000001330300067676000000000130000003133030000000013077777777666666311300000011111100000000000000
13030031000001300000031100030030030113130300317670000000000300300011313030031000030076677766631136111310000001011100000000000000
30000003110003003000003130000300000031300000031100000000003003003030130000003000300376366666333133111300000000000100000000000000
00300000300030030030300000033030303003003000003300000013000030000000300300001300003066666666333333311300000000001100000000000000
03003030130000300000030000300030000030030030300000000000003303030003003003030000330376666666333133111310000000000100000000000000
30000003000033030303000000000300130000300000030000000000030003013000030000000003000376666666333333111110000000001100000000000000
03030310000300030003000000003300300033030303000000000000000030030003303030300000003063313363111111111310000000000000000000000000
03000131000000300300300030030000000300030003000310000000000330000030003000000000033031111131111111111111000000000000000000000000
30030131000003300300000000300300000000300100300033000003003000000000010030030300300000000030030000006666d55111111100000000000000
30011333030000000000030000000000000003301310000000000000030000000000131030000003003000000000030000006636105001000000000000000000
00133030000000300000000000000003030030001310030000000000000030003003131000000000003000000000000300116313100000000000000000000000
11313030000000000000000000300000000300113330003000000000000000300011333000000000000030000030000000003131310000000000000000000000
30130000000000003000000003000000000001330300000300000000030000000133030000000003000000000300000000006313300000000000000000000000
00300300000000000000030330000000000113130300310000000000300000011313030031000030000000033000000000036133310000000000000000000000
03003003000000000000000000000300000301300000031100000033000000000130000003113300000000000000030130003111110000000000000000000000
00030000000000000000000300000000003003003000003300000000000000000300300000330000003000030000300000031111110000000000000000000000
0330000000000000000000000030300030003003003030000000003000030000300300303000000003007777777766666631666666d555511100000000000000
30000000000000000000000003130000130000300000030003100000030313000030000d6d50000303007667776663113611663633d005000000000000000000
00030000000000000000000300300030300033030303000000300000313000003309d30666900031300076366666333133116313313100000000000000000000
00300000000000000000033000000000000300030003000310000030030000030306900059900003000366666666333333313131333100000000000000000000
03000000000000000000000000000000000000300300300033003300000000000036000595001000000076666666333133116313313110000000000000000000
50000000000000000000000000000000000003300300000000000000000000000339000050014100000076666666333333116133333310000000000000000000
55030000000000000000000000000033030030000000030000003300000003b03009000000142100000363313363111111113111111100000000000000000000
0000000000000000000000000000000000030030000000300003000000000bb333b9000000125500000031111131111111111111111100000000000000000000
300000000000000000000000000000330000003000000003000011111b30bbbbbb3d9000d61256606631777777636666666666666631dd555500000000000000
0000000000000000000000300300330000000000300003000000050003000b0bbb00210005120500dd00d61d1d10dd1d11d01d0101000d055500000000000000
00000000000000000000000000300000000000000000030000000000000000333b312600061420001d00dd11dd11d10110111100110000000500000000000000
0000000000000000000000000000000000000000000000300000000000000303bb31610000004000dd10dd1ddd10101011111101110001005500000000000000
00000000000000000000000000000000000000000000000000000000000000333b000000000000011d00dddddd11d10110111111110000100500000000000000
3000000000000000000000000000000000000000000000030310000000000303bb00000000000001dd00dd1ddd10d01111111101110001005500000000000000
13000000000000000000000000000000000000000000300300330000000000000100000000000000010010110110100000000000000000000000000000000000
30000000000000000000000000000000000000000000330030000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111111111111111111111111111111100001111111111111111111115dddddd55dddddd55dddddd55ddd5551111111100111
011110110111101101111011011110110111101101111011011110110000000101111011011110110111d5555551d5555551d5555551d5555110500000001000
000100000001000000010000000100000001000000010000000100000000000000010000000100000001d5555551d5555551d5555551d5555110510000001000
101001101010011010100110101001101010011010100110101001101000001010100110101001101010d5555551d5555551d5555551d5555110510000001000
01111111011111110111111101111111011111110111111101111111000000000000000000000000000051111110511111105111111051111110510000001000
11111111111111111111111111111111111111111111111111111111111111111111011111111111111110000000100000001000000010000000100000001000
01110110011101100111011001110110011101100111011001110110011101100111011001110110011110000000100000001000000010000000100000001000
11011111110111111101111111011111110111111101111111011111110111111101111111011111110100000000000000000000000000000000000000000000
11011100110111001101110011011100110111001101110011011100110111001101110011011100110155555500555555001110111111101111111011111110
10011001100110011001100110011001100110011001100110011001100110011001100110011001100151011100510111000000000000000000000000000000
00110000001100000011000000110000001100000011000000110000001100000011000000110000001151111000511110000111110101111101011111010111
10011001100110011001100110011001100110011001100110011001100110011001100110011001100151115100511151000111110101111101011111010111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000055010000550100000000000000000000000000000000
01000010010000100100001001000010010000100100001001000010010000100100001001000010010051100000511000001110111011101110111011101110
00011000000110000001100000011000000110000001100000011000000110000001100000011000000100000000000000001110111011101110111011101110
00000001000000010000000100000001000000010000000100000001000000010000000100000001000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
000101010101000000000000111100000008000000000000000000001010000000000000c0c0c0c0c0c0c00000c0c00000000000c0c0c0c000c0c000c0c0c00000010100010101000000000000000000000100000100010001000000000000000080800000000101010100000000000080808080000001010101000000000000
0000000000000000000000000000000000000000008080808080800000000000000000000080808080808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
026464c064646464025f6464c0645e5e025e6464645f64646464646464646464645f646464644f95969798979897979897989730313233969798a89a97302031004f0000000000000000000000000000000000000000000000000000000000000000040358585858585858585858585858585858585858585858585858585858
02646464646464644f4f5e5e5e5e5e5e5e5e5e5e5e5f5b6464c464645c646464644f646464645fa5989798a7a8a7a7a897a897972122a598a7a8aaa8a7202122005f0000000000000000000000000000000000000000000000000000000000000000020202020202020202020202020202020202020202020202020202020202
02646464646464645f646464645e5e5e5e5e5e5e5e4f646464646464646464646464646464644f4ba89a994ba8a7a64b9797979898979798974b99c497323323004f00000000000000000000000000000000000000000000000000000000000000004f4f30312122223233212233212233212232332122332122212232332122
026464646464646464646464645e5e5e64db64646464030364646464646464646464646464645fa5a8aaa9989798a7a6a598a5a898dba7a8a7a8a99899203031005f00000000000000000000000000000000000000000000000000000000000000004f5f0733216f6f6f6e6f6e6f6f6f6f6f6e21236e6f6f6e6f6f6f6f332121
026464646464dd6464646464645e5e5e5e64646464cc0303646464646469646464646464646464a5a6a7a8a8a7a8a89797a89797989798969797a7a8a6212297004f00000000000000000000000000000000000000000000000000000000000000004f4f2021326f6f6f6e6f6e81826e6e6f6e22236e6e6f6e81826e6e323222
02020202020218191a1b02020202020202020202020202020202020258795c64030364646464640202020202020202a7979797a7a80298a60202a7a8a797994b00000000000000000000000000000000000000000000000000000000000000000000005f30316f6f6f6f6e6f909192937e6f6e33236e6e6f909192937e320202
5e5e5e5e5e0208090a02025e5e5e5e5e645e5e5e5e5e5e5e5e5e5e5e7869646464646464646464666868686868686802a7aaa7a902029798a899979897dda9a700000000000000000000004b00000000000000000000000000000000000000000000004f2021226f6f6f7e7fa0a1a2a36e6f7e32237e7e7fa0a1a2a36e330202
5e5e5e5e5e02020202025e5e5e5e5e5e5e645e5e5e5e5e5e5e5e5e5e5879646464646464050564666868686868686868020202020202a7a8aaa9a7a897039697000000000000000000000000000000000000000000000000000000000000000000000000303132336e6e6e6eb0b1b2a36f166e32236e6f6eb0b1b2a36f330202
5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e645e5e5e5e5e5e5e5e5e78696464646464646464646668686868686868686868680202020e0e0e0e0e0e0a03a6a5000000db00004b0000000304050000000000616200000000000061620000000000000000000021226e6e6f6eb0b1b2b37e6e6f33236f6e6eb0b1b2b37e200202
5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e587964030364646464645b6668686868686868686868680202020202020202020303032122000200000000000000004f000000000070717273006162db7071727300000000000000303121226f6e6f6eb0b1b2b36e6e6f32236e6e6eb0b1b2b36e320202
5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e786964c4640364646464646668686868686868686868680202020202020202020203030323000202000304050000005f000000000024252627707172732425262761620022333233202122337e7e7e7e7e7e7e7e7e7e7e30317e7e7e7edd7e7e7e320202
5e5e026466020202020202020202020202020202020202020202020202795c6464646464646464666868686464646464000000000000000000009798080909cccccccccccccccccccccc0c0c0d0c0d0c0c0d0c0d0c0d0c0d0c0d0c0d0c0d0c0d0c0d0c0d02020202020202020202020202020202020202020303030302020202
5e5e026477444546424342434243424342434243424342434445467878696464646464640202646668686864646464640000000000000000000000001819020908090a0b08090a0b08090a0b0a0b1c1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d05055858585858585858585858585858585858585858585858585858
5e5e026467546456525352535253525352535253525352535455565858796464646464646464646668686864646464640000000000000000000000000000021918191a1b18191a1b18191a1b1a1b1c1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
5e5e026464645c64c464645c6464646cc464645c6464645c6464675264646464020264646464646668686864646464640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e026464646464646464646464646464646464646464646464646464646464646464c06464646668686864000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e02cccc64dd64646464646464646464646464646464646464646464646464646464646464647678786864000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5e020202020202020202020202020202020202020202020202020202020202020202020202020202020b64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9897989798a7a89897989798a7a898979897989798a7a897989798a7a8989798979897989798979897989798000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98979896a8979898979896a89798989798979896a89798979896a89798a8a79897989798a79897989798a7a8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a6a5a8a7a8a7a8a6a5a8a7a8a7a8a6a5a6a5a8a7a8a7a8a5a8a7a8a7a8989798979896a89798979896a89798000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98979897989a999897979897989a99979897a8a7a6a5a8a7a8a7a8a7a7a8a7a6a5a8a7a8a7a6a5a8a7a8a7a8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a8979896a8aaa9a8a7979896a8aaa9a7a8a79897989a999798979897979897989a99979897989a9997989798000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a7a6a5a69897989897a6a5a69897989798979897989798a7a89897989798a7a898979897a7a89897989796a8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9897989798a7a89897989798a7a89898979897989897989798a7a89897989798a7a898979798a7a898979897000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9897989798a7a898979897989897989798a7a89898979896a8979898979896a89798989796a8979898979897636363630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98979896a8979898979896a898979896a8979898a6a5a8a7a8a7a8a6a5a8a7a8a7a8a6a5a7a8a7a8a6a5a6a5636363630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a6a5a8a7a8a7a8a6a5a8a7a8a6a5a8a7a8a7a8a698979897989a999897979897989a99979897989a99979897636363630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98979897989a99989797989798979897989a9998a8979896a8aaa9a8a7979896a8aaa9a79896a8aaa9a7a8a7636363630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a8979896a8aaa9a8a7979896a8979896a8aaa9a8a7a6a5a69897989897a6a5a698979897a5a6989798979897636363630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a7a6a5a69897989897a6a5a6a7a6a5a698979898a7a6a5a69897989897a6a5a698979897a5a6989798979897000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00030000371501414015140181401a1401c5401e55021550235502a5502d2302b6203020000800020000100001000010000200005000050000600007000000000000000000000000000000000000000000000000
0003000007950099500b9500e9501095010950109500f9500095016000110000f0001000014000190001e00020000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f9701f9701a9501a950199501795014950109300b930049100095000c0001c0001c0001c0001c0001c00000000000000000000000000000000000000000000000000000000000000000000000000000
000400003fd303ed603b1603b1203b11036f0022f0003f003ef003ef002fd0034d0002b0000b0000b0012b0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003665036640346303463034620355101153024340053400034000340003200255000000000000000001000001000110000100001000010000100001000010000100001000010001100011000010000000
000200001065005630016100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001a6101a01019010119101591017910199201a9201b9201b95019950159500f9500a950089400324003240032300423004230032300323003230032300322004210022100020001200002000520002200
000400003e7403e7403e7403e7403e7303e7303d7203d7203c7103c710017000270002700027000270001000105000d5000850005500015000050000500000000000000000000000000000000000000000000000
0004000016c1000c1000c1000c1001c1002c0000c00106000c6000660000600006001560013600106000c60008600066000460001600006000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001885000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
