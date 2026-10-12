SkinLibMenu = SkinLibMenu or class(BLTMenu)

function SkinLibMenu:Init(root)
    SkinLib.Load()

    self:Title({
        text = "menu_skinlib_title"
    })
    self:AutoBindNamedControlsBegin()

    self:Toggle({
        name = "Debug",
        text = "menu_skinlib_debug",
        value = SkinLib.settings.Debug,
        callback = callback(self, self, "change_clbk", {type = "Debug", toogle = true}),
        desc = "menu_skinlib_debug_desc",
        auto_select_on_hover = true
    })

    self:Toggle({
        name = "ForceCosmeticParts",
        text = "menu_skinlib_forcecosmeticparts",
        value = SkinLib.settings.ForceCosmeticParts,
        callback = callback(self, self, "change_clbk", {type = "ForceCosmeticParts", toogle = true}),
        desc = "menu_skinlib_forcecosmeticparts_desc",
        auto_select_on_hover = true
    })

    self:Toggle({
        name = "CustomHudIcon",
        text = "menu_skinlib_customhudicon",
        value = SkinLib.settings.CustomHudIcon,
        callback = callback(self, self, "change_clbk", {type = "CustomHudIcon", toogle = true}),
        desc = "menu_skinlib_customhudicon_desc",
        auto_select_on_hover = true
    })

    self:Toggle({
        name = "ExpandWeaponRotation",
        text = "menu_skinlib_expandweaponrotation",
        value = SkinLib.settings.ExpandWeaponRotation,
        callback = callback(self, self, "change_clbk", {type = "ExpandWeaponRotation", toogle = true}),
        desc = "menu_skinlib_expandweaponrotation_desc",
        auto_select_on_hover = true
    })

    self:AutoBindNamedControlsEnd()

    self:LongRoundedButton2({
		name = "reset",
		text = "menu_skinlib_reset",
		callback = callback(self, self, "Reset"),
		ignore_align = true,
		y = 832,
		x = 1472
	})
end

function SkinLibMenu:Close()
    SkinLib.Save()
end

function SkinLibMenu:Reset(value, item)
	QuickMenu:new(
		managers.localization:text("menu_skinlib_reset"),
		managers.localization:text("menu_skinlib_reset_confirm"),
		{
			[1] = {
				text = managers.localization:text("dialog_no"),
				is_cancel_button = true,
			},
			[2] = {
				text = managers.localization:text("dialog_yes"),
				callback = function()
                    SkinLib.settings = clone(SkinLib.default_settings)
                    SkinLib.Save()
                    self:ReloadMenu()
				end,
			},
		},
		true
	)
end

function SkinLibMenu:change_clbk(custom, value, item)
    if custom.toogle then
        SkinLib.settings[custom.type] = value == true
    else
        SkinLib.settings[custom.type] = value
    end
end

Hooks:Add("MenuComponentManagerInitialize", "SkinLib.MenuComponentManagerInitialize", function(self)
	RaidMenuHelper:CreateMenu({
		name = "SkinLib_Menu",
		name_id = "menu_skinlib_title",
		inject_list = "blt_options",
        icon = "rwd_weapon",
		class = SkinLibMenu
	})
end)
