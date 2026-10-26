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
---@diagnostic disable-next-line: param-type-mismatch
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

-- decal and sounds are read from the tweak data of the melee weapon, so it carries the ones of the skin while it is applied
local melee_originals = {}
local function apply_melee_overrides(melee_weapon_id, skin)
	local melee = tweak_data.blackmarket.melee_weapons[melee_weapon_id]
	if not melee then
		return
	end

	local original = melee_originals[melee_weapon_id]
	if original then
		melee.decal_effect = original.decal_effect
		melee.sounds = original.sounds
	end

	if not (skin and skin.custom and (skin.melee_decal_effect ~= nil or skin.melee_sounds)) then
		return
	end

	melee_originals[melee_weapon_id] = original or { decal_effect = melee.decal_effect, sounds = melee.sounds }

	if skin.melee_decal_effect ~= nil then
		melee.decal_effect = skin.melee_decal_effect or nil
	end
	if skin.melee_sounds then
		melee.sounds = type(skin.melee_sounds) == "string" and tweak_data.blackmarket.melee_sounds[skin.melee_sounds] or skin.melee_sounds
	end
end

-- vanilla only applies skins to throwables, so swap the melee units of the applied skin
local set_melee_weapon = PlayerInventory.set_melee_weapon
---@diagnostic disable-next-line: duplicate-set-field
function PlayerInventory:set_melee_weapon(melee_weapon_id, is_npc, ...)
	-- husks also get here (is_npc), the applied skin is ours, not theirs
	local _, skin = managers.weapon_inventory:get_applied_weapon_skin(melee_weapon_id)
	if not is_npc then
		apply_melee_overrides(melee_weapon_id, skin)
	end
	local units = not is_npc and skin and skin.replaces_units
	if not units then
		return set_melee_weapon(self, melee_weapon_id, is_npc, ...)
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

	local ok, err = blt.pcall(set_melee_weapon, self, melee_weapon_id, is_npc, ...)
	blackmarket.get_melee_weapon_data = get_melee_weapon_data
	if not ok then
		error(err)
	end
end

-- the custom skin of a weapon unit that was just linked to a place, and which transform of it to use:
-- local player = applied skin (first person), husk = what the peer synced (third person)
local function get_linked_skin(self, unit)
	local base = unit:base()
	local is_grenade = base and base.set_thrower_unit ~= nil
	local name_id = base and (is_grenade and self.equipped_grenade or base.get_name_id and base:get_name_id())
	if not (name_id or is_grenade and self._peer_weapons) then
		return
	end

	local skin, prefix
	if not self._peer_weapons then
		local _
		_, skin = managers.weapon_inventory:get_applied_weapon_skin(name_id)
		prefix = "fps"
	else
		local skin_id
		if is_grenade then
			skin_id = self._skinlib_grenade_skin
		elseif tweak_data.blackmarket.melee_weapons[name_id] then
			skin_id = self._skinlib_melee_skin
		elseif base._factory_id then
			local peer = self._unit:network():peer()
			skin_id = peer and SkinLib.get_synced_custom_skin(SkinLib.get_peer_skin(peer:id(), base._factory_id), base._factory_id)
		end
		skin = skin_id and tweak_data.weapon.weapon_skins[skin_id]
		prefix = "tps"
	end

	if skin and skin.custom and (skin[prefix .. "_rotation"] or skin[prefix .. "_offset"]) then
		return skin, prefix
	end
end

-- skins can turn and move the unit in the hand (fps_/tps_rotation and _offset), anywhere else it keeps its own transform
Hooks:PostHook(PlayerInventory, "_link_weapon", "SkinLib.PlayerInventory._link_weapon", function(self, unit, align_place)
	if not alive(unit) then
		return
	end

	local obj = unit:orientation_object()
	local base = unit:base()
	local skin, prefix
	if align_place == self._align_places.right_hand then
		skin, prefix = get_linked_skin(self, unit)
	end

	if not skin then
		local orig = base and base._skinlib_orig_transform
		if orig then
			obj:set_local_rotation(orig.rotation)
			obj:set_local_position(orig.position)
			unit:set_moving()
		end
		return
	end

	if not base._skinlib_orig_transform then
		base._skinlib_orig_transform = {
			rotation = obj:local_rotation(),
			position = obj:local_position(),
		}
	end

	local r = skin[prefix .. "_rotation"]
	if r then
		obj:set_local_rotation(base._skinlib_orig_transform.rotation * Rotation(r[1], r[2], r[3]))
	end
	local o = skin[prefix .. "_offset"]
	if o then
		obj:set_local_position(base._skinlib_orig_transform.position + Vector3(o[1], o[2], o[3]))
	end
	unit:set_moving()
end)
