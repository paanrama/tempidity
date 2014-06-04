--experimental code to show humidity and temperature
--ONLY WORKS FOR THIS MOD AND WATERSHED

-- 3D noise for temperature

local np_temp = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 9130,
	octaves = 3,
	persist = 0.5
}

-- 3D noise for humidity

local np_humid = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -55500,
	octaves = 3,
	persist = 0.5
}
tempidity = {}
tempidity.hud = {}
local timer = 0
minetest.register_globalstep(function(dtime)
	--grab humidity and temp values
	local point = {x=1,y=1,z=1}
	--timer = timer + dtime
	--if timer >= 1.5 then
	--display them in the bottom right (because areas is usually bottom left)
	for _,player in ipairs(minetest.get_connected_players()) do
		local pos = vector.round(player:getpos())
		local nvals_temp = minetest.get_perlin_map(np_temp, point):get3dMap_flat(pos)
		local nvals_humid = minetest.get_perlin_map(np_humid, point):get3dMap_flat(pos)
		local name = player:get_player_name()
		local temperature = nvals_temp[1]--math.floor(nvals_temp[1] * 100)--00)/100
		local humidity = nvals_humid[1]--math.floor(nvals_humid[1] * 100)--00)/100
		temperature = math.floor((25 + temperature * 50) * 100) / 100
		humidity = math.floor((50 + humidity * 31.25) * 100) / 100
		if not tempidity.hud[name] then
			tempidity.hud[name] = {}
			tempidity.hud[name].TempId = player:hud_add({
				hud_elem_type = "text",
				name = "Temperature",
				number = 0xFFFFFF,
				position = {x=1, y=1},
				offset = {x=-128, y=-80},
				direction = 0,
				text = "Temperature: "..temperature.." C",
				scale = {x=200, y=60},
				alignment = {x=1, y=1},
			})
			tempidity.hud[name].HumidId = player:hud_add({
				hud_elem_type = "text",
				name = "Humidity",
				number = 0xFFFFFF,
				position = {x=1, y=1},
				offset = {x=-128, y=-60},
				direction = 0,
				text = "Humidity: "..humidity,
				scale = {x=200, y=60},
				alignment = {x=1, y=1},
			})
			tempidity.hud[name].oldTemp = temperature
			tempidity.hud[name].oldHumid = humidity
			return
		elseif tempidity.hud[name].oldTemp ~= temperature then
			player:hud_change(tempidity.hud[name].TempId, "text",
				"Temperature: "..temperature.." C")
			tempidity.hud[name].oldTemp = temperature
		elseif tempidity.hud[name].oldHumid ~= humidity then
			player:hud_change(tempidity.hud[name].HumidId, "text",
				"Humidity: "..humidity)
			tempidity.hud[name].oldHumid = humidity
		end
	end
	--timer = 0
	--end
end)

minetest.register_on_leaveplayer(function(player)
	tempidity.hud[player:get_player_name()] = nil
end)