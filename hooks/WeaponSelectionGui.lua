Hooks:PostHook(WeaponSelectionGui, "_on_skins_button_click", "SkinLib.WeaponSelectionGui._on_skins_button_click", function (self)
    self._SL_weapon_id = self._selected_weapon_id -- store _selected_weapon_id now as it is changed after _on_apply_weapon_skin
end)

Hooks:PostHook(WeaponSelectionGui, "_on_apply_weapon_skin", "SkinLib.WeaponSelectionGui._on_apply_weapon_skin", function (self, item)
    if SkinLib.settings.CustomHudIcon then
        local primary = managers.weapon_inventory:get_equipped_primary_weapon_id()
        local secondary = managers.weapon_inventory:get_equipped_secondary_weapon_id()
        local grenade = managers.weapon_inventory:get_equipped_grenade_id()
        local weapon_id = tweak_data.weapon.weapon_skins[item.skin_id] and tweak_data.weapon.weapon_skins[item.skin_id].weapon_id or self._SL_weapon_id
        local slot = self._selected_weapon_category_id
        if weapon_id and (weapon_id == primary or weapon_id == secondary or weapon_id == grenade) then -- check for valid weapon_id and if weapon is equipped
            if tweak_data.weapon.weapon_skins[item.skin_id] and tweak_data.weapon.weapon_skins[item.skin_id].hud_icon then -- check for custom hud icon and apply
                managers.hud._weapon_panels[slot]._icon:set_image(
                    type(tweak_data.weapon.weapon_skins[item.skin_id].hud_icon) == "table" and tweak_data.weapon.weapon_skins[item.skin_id].hud_icon.texture or tweak_data.weapon.weapon_skins[item.skin_id].hud_icon,
                    type(tweak_data.weapon.weapon_skins[item.skin_id].hud_icon) == "table" and tweak_data.weapon.weapon_skins[item.skin_id].hud_icon.texture_rect or nil
                )
            else
                if tweak_data.weapon[weapon_id] and tweak_data.weapon[weapon_id].hud.icon then -- use vanilla icon
                    local icon = tweak_data.gui:get_full_gui_data(tweak_data.weapon[weapon_id].hud.icon)
                    managers.hud._weapon_panels[slot]._icon:set_image(icon.texture)
---@diagnostic disable-next-line: deprecated
                    managers.hud._weapon_panels[slot]._icon:set_texture_rect(unpack(icon.texture_rect))
                end
            end
        end
    end
end)
