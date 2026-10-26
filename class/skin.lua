_G.SL_Skin = _G.SL_Skin or class()


-- PRIVATE

function SL_Skin:init(skin_id, weapon_id)
    self._skin = {}
    self._skin.skin_id = skin_id
    self._skin.weapon_id = weapon_id
end

function SL_Skin:_to_tbl()
    return self._skin
end

function SL_Skin:_parts()
    return self._skin.parts
end

-- PUBLIC

---Sets name_id for skin
---@param name_id string
---@return table
function SL_Skin:set_name_id(name_id)
    if name_id then
        self._skin.name_id = name_id
    end
    return self
end

---Sets weapon_desc_id for skin
---@param w_desc_id string
---@return table
function SL_Skin:set_weapon_desc_id(w_desc_id)
    if w_desc_id then
        self._skin.weapon_desc_id = w_desc_id
    end
    return self
end

---Sets weapon_name_id for skin
---@param w_name_id string
---@return table
function SL_Skin:set_weapon_name_id(w_name_id)
    if w_name_id then
        self._skin.weapon_name_id = w_name_id
    end
    return self
end

---Sets gold price for skin
---@param price integer
---@return table
function SL_Skin:set_gold_price(price)
    if price then
        self._skin.gold_price = price
    end
    return self
end

---Sets if skin is droppable reward
---@param droppable boolean
---@return table
function SL_Skin:set_droppable(droppable)
    if type(droppable) == "boolean" then
        self._skin.droppable = droppable
    end
    return self
end

---Sets drop rarity for skin; Possible rarities: RARITY_COMMON, RARITY_UNCOMMON, RARITY_RARE
---@param rarity string
---@return table
function SL_Skin:set_rarity(rarity)
    if rarity then
        self._skin.rarity = rarity
    end
    return self
end

---Sets challenge data for unlocking skin
---@param challenge table
---@return table
function SL_Skin:set_challenge(challenge)
    if challenge then
        self._skin.challenge = challenge
    end
    return self
end

---Sets unit to replace
---@param base_unit string
---@param replace_unit string
---@return table
function SL_Skin:set_replaces_unit(base_unit, replace_unit)
    if not self._skin.replaces_units then
        self._skin.replaces_units = {}
    end
    if base_unit and replace_unit then
        self._skin.replaces_units[base_unit] = replace_unit
    end
    return self
end

---Sets multiple units to replace
---@param units table
---@return table
function SL_Skin:set_replaces_units(units)
    if units then
        for base, replace in pairs(units) do
            self:set_replaces_unit(base, replace)
        end
    end
    return self
end

---Adds part to skin, expects SL_Part instance
---@param part table
---@return table
function SL_Skin:add_part(part)
    if not self._skin.parts then
        self._skin.parts = {}
    end
    if not self._skin.replaces_parts then
        self._skin.replaces_parts = {}
    end
    if part._part_id and part._base_part then
        self._skin.replaces_parts[part:_base_part()] = part:_part_id()
    end
    table.insert(self._skin.parts, part)
    return self
end

---Adds multiple parts to skin, expects table of SL_Part instances
---@param parts table
---@return table
function SL_Skin:add_parts(parts)
    for _, part in ipairs(parts) do
        self:add_part(part)
    end
    return self
end

---Sets icon_large for skin, used in reward screen
---@param icon string
---@return table
function SL_Skin:set_icon_large(icon)
    if icon then
        self._skin.icon_large = icon
    end
    return self
end

---Sets hud_icon for skin
---@param icon string|table
---@return table
function SL_Skin:set_hud_icon(icon)
    if icon then
        self._skin.hud_icon = icon
    end
    return self
end

---Rotates the first person melee unit in the hand (melee skins with replaces_units)
---@param yaw number
---@param pitch number
---@param roll number
---@return table
function SL_Skin:set_fps_rotation(yaw, pitch, roll)
    self._skin.fps_rotation = {yaw or 0, pitch or 0, roll or 0}
    return self
end

---Moves the first person melee unit in the hand (melee skins with replaces_units)
---@param x number
---@param y number
---@param z number
---@return table
function SL_Skin:set_fps_offset(x, y, z)
    self._skin.fps_offset = {x or 0, y or 0, z or 0}
    return self
end

---Sets cosmetic parts to override with skin
---@param parts table
---@return table
function SL_Skin:set_force_cosmetic_parts(parts)
    if parts then
        self._skin.force_cosmetic_parts = parts
    end
    return self
end
