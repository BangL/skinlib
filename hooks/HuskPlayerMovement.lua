-- the melee item of the swing animation is spawned from the tweak data of the melee weapon of the peer, so give it the units of the skin the peer synced
local anim_cbk_spawn_melee_item = HuskPlayerMovement.anim_cbk_spawn_melee_item
---@diagnostic disable-next-line: duplicate-set-field
function HuskPlayerMovement:anim_cbk_spawn_melee_item(...)
	local skin_id = self._unit:inventory()._skinlib_melee_skin
	local skin = skin_id and tweak_data.weapon.weapon_skins[skin_id]
	local unit_name = skin and skin.custom and skin.replaces_units and skin.replaces_units.third_unit
	local melee = unit_name and tweak_data.blackmarket.melee_weapons[skin.weapon_id]
	if not melee then
		return anim_cbk_spawn_melee_item(self, ...)
	end

	local original = melee.third_unit
	melee.third_unit = unit_name
	local ok, err = blt.pcall(anim_cbk_spawn_melee_item, self, ...)
	melee.third_unit = original
	if not ok then
		error(err)
	end

	local item = self._melee_item_unit
	if alive(item) then
		local obj = item:orientation_object()
		if skin.tps_rotation then
			local r = skin.tps_rotation
			obj:set_local_rotation(obj:local_rotation() * Rotation(r[1], r[2], r[3]))
		end
		if skin.tps_offset then
			local o = skin.tps_offset
			obj:set_local_position(obj:local_position() + Vector3(o[1], o[2], o[3]))
		end
		item:set_moving()
	end
end
