local roll_clamp = 90

local function roll_unit(obj, roll_delta)
    if not obj._unit or not alive(obj._unit) then
        return
    end

    local rotation = obj._unit:rotation()
    local yaw = rotation:yaw()
    local pitch = rotation:pitch()
    local roll = rotation:roll()

    roll_delta = roll_delta or 0
---@diagnostic disable-next-line: undefined-field
    roll = math.clamp(roll + roll_delta, -roll_clamp, roll_clamp)
    obj._yaw_delta = obj._yaw_delta or 0
    yaw = yaw + obj._yaw_delta

    local rot_out = Rotation(yaw, pitch, roll)
    local rotated_offset = obj._unit_center_offset:rotate_with(rot_out)

    obj:_place_unit(obj._original_position - rotated_offset + obj._unit_screen_adjust_offset, rot_out)
end

Hooks:PostHook(RaidGUIControlRotateUnit, "on_mouse_moved", "SkinLib.RaidGUIControlRotateUnit.on_mouse moved", function (self, o, x, y)
	if SkinLib.settings.ExpandWeaponRotation then
		if not self._dragging or not self._unit or not alive(self._unit) then
			return
		end

		if not self._last_y then
			self._last_y = y
			self._last_sound_click_roll = self._unit:rotation():roll()

			return
		end

		roll_unit(self, (y - self._last_y) / 4)

		self._last_y = y

		if self._params.sound_click_every_n_degrees and
		math.abs(self._unit:rotation():roll() - self._last_sound_click_roll) > self._params.sound_click_every_n_degrees then
			if not self._params.rotation_click_sound then
				debug_pause("Rotation click sound not set for rotate unit control " .. tostring(self._name))

				return
			end

			managers.menu_component:post_event(self._params.rotation_click_sound)

			self._last_sound_click_roll = self._unit:rotation():roll()
		end
	end
end)

Hooks:PostHook(RaidGUIControlRotateUnit, "update", "SkinLib.RaidGUIControlRotateUnit.update", function (self, t, dt)
	if SkinLib.settings.ExpandWeaponRotation then
		local menu_controller = managers.menu:get_controller()

		if not managers.menu:is_pc_controller() and menu_controller then
			roll_unit(self, menu_controller:get_input_axis("look").y * 0.4)
		end
	end
end)

Hooks:PostHook(RaidGUIControlRotateUnit, "_rotate_unit_by", "SkinLib.RaidGUIControlRotateUnit._rotate_unit_by", function (self, yaw_delta)
    self._yaw_delta = yaw_delta
end)

-- a new drag starts fresh, else the first move jumps by the distance to where the last drag ended
Hooks:PostHook(RaidGUIControlRotateUnit, "on_mouse_pressed", "SkinLib.RaidGUIControlRotateUnit.on_mouse_pressed", function (self)
    self._last_y = nil
    self._last_sound_click_roll = nil
end)
