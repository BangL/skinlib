-- peers without skinlib crash in the loot screen when they get a custom skin id (tweak_data.weapon.weapon_skins[id] == nil).
-- so never sync custom skin ids; send a vanilla skin of the same weapon instead.
local function vanilla_fallback(weapon_id)
	local any
	for id, skin in pairs(tweak_data.weapon.weapon_skins) do
		if not skin.custom then
			if skin.weapon_id == weapon_id then
				return id
			end
			any = any or id
		end
	end
	return any
end

local give_weapon_skin_original = LootDropManager._give_weapon_skin_to_player
---@diagnostic disable-next-line: duplicate-set-field
function LootDropManager:_give_weapon_skin_to_player(drop)
	local session = managers.network and managers.network:session()
	if not session then
		return give_weapon_skin_original(self, drop)
	end

	local send_original = session.send_to_peers_synched
	local had_own = rawget(session, "send_to_peers_synched") ~= nil
	session.send_to_peers_synched = function(s, func_name, reward_type, skin_id, ...)
		if func_name == "sync_loot_to_peers" and reward_type == LootDropTweakData.REWARD_WEAPON_SKIN then
			local skin = tweak_data.weapon.weapon_skins[skin_id]
			if skin and skin.custom then
				skin_id = vanilla_fallback(skin.weapon_id) or skin_id
			end
		end
		return send_original(s, func_name, reward_type, skin_id, ...)
	end

	-- always restore the session
	local ok, res = pcall(give_weapon_skin_original, self, drop)
	session.send_to_peers_synched = had_own and send_original or nil
	if not ok then
		error(res, 0)
	end
	return res
end

-- unknown skin ids from other peers (e.g. other mods) would crash the loot screen too
local on_loot_for_peer_original = LootDropManager.on_loot_dropped_for_peer
---@diagnostic disable-next-line: duplicate-set-field
function LootDropManager:on_loot_dropped_for_peer(loot_type, name, value, peer_id)
	if loot_type == LootDropTweakData.REWARD_WEAPON_SKIN and not tweak_data.weapon.weapon_skins[name] then
		log("[SkinLib] unknown skin drop '" .. tostring(name) .. "' from peer " .. tostring(peer_id) .. ", using fallback")
		name = vanilla_fallback() or name
	end
	return on_loot_for_peer_original(self, loot_type, name, value, peer_id)
end
