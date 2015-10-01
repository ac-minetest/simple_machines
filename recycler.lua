
local recycler_process = function(pos) 
	
	local node = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name;
	if node ~= "default:furnace_active" then return end
	local meta = minetest.get_meta(pos);local inv = meta:get_inventory();
	local stack = inv:get_stack("src",1);
		if stack:is_empty() then return end; -- nothing to do
	--minetest.chat_send_all("listname " .. listname .. " item " ..stack:to_string());
		local itemlist = minetest.get_craft_recipe( stack:to_string() ).items;
		
		--minetest.chat_send_all("will drop " .. dump(  minetest.get_craft_recipe( stack:to_string() )  ));
		
		if not itemlist then itemlist = {stack:to_string()} end
		local output = minetest.get_craft_recipe( stack:to_string() ).output or "";
		if string.find(output," ") then 
			local par = string.find(output," ");
			if (tonumber(string.sub(output, par)) or 0)>1 then	itemlist = {stack:to_string()} end
		end -- cause  if for example output is "default:mese 9" we dont want to get meseblock from just 1 mese..
		

		--empty dst inventory before proceeding
		-- local size = inv:get_size("dst"); 
		-- for i=1,size do
			-- inv:set_stack("dst", i, ItemStack(""));
		-- end
		
		for _,  v in pairs(itemlist) do
			if math.random(1, 4)<=3 then -- probability 3/4 = 75%
				if not string.find(v,"group") then -- dont add if item described with group
					local par = string.find(v,"\"") or 0;
					--minetest.chat_send_all(" par location at " .. par .. " item ".. v);
					if inv:room_for_item("dst", ItemStack(v)) then -- can item be put in
						inv:add_item("dst",ItemStack(v));
					else return
					end
				end
			end
		end
	
		--empty src inventory
		size = inv:get_size("src"); 
		for i=1,size do
			inv:set_stack("src", i, ItemStack(""));
		end
	
end

minetest.register_node("basic_machines:recycler", {
	description = "Recycler",
	tiles = {"recycler.png"},
	groups = {oddly_breakable_by_hand=2,mesecon_effector_on = 1},
	sounds = default.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos);
		meta:set_string("infotext", "Recycler: put one item in it (src) and obtain 75% of raw materials (dst). To operate it must sit on top of working furnace.")
		meta:set_string("owner", placer:get_player_name());
		
		local inv = meta:get_inventory();inv:set_size("src", 1);inv:set_size("dst",9);
		--inv:set_stack("mode", 1, ItemStack("default:coal_lump"))
	end,
	
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if meta:get_string("owner")~=player:get_player_name() and not privs.privs then return end -- only owner can interact with recycler
		
		minetest.log("OK!");
		local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z 
		local form  = 
		"size[8,8]" ..  -- width, height
		--"size[6,10]" ..  -- width, height
		"label[0,0;IN] label[1,0;OUT]"..
		"list["..list_name..";src;0.,0.5;1,1;]".. 
		"list["..list_name..";dst;1.,0.5;3,3;]"..
		"list[current_player;main;0,4;8,4;]"
		;
		
		--"field[0.25,4.5;2,1;mode;mode;"..mode.."]";
		
		minetest.show_formspec(player:get_player_name(), "basic_machines:recycler_"..minetest.pos_to_string(pos), form)
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname ~= "src" then return 0 end
		return 1
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname ~= "dst" then return 0 end
		return stack:get_count();
	end,
	
	on_metadata_inventory_put = function(pos, listname, index, stack, player) 
		recycler_process(pos);
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0		
	end,
	
	mesecons = {effector = { 
		action_on = function (pos, node,ttl) 
		if type(ttl)~="number" then ttl = 1 end
		if ttl<0 then return end -- machines_TTL prevents infinite recursion
		recycler_process(pos);
	end
	}
	},
	
	
})


-- CRAFTS

minetest.register_craft({
	output = "basic_machines:recycler",
	recipe = {
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"},
		{"default:mese_crystal", "default:diamondblock","default:mese_crystal"},
		{"default:mese_crystal", "default:mese_crystal","default:mese_crystal"}
	}
})