--experimental code to show humidity and temperature

local mg = ""
local skyland = false
local wshed = false
local height_threshold = false

minetest.register_on_mapgen_init(function(mgparams)
	if mgparams.mgname == "v7" then
		mg = "v7"
	end
end)

local tperlin
local hperlin
tempidity = {}
tempidity.hud = {}
local timer = 0

minetest.register_globalstep(function(dtime)
	--something
	local point = {x=1,y=1,z=1}
	--display HUD to each person
	for _,player in ipairs(minetest.get_connected_players()) do
		--common variables
		local pos = vector.round(player:getpos())
		local name = player:get_player_name()
		
		--actual display temp/humidity
    local biome_data = minetest.get_biome_data(pos)
    local biome_name = minetest.get_biome_name(biome_data.biome)
		local temperature = biome_data.heat
		local humidity = biome_data.humidity
		
		--check if a HUD for the player is already set up
		if not tempidity.hud[name] then
			--nope, so make one
			tempidity.hud[name] = {}
			--temperature...
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
			--humidity...
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
      --biome...
			tempidity.hud[name].BiomeId = player:hud_add({
				hud_elem_type = "text",
				name = "Biome",
				number = 0xFFFFFF,
				position = {x=1, y=1},
				offset = {x=-128, y=-40},
				direction = 0,
				text = biome_name,
				scale = {x=200, y=60},
				alignment = {x=1, y=1},
			})
			--store the values to potentially reduce calculations
			tempidity.hud[name].oldTemp = temperature
			tempidity.hud[name].oldHumid = humidity
      tempidity.hud[name].oldBiome = biome_name
			return
		--HUD already exists
		--see if temperature is the same here, if not, redraw
		elseif tempidity.hud[name].oldTemp ~= temperature then
			player:hud_change(tempidity.hud[name].TempId, "text",
				"Temperature: "..temperature.." C")
			tempidity.hud[name].oldTemp = temperature
		--same for humidity
		elseif tempidity.hud[name].oldHumid ~= humidity then
			player:hud_change(tempidity.hud[name].HumidId, "text",
				"Humidity: "..humidity)
			tempidity.hud[name].oldHumid = humidity
    --same for biome
		elseif tempidity.hud[name].oldBiome ~= biome_name then
			player:hud_change(tempidity.hud[name].BiomeId, "text",
				biome_name)
			tempidity.hud[name].oldBiome = biome_name
		end
	end
end)

--clear calculations for the HUD of the now non-existant player
minetest.register_on_leaveplayer(function(player)
	tempidity.hud[player:get_player_name()] = nil
end)