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
local np_temp = nil
local np_humid = nil

-- noise vals for default mgv7
if mg == "v7" then
	-- 2D noise for temperature
	tperlin =0 

	-- 2D noise for humidity
	hperlin =0 
end

if minetest.get_modpath("skylands") or minetest.get_modpath("watershed") then
	-- noise vals for watershed and skylands
	-- 3D noise for temperature
	np_temp = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = 9130,
		octaves = 3,
		persist = 0.5
	}

	-- 3D noise for humidity

	np_humid = {
		offset = 0,
		scale = 1,
		spread = {x=512, y=512, z=512},
		seed = -55500,
		octaves = 3,
		persist = 0.5
	}
	if minetest.get_modpath("skylands") then
		skyland = true
	end
	if minetest.get_modpath("watershed") then
		wshed = true
	end
end

--make it so that the engine knows it needs to switch between 2D and 3D noise depending on altitude
if mg == "v7" and skyland == true then
	height_threshold =true
end

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
		local temperature = 0
		local humidity = 0
		
		--in order: if mgv7+skylands, or watershed, or NOT mgv7 (assume only skylands)
		if (height_threshold and pos.y >= 700) or wshed or mg ~= "v7" then
			--use 3D values
			local nvals_temp = minetest.get_perlin_map(np_temp, point):get3dMap_flat(pos)
			local nvals_humid = minetest.get_perlin_map(np_humid, point):get3dMap_flat(pos)
			local temp = nvals_temp[1]
			local humid = nvals_humid[1]
			
			--set temperature and humidity
			temperature = math.floor((temp * 20) * 100) / 100 -- in Celsius
			humidity = math.floor((humid + 1.75)/3.5 * 100) / 100 --in %
		--otherwise, if ONLY mgv7
		elseif mg == "v7" then
			--get 2d temperature
			local tnoise = minetest.get_perlin(35293, 1, 0, 500):get2d({x=pos.x,y=pos.z})
			temperature = math.floor((25 + tnoise * 50)*100) / 100 -- convert to Celsius
			
			--get 2d humidity
			local hnoise = minetest.get_perlin(12094, 2, 0.6, 750):get2d({x=pos.x,y=pos.z})
			humidity = math.floor((50 + hnoise * 31.25)*100) / 100 --unit conversion
		else --none of the above. skip calculations
			break --nope.avi
		end		
		
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
			--store the values to potentially reduce calculations
			tempidity.hud[name].oldTemp = temperature
			tempidity.hud[name].oldHumid = humidity
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
		end
	end
end)

--clear calculations for the HUD of the now non-existant player
minetest.register_on_leaveplayer(function(player)
	tempidity.hud[player:get_player_name()] = nil
end)