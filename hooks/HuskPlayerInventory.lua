-- remember the synced skin id, as the original discards it for primary/secondary weapons.
-- for throwables, drop ids we can't use (unknown skin, wrong item, missing unit), so vanilla falls back to the default unit.
local synch_equipped_weapon_original = HuskPlayerInventory.synch_equipped_weapon
---@diagnostic disable-next-line: duplicate-set-field
function HuskPlayerInventory:synch_equipped_weapon(send_equipped_weapon_type, equipped_weapon_category_id, equipped_weapon_identifier, blueprint_string, cosmetics_string, peer)
	self._skinlib_cosmetics_string = nil

	if send_equipped_weapon_type == PlayerInventory.SEND_WEAPON_TYPE_PLAYER_PRIMARY_SECONDARY then
		self._skinlib_cosmetics_string = cosmetics_string
	elseif send_equipped_weapon_type == PlayerInventory.SEND_WEAPON_TYPE_PLAYER_MELEE_GRENADE then
		local skin = tweak_data.weapon.weapon_skins[cosmetics_string]
		if skin and skin.custom then
			local key = equipped_weapon_category_id == WeaponInventoryManager.BM_CATEGORY_GRENADES_ID and "unit_dummy" or "third_unit"
			if skin.weapon_id ~= equipped_weapon_identifier or not (skin.replaces_units and skin.replaces_units[key]) then
				cosmetics_string = nil
			end
		end
	end

	return synch_equipped_weapon_original(self, send_equipped_weapon_type, equipped_weapon_category_id, equipped_weapon_identifier, blueprint_string, cosmetics_string, peer)
end

-- late join sync
Hooks:PreHook(HuskPlayerInventory, "_clbk_weapon_add", "SkinLib.HuskPlayerInventory._clbk_weapon_add", function(self, data)
	self._skinlib_cosmetics_string = data and data.cosmetics_string
end)

local add_unit_by_factory_name_original = HuskPlayerInventory.add_unit_by_factory_name
---@diagnostic disable-next-line: duplicate-set-field
function HuskPlayerInventory:add_unit_by_factory_name(factory_name, equip, instant, blueprint_string, cosmetics_string)
	local synced = self._skinlib_cosmetics_string
	self._skinlib_cosmetics_string = nil

	local skin_id = SkinLib.get_synced_custom_skin(synced, factory_name)
	if not skin_id then
		return add_unit_by_factory_name_original(self, factory_name, equip, instant, blueprint_string, cosmetics_string)
	end

	local blueprint = managers.weapon_factory:unpack_blueprint_from_string(factory_name, blueprint_string)
	blueprint = managers.weapon_factory:modify_skin_blueprint(factory_name, blueprint, skin_id)
	blueprint = SkinLib.apply_force_cosmetic_parts(blueprint, tweak_data.weapon.weapon_skins[skin_id])

	return self:add_unit_by_factory_blueprint(factory_name, equip, instant, blueprint)
end
