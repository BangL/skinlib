local function bp_unpack(blueprint_string, factory_id)
	local factory = tweak_data.weapon.factory
	local index_table = string.split(blueprint_string, " ")
	local blueprint = {}
	local part_id

	for _, part_index in ipairs(index_table) do
		part_id = factory[factory_id].uses_parts[tonumber(part_index)]

		if part_id then
			table.insert(blueprint, part_id)
		end
	end

	return blueprint
end

local function bp_pack(blueprint, factory_id)
	local factory = tweak_data.weapon.factory
	local index_table = {}

	for i, part_id in ipairs(factory[factory_id] and factory[factory_id].uses_parts or {}) do
		index_table[part_id] = i
	end

	local s = ""

	for _, part_id in ipairs(blueprint) do
		if index_table[part_id] then
			s = s .. tostring(index_table[part_id]) .. " "
		else
			Application:error("[WeaponFactoryManager:blueprint_to_string] Part do not exist in weapon's uses_parts!", "factory_id", factory_id, "part_id", part_id)
		end
	end

	return s
end

---@diagnostic disable-next-line: duplicate-set-field
function PlayerInventory:_send_equipped_weapon(send_equipped_weapon_type)
	send_equipped_weapon_type = send_equipped_weapon_type or PlayerInventory.SEND_WEAPON_TYPE_PLAYER_PRIMARY_SECONDARY

	local equipped_weapon_category_id = self:equipped_selection()
	local equipped_weapon_identifier = self:equipped_unit():base():get_name_id()

	if equipped_weapon_category_id == WeaponInventoryManager.BM_CATEGORY_GRENADES_ID or equipped_weapon_category_id == WeaponInventoryManager.BM_CATEGORY_MELEE_ID then
		send_equipped_weapon_type = PlayerInventory.SEND_WEAPON_TYPE_PLAYER_MELEE_GRENADE
	end

	if send_equipped_weapon_type == PlayerInventory.SEND_WEAPON_TYPE_TEAMAI_COPS then
		for i, weap_name in ipairs(tweak_data.character.weap_unit_names) do
			if weap_name == self:equipped_unit():name() then
				equipped_weapon_identifier = tostring(i)
			end
		end
	end

	local blueprint_string = self:equipped_unit():base().blueprint_to_string and self:equipped_unit():base():blueprint_to_string() or ""
	local cosmetics_id = self:equipped_unit():base().get_cosmetics_id and self:equipped_unit():base():get_cosmetics_id()

	-- throwables: only sync the id of the custom skin, peers without it fall back to vanilla
	if send_equipped_weapon_type == PlayerInventory.SEND_WEAPON_TYPE_PLAYER_MELEE_GRENADE then
		cosmetics_id = SkinLib.get_applied_custom_skin(equipped_weapon_identifier)
	end

	-- fix custom skins resulting in broken weapon for peers
	local factory_id = SkinLib.weaponid2factoryid(equipped_weapon_identifier)
	if factory_id ~= false  and factory_id ~= nil and blueprint_string ~= "" then
		blueprint_string = bp_pack(SkinLib._clean_blueprint(bp_unpack(blueprint_string, factory_id), factory_id), factory_id)
		-- sync custom skin id, so peers with the same skin can apply it
		if send_equipped_weapon_type == PlayerInventory.SEND_WEAPON_TYPE_PLAYER_PRIMARY_SECONDARY and not cosmetics_id then
			local skin_id = SkinLib.get_applied_custom_skin(factory_id)
			cosmetics_id = skin_id and SkinLib.make_cosmetics_string(skin_id)
		end
	end

	self._unit:network():send("set_equipped_weapon", send_equipped_weapon_type, equipped_weapon_category_id, equipped_weapon_identifier, blueprint_string, cosmetics_id)
end


-- same for late join sync
Hooks:PostHook(PlayerInventory, "save", "SkinLib.PlayerInventory.save", function(self, data)
	if not (self._equipped_selection and data.blueprint_string and data.equipped_weapon_index) then
		return
	end

	local factory_id = self:equipped_unit():base()._factory_id
	if not (factory_id and SkinLib.factoryid2weaponid(factory_id)) then
		return
	end

	data.blueprint_string = bp_pack(SkinLib._clean_blueprint(bp_unpack(data.blueprint_string, factory_id), factory_id), factory_id)

	local skin_id = SkinLib.get_applied_custom_skin(factory_id)
	if skin_id then
		data.cosmetics_string = SkinLib.make_cosmetics_string(skin_id)
	end
end)

-- vanilla only applies skins to throwables, so swap the melee units of the applied skin
local set_melee_weapon = PlayerInventory.set_melee_weapon
function PlayerInventory:set_melee_weapon(melee_weapon_id, ...)
	local _, skin = managers.weapon_inventory:get_applied_weapon_skin(melee_weapon_id)
	local units = skin and skin.replaces_units
	if not units then
		return set_melee_weapon(self, melee_weapon_id, ...)
	end

	local blackmarket = managers.blackmarket
	local get_melee_weapon_data = blackmarket.get_melee_weapon_data
	blackmarket.get_melee_weapon_data = function(this, ...)
		local data = get_melee_weapon_data(this, ...)
		if data then
			data = clone(data)
			data.unit = units.unit or data.unit
			data.third_unit = units.third_unit or data.third_unit
		end
		return data
	end

	local ok, err = blt.pcall(set_melee_weapon, self, melee_weapon_id, ...)
	blackmarket.get_melee_weapon_data = get_melee_weapon_data
	if not ok then
		error(err)
	end
end

-- melee skin units can be turned and moved in the hand
Hooks:PostHook(PlayerInventory, "_link_weapon", "SkinLib.PlayerInventory._link_weapon", function(self, unit)
	local base = alive(unit) and unit:base()
	local melee_id = base and base.get_name_id and base:get_name_id()
	local _, skin = managers.weapon_inventory:get_applied_weapon_skin(melee_id)
	if not (skin and skin.custom and (skin.fps_rotation or skin.fps_offset)) then
		return
	end

	local obj = unit:orientation_object()
	if skin.fps_rotation then
		local r = skin.fps_rotation
		obj:set_local_rotation(Rotation(r[1], r[2], r[3]))
	end
	if skin.fps_offset then
		local o = skin.fps_offset
		obj:set_local_position(Vector3(o[1], o[2], o[3]))
	end
	unit:set_moving()
end)
