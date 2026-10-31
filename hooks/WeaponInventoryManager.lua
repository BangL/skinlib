Hooks:PostHook(WeaponInventoryManager, "setup", "SkinLib.WeaponInventoryManager.setup", function (self)
	SkinLib.Load_owned_skins()
	-- add unlocked skins from skinlib
	for skin_id, gold_price in pairs(SkinLib._owned_skins) do
		local tweak = tweak_data.weapon.weapon_skins[skin_id]
		if tweak then
			if SkinLib.debug() then
				log("[SkinLib] loaded custom owned_skin id: " .. skin_id)
			end
			self._owned_skins[skin_id] = gold_price
		end
	end
end)

-- hotfix to avoid crashes when unlocked skin is not in tweak_data, will be fixed in next game update

---@diagnostic disable-next-line: duplicate-set-field
function WeaponInventoryManager:load_profile_slot(data)
	self:setup()

	local state = data.WeaponInventoryManager

	if not state then
		return
	end

	self._weapons[WeaponInventoryManager.CATEGORY_NAME_MELEE] = state.melee_weapons

	for index, melee_weapon_data in ipairs(tweak_data.weapon_inventory.weapon_melee_index) do
		local weapon_id = melee_weapon_data.weapon_id

		if not self._weapons.melee_weapons[weapon_id] then
			self._weapons.melee_weapons[weapon_id] = {
				default = melee_weapon_data.default,
				droppable = melee_weapon_data.droppable,
				is_challenge_reward = melee_weapon_data.is_challenge_reward,
				owned = true,
				redeemed_xp = melee_weapon_data.redeemed_xp,
				slot = melee_weapon_data.slot,
				unlocked = false,
			}

			managers.savefile:set_resave_required()
		end
	end

	local unlocked_melee_weapons = tweak_data.dlc:get_unlocked_melee_weapons()
	local locked_melee_weapons = tweak_data.dlc:get_locked_melee_weapons()

	for weapon_id, melee_weapon in pairs(self._weapons.melee_weapons) do
		local weapon_tweaks = tweak_data.blackmarket.melee_weapons[weapon_id]

		if weapon_tweaks.dlc then
			if unlocked_melee_weapons[weapon_id] then
				melee_weapon.unlocked = true
				melee_weapon.owned = true
			elseif locked_melee_weapons[weapon_id] then
				melee_weapon.unlocked = false
				melee_weapon.owned = false
			end
		end
	end

	self._owned_skins = state.owned_skins or {}
	local save_dirty = false

	for skin_id, gold_price in pairs(self._owned_skins) do
		if SkinLib.debug() then
			log("[SkinLib] loaded vanilla owned_skin id: ".. skin_id)
		end
		local tweak = tweak_data.weapon.weapon_skins[skin_id]
		if tweak and tweak.custom then
			-- migrate to new save system
			if SkinLib.debug() then
				log("[SkinLib] migrate custom skin to new save system id: ".. skin_id)
			end
			SkinLib.migrate_owned_skin(skin_id, tweak)
			-- remove from game save
			self._owned_skins[skin_id] = nil
			save_dirty = true
		end
		-- fix crash for unknown skins
		if not tweak then
			-- self._owned_skins = nil
			-- keep ownership in the skinlib save, e.g. for custom skins whose mod is not loaded right now
			SkinLib.migrate_owned_skin(skin_id, { gold_price = gold_price })
            self._owned_skins[skin_id] = nil
			save_dirty = true
		end
	end

	if save_dirty then
		SkinLib.Save_owned_skins()
		managers.savefile:set_resave_required()
	end

	-- read unlocked skins from skinlib due to migration from old skinlib save system
	for skin_id, gold_price in pairs(SkinLib._owned_skins) do
		local tweak = tweak_data.weapon.weapon_skins[skin_id]
		if tweak then
			if SkinLib.debug() then
				log("[SkinLib] loaded custom owned_skin id: " .. skin_id)
			end
			self._owned_skins[skin_id] = gold_price
		end
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function WeaponInventoryManager:save_profile_slot(data)
	SkinLib.Load_owned_skins()
	local state = {
		melee_weapons = self._weapons[WeaponInventoryManager.CATEGORY_NAME_MELEE],
		owned_skins = self._owned_skins,
		version_account_wide = self.version_account_wide,
	}

	-- SkinLib skins from vanilla save data
	local owned_skins = {}
	for skin_id, price in pairs(self._owned_skins) do
		local tweak = tweak_data.weapon.weapon_skins[skin_id]
		if tweak and tweak.custom then
			-- migrate to new save system
			SkinLib.migrate_owned_skin(skin_id, tweak)
			-- remove from game save
			--self._owned_skins[skin_id] = nil
		elseif tweak then
			owned_skins[skin_id] = price
		end
	end

	if SkinLib.Save_owned_skins() then
		state.owned_skins = owned_skins
	end
	data.WeaponInventoryManager = state
end
