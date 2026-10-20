-- the ready up screen builds the weapons of the other players from their outfit, which knows no custom skins.
-- tell WeaponFactoryManager:assemble_from_blueprint whose weapon it assembles, to apply the skin that player told us about.
local spawn_weapon_original = ReadyUpGui._spawn_weapon
---@diagnostic disable-next-line: duplicate-set-field
function ReadyUpGui:_spawn_weapon(params)
	SkinLib._ready_up_peer = params and params.peer
	-- never leave the peer behind, the next assembling would take it for its own
	local ok, err = pcall(spawn_weapon_original, self, params)
	SkinLib._ready_up_peer = nil
	if not ok then
		error(err, 0)
	end
end

-- skin textures are applied by NewRaycastWeaponBase, which the ready up screen never uses (it assembles the parts directly), so no skin with
-- textures shows up there. do what NewRaycastWeaponBase:apply_texture_switches does, for the parts that were just assembled.
Hooks:PostHook(ReadyUpGui, "_assemble_completed", "SkinLib.ReadyUpGui._assemble_completed", function(self, params, parts)
	local parts_tweak = tweak_data.weapon.factory.parts
	local weapon_base = {_parts = parts, _parts_texture_switches = {}}
	local first_person = SkinLib._ready_up_first_person and SkinLib._ready_up_first_person[params.peer:id()]
	for part_id in pairs(parts) do
		local texture_data = parts_tweak[part_id] and parts_tweak[part_id][first_person and "materials_fps" or "materials_tps"]
		if texture_data then
			NewRaycastWeaponBase.apply_modified_textures(weapon_base, part_id, texture_data)
		end
	end
end)
