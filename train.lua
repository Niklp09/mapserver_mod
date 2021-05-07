
local last_set_by = {}

local update_formspec = function(meta)
	local line = meta:get_string("line")
	local station = meta:get_string("station")
	local index = meta:get_string("index")
	local color = meta:get_string("color") or ""

	meta:set_string("infotext", "Train: Line=" .. line .. ", Station=" .. station)

	meta:set_string("formspec", "size[8,4;]" ..
		-- col 1
		"field[0,1;4,1;line;Line;" .. line .. "]" ..
		"button_exit[4,1;4,1;save;Save]" ..

		-- col 2
		"field[0,2.5;4,1;station;Station;" .. station .. "]" ..
		"field[4,2.5;4,1;index;Index;" .. index .. "]" ..

		-- col 3
		"field[0,3.5;4,1;color;Color;" .. color .. "]" ..
		""
	)

end


minetest.register_node("mapserver:train", {
	description = "Mapserver Train",
	tiles = {
		"mapserver_train.png"
	},
	groups = {cracky=3,oddly_breakable_by_hand=3},
	sounds = moditems.sound_glass(),
	can_dig = mapserver.can_interact,
	after_place_node = mapserver.after_place_node,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)

		local find_nearest_player = function(block_pos, radius)
			-- adapted from https://forum.minetest.net/viewtopic.php?t=23319

			local closest_d = radius+1
			local closest_name

			for i, obj in ipairs(minetest.get_objects_inside_radius(block_pos, radius)) do
				-- 0.4.x compatibility:
				--if obj:get_player_name() ~= "" then

				-- 5.0.0+ method:
				if minetest.is_player(obj) then
					local distance = vector.distance(obj:get_pos(), block_pos)
					if distance < closest_d then
						closest_d = distance
						closest_name = obj:get_player_name()
					end
				end
			end

			-- if 'closest_name' is nil, there's no player inside that radius
			return closest_name
		end

		-- 10 should be the max possible interaction distance
		local name = find_nearest_player(pos, 10)

		local last_index = 0
		local last_line = ""
		local last_color = ""

		if name ~= nil then
			name = string.lower(name)
			if last_set_by[name] ~= nil then
				last_index = last_set_by[name].index + 5
				last_line = last_set_by[name].line
				last_color = last_set_by[name].color
			else
				last_set_by[name] = {}
			end

			last_set_by[name].index = last_index
			last_set_by[name].line = last_line
			last_set_by[name].color = last_color
		end

		meta:set_string("station", "")
		meta:set_string("line", last_line)
		meta:set_int("index", last_index)
		meta:set_string("color", last_color)

		update_formspec(meta)
	end,

	on_receive_fields = function(pos, formname, fields, sender)

		if not mapserver.can_interact(pos, sender) then
			return
		end

		local meta = minetest.get_meta(pos)
		local name = string.lower(sender:get_player_name())

		if fields.save then
			if last_set_by[name] == nil then
				last_set_by[name] = {}
			end

			local index = tonumber(fields.index)
			if index ~= nil then
				index = index
			end

			meta:set_string("color", fields.color)
			meta:set_string("line", fields.line)
			meta:set_string("station", fields.station)
			meta:set_int("index", index)

			last_set_by[name].color = fields.color
			last_set_by[name].line = fields.line
			last_set_by[name].station = fields.station
			last_set_by[name].index = index
		end

		update_formspec(meta)
	end
})

if mapserver.enable_crafting then
	minetest.register_craft({
	    output = 'mapserver:train',
	    recipe = {
				{"", moditems.steel_ingot, ""},
				{moditems.paper, moditems.goldblock, moditems.paper},
				{"", moditems.glass, ""}
			}
	})
end
