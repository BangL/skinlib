_G.SkinLib = _G.SkinLib or {}
SkinLib.path = ModPath
SkinLib.save_path = SavePath .. "SkinLib.json"
SkinLib._skins = {}
SkinLib._injected_skins = {}
SkinLib._parts = {}
SkinLib._injected_parts = {}
SkinLib._version = ModInstance and tostring(ModInstance:GetVersion()) or "0.0.0"
SkinLib.default_settings = {
    Debug = false,
    ForceCosmeticParts = true,
    CustomHudIcon = true,
    ExpandWeaponRotation = true,
}
SkinLib.settings = clone(SkinLib.default_settings)
SkinLib._owned_skins = SkinLib._owned_skins or {}
SkinLib._owned_skins_save_path = SavePath .. "SkinLib._owned_skins." .. (Steam:userid() or "0") ..".json"

SkinLib.weapon_tbl = {
    -- secondaries
    c96 = "wpn_fps_pis_c96", -- Mauser C96
    tt33 = "wpn_fps_pis_tt33", -- TT33
    georg = "wpn_fps_pis_georg", -- Luger
    webley = "wpn_fps_pis_webley", -- Webley revolver
    m1911 = "wpn_fps_pis_m1911", -- M1911
    welrod = "wpn_fps_pis_welrod", -- Welrod
    shotty = "wpn_fps_pis_shotty", -- Pocket Double-Barrel
    -- shotguns
    m1912 = "wpn_fps_sho_m1912", -- BAR
    ithaca = "wpn_fps_sho_ithaca", -- Ithaca
    browning = "wpn_fps_sho_browning", -- Browning Auto-5
    geco = "wpn_fps_sho_geco", -- Double barrel shotgun
    -- SMG
    sten = "wpn_fps_smg_sten", -- Sten SMG
    thompson = "wpn_fps_smg_thompson", -- Thompson SMG
    mp38 = "wpn_fps_smg_mp38", -- MP38
    sterling = "wpn_fps_smg_sterling", -- Sterling SMG
    -- assault rifle
    carbine = "wpn_fps_ass_carbine", -- M1 Carbine
    garand = "wpn_fps_ass_garand", -- M1 Garand
    mp44 = "wpn_fps_ass_mp44", -- MP44/STG44
    -- LMG
    m1918 = "wpn_fps_lmg_m1918", -- M1918 LMG/BAR
    dp28 = "wpn_fps_lmg_dp28", -- DP28
    bren = "wpn_fps_lmg_bren", -- Bren
    mg42 = "wpn_fps_lmg_mg42", -- MG42
    -- snipers
    m1903 = "wpn_fps_snp_m1903", -- M1903 Springfield
    kar_98k = "wpn_fps_snp_kar_98k", -- Mauser K98K
    lee_enfield = "wpn_fps_snp_lee_enfield", -- Lee-Enfield
    mosin = "wpn_fps_snp_mosin", -- Mosin-Nagant rifle
}
SkinLib.weapon_tbl_reversed = {}

-- fill weapon_tbl_reversed
for wid, fid in pairs(SkinLib.weapon_tbl) do
    SkinLib.weapon_tbl_reversed[fid] = wid
end

-- fix "Original" skin bug
dofile(ModPath .. "class/fix_original_skin.lua")

local ids = {
    texture = Idstring("texture"),
    unit = Idstring("unit")
}

-- PRIVATE

function SkinLib.Load()
    local file = io.open(SkinLib.save_path, "r")
	if file then
		local options = json.decode(file:read("*all"))
        file:close()
        if type(options) == "table" then
            for key, ops in pairs(options) do
                SkinLib.settings[key] = ops
            end
        end
	end
end

function SkinLib.Save()
	local file = io.open(SkinLib.save_path, "w+")
	if file then
		file:write(json.encode(SkinLib.settings))
		file:close()
	end
end

function SkinLib.Load_owned_skins()
    local file = io.open(SkinLib._owned_skins_save_path, "r")
	if file then
		local skins = json.decode(file:read("*all"))
        file:close()
        if type(skins) == "table" then
            for skin_id, price in pairs(skins) do
                SkinLib._owned_skins[skin_id] = price
            end
        end
	end
end

function SkinLib.Save_owned_skins()
	local file = io.open(SkinLib._owned_skins_save_path, "w+")
	if file then
		file:write(json.encode(SkinLib._owned_skins))
		file:close()
        return true
	end
end

function SkinLib.migrate_owned_skin(skin_id, data)
    local skin = SkinLib._owned_skins[skin_id]
    if not skin then
        SkinLib._owned_skins[skin_id] = data.gold_price or 0
    end
end

function SkinLib.debug()
    return SkinLib.settings.Debug
end

function SkinLib._is_skin_injected(skin_id)
    for _, id in pairs(SkinLib._injected_skins) do
        if id == skin_id then
            return true
        end
    end
    return false
end

function SkinLib._is_part_injected(part_id)
    for _, id in pairs(SkinLib._injected_parts) do
        if id == part_id then
            return true
        end
    end
    return false
end

function SkinLib._get_skins()
    return SkinLib._skins
end

function SkinLib._get_parts()
    return SkinLib._parts
end

function SkinLib._set_injected_skin(skin_id)
    table.insert(SkinLib._injected_skins, skin_id)
end

function SkinLib._set_injected_part(part_id)
    table.insert(SkinLib._injected_parts, part_id)
end

function SkinLib._add_skin(skin)
    SkinLib._skins[skin.id] = skin
end

function SkinLib._add_part(part)
    SkinLib._parts[part.id] = part
end

local function normalized_texture_name(path)
    local name = path and path:match("([^/]+)$")
    if not name then
        return nil
    end
    name = name:gsub("^wpn_fps_", ""):gsub("^wpn_third_", "")
    return name
end

---Third person materials for a part whose skin only comes with first person materials, built from the vanilla data of the
---base part in _fix_tbl: real material names, real third person folders and bump/material textures, only the diffuse
---texture of the skin is put in. A vanilla third person material belongs to the skin material whose vanilla diffuse has
---the same file name apart from the wpn_fps_/wpn_third_ prefix, else to the one with the matching name, else (one
---material on each side) to the only one. Materials without a match keep the vanilla textures.
---@param base_part string
---@param m_fps table skin first person materials, name -> textures
---@return table|nil materials nil if there is no vanilla data or nothing matched
function SkinLib._derive_tps_materials(base_part, m_fps)
    local fix = SkinLib._fix_tbl[base_part]
    if not (fix and fix.tps and next(fix.tps)) then
        return nil
    end

    local fps_by_diffuse = {}
    local fps_count = 0
    for name in pairs(m_fps) do
        fps_count = fps_count + 1
        local vanilla = fix.fps and fix.fps[name]
        local key = vanilla and normalized_texture_name(vanilla.diffuse_texture)
        if key then
            fps_by_diffuse[key] = name
        end
    end
    local tps_count = 0
    for _ in pairs(fix.tps) do
        tps_count = tps_count + 1
    end

    local derived = {}
    local matched = 0
    for tps_name, vanilla in pairs(fix.tps) do
        local fps_name = fps_by_diffuse[normalized_texture_name(vanilla.diffuse_texture)]
        if not fps_name then
            local same_name = tps_name:gsub("^wpn_third_", "wpn_fps_")
            if m_fps[same_name] then
                fps_name = same_name
            elseif fps_count == 1 and tps_count == 1 then
                fps_name = next(m_fps)
            end
        end
        local diffuse = fps_name and m_fps[fps_name].diffuse_texture
        if diffuse then
            derived[tps_name] = {
                bump_normal_texture = vanilla.bump_normal_texture,
                diffuse_texture = diffuse,
                material_texture = vanilla.material_texture,
                reflection_texture = vanilla.reflection_texture,
            }
            matched = matched + 1
        end
    end

    return matched > 0 and derived or nil
end

---A skin that uses the vanilla model has to name the vanilla third person materials, a typo (e.g. wpn_tps_* instead of
---wpn_third_*) would make the skin silently do nothing there. If exactly one given name is unknown and exactly one vanilla
---material is unused, the given material is meant for it: rename it (the textures stay).
---Parts with their own model, and parts _fix_tbl knows nothing about, are left alone.
---@param base_part string
---@param m_tps table skin third person materials, name -> textures, renamed in place
---@param unique_materials table list of material names, renamed in place
---@return string|nil old_name
---@return string|nil new_name
function SkinLib._fix_tps_material_name(base_part, m_tps, unique_materials)
    local fix = SkinLib._fix_tbl[base_part]
    if not (fix and fix.tps and next(fix.tps)) then
        return nil
    end

    local unknown, unused
    for name in pairs(m_tps) do
        if not fix.tps[name] then
            if unknown then
                return nil
            end
            unknown = name
        end
    end
    for name in pairs(fix.tps) do
        if not m_tps[name] then
            if unused then
                return nil
            end
            unused = name
        end
    end
    if not (unknown and unused) then
        return nil
    end

    m_tps[unused] = m_tps[unknown]
    m_tps[unknown] = nil
    for i, name in ipairs(unique_materials) do
        if name == unknown then
            unique_materials[i] = unused
        end
    end
    return unknown, unused
end

---Whether the vanilla third person part has materials at all (e.g. magazines of some weapons have none, so there is nothing to skin)
---@param base_part string
---@return boolean
function SkinLib._base_part_has_tps_materials(base_part)
    local fix = SkinLib._fix_tbl[base_part]
    local tps = fix and fix.tps or tweak_data.weapon.factory.parts[base_part].materials_tps
    return tps ~= nil and next(tps) ~= nil
end

---Whether a custom skin has parts without third person materials of their own (they use the first person ones)
---@param skin_id string
---@return boolean
function SkinLib.skin_lacks_tps(skin_id)
    local skin = tweak_data.weapon.weapon_skins[skin_id]
    if not (skin and skin.custom) then
        return false
    end
    for _, part_id in pairs(skin.replaces_parts or {}) do
        local part = tweak_data.weapon.factory.parts[part_id]
        if part and part.custom and part.materials_fps and next(part.materials_fps) and not part.tps_provided then
            return true
        end
    end
    return false
end

function SkinLib._add_unique_material(unique_material, material)
    local inserted = false
    for _, m in ipairs(unique_material) do
        if m == material then
            inserted = true
        end
    end
    if not inserted then
        table.insert(unique_material, material)
    end
    return unique_material
end

function SkinLib._clean_blueprint(blueprint, factory_id)
    local new_blueprint = {}
    local factory = tweak_data.weapon.factory

    for _, part_id in pairs(blueprint) do
        local part = factory.parts[part_id]
        if part then
            if part.custom then
                local fac = factory[factory_id]
                if fac and part.base_part then
                    if table.contains(fac.uses_parts, part.base_part) then
                        table.insert(new_blueprint, part.base_part)
                    else
                        local fac_part = factory.parts[part.base_part]
                        for _, def_part in pairs(fac.default_blueprint) do
                            local fac_def_part = factory.parts[def_part]
                            if fac_def_part.type == fac_part.type then
                                table.insert(new_blueprint, def_part)
                                break
                            end
                        end
                    end
                end
            else
                table.insert(new_blueprint, part_id)
            end
        end
    end

    return new_blueprint
end

---Whether injecting the part can not crash: its weapon factory and base part exist
---@param part table
---@return boolean
function SkinLib._can_inject_part(part)
    local factory = tweak_data.weapon.factory
    if not (factory[part.weapon_factory_id] and factory[part.weapon_factory_id].uses_parts and factory.parts[part.base_part]) then
        log("[SkinLib] part " .. tostring(part.part_id) .. " skipped, unknown weapon_factory_id '" .. tostring(part.weapon_factory_id) .. "' or base_part '" .. tostring(part.base_part) .. "'")
        return false
    end
    return true
end

---Whether injecting the skin can not crash: all parts it replaces with exist (skipped parts are missing)
---@param skin table
---@return boolean
function SkinLib._can_inject_skin(skin)
    local parts = tweak_data.weapon.factory.parts
    for base, replace in pairs(skin.replaces_parts or {}) do
        if not (parts[base] and parts[replace]) then
            log("[SkinLib] skin " .. tostring(skin.skin_id) .. " skipped, part '" .. tostring(base) .. "' or '" .. tostring(replace) .. "' does not exist")
            return false
        end
    end
    return true
end

function SkinLib._validate_part(part, factory)
    local valid = true
    local sl = "[SkinLib][SL_Part][_validate_part] "

    -- does part_id already exist?
    if factory.parts[part.part_id] then
        log(sl .. "part_id is already in use! '" .. part.part_id .. "'")
        valid = false
    end

    -- is weapon_factory_id valid?
    if not factory[part.weapon_factory_id] then
        log(sl .. "weapon_factory_id is invalid! '" .. part.weapon_factory_id .. "'")
        valid = false
    end

    -- does base_part exist?
    if not factory.parts[part.base_part] then
        log(sl .. "base_part does not exist! '" .. part.base_part .. "'")
        valid = false
    end

    -- set textures loaded?
    for _, view_type in ipairs({ "fps", "tps" }) do
        if part[view_type] then
            for mat, data in pairs(part[view_type]) do
                for typ, texture in pairs(data) do
                    if not DB:has(ids["texture"], Idstring(texture)) then
                        log(sl ..
                            "part_id: '" ..
                            part.part_id ..
                            "' material: '" .. mat .. "' type: '" .. typ .. "' texture: '" .. texture .. "'")
                        valid = false
                    end
                end
            end
        end
    end

    -- set unit loaded?
    if part.unit then
        if not DB:has(ids["unit"], Idstring(part.unit)) then
            valid = false
        end
    end

    -- set third_unit loaded?
    if part.third_unit then
        if not DB:has(ids["unit"], Idstring(part.third_unit)) then
            valid = false
        end
    end

    log(sl .. "Part: " .. part.part_id .. " Valid?: " .. tostring(valid))
    return valid
end

function SkinLib._validate_skin(skin, factory)
    local valid = true
    local valid_rarity = {"loot_rarity_common", "loot_rarity_uncommon", "loot_rarity_rare"}
    local sl = "[SkinLib][SL_Skin][_validate_skin] "

    -- do parts in replaces_parts exist?
    if skin.replaces_parts and next(skin.replaces_parts) then
        for base, replace in pairs(skin.replaces_parts) do
            if not factory.parts[base] then
                valid = false
                log(sl .. "base_part not found: " .. base .. " skin_id: " .. skin.skin_id)
            end
            if not factory.parts[replace] then
                valid = false
                log(sl .. "replace_part not found: " .. replace .. " skin_id: " .. skin.skin_id)
            end
        end
    end

    -- weapon_id valid?
    if not tweak_data.weapon[skin.weapon_id] and not tweak_data.blackmarket.melee_weapons[skin.weapon_id] then
        log(sl .. "invalid weapon_id: " .. skin.weapon_id .. " skin_id: " .. skin.skin_id)
        valid = false
    end

    -- challenge data correct?

    -- droppable type?
    if skin.droppable then
        if type(skin.droppable) ~= "boolean" then
            valid = false
            log(sl .. "droppable wrong type: " .. type(skin.droppable) .. " skin_id: " .. skin.skin_id)
        end
    end

    -- gold_price type?
    if skin.gold_price then
        if type(skin.gold_price) ~= "number" then
            valid = false
            log(sl .. "gold_price wrong type: " .. type(skin.gold_price) .. " skin_id: " .. skin.skin_id)
        end
    end

    -- valid rarity?
    local rarity_check = false
    for _, rare in ipairs(valid_rarity) do
        if rare == skin.rarity then
            rarity_check = true
        end
    end
    if rarity_check == false and skin.rarity ~= nil then
        valid = false
        log(sl .. "invalid rarity: " .. skin.rarity .. " skin_id: " .. skin.skin_id)
    end

    -- units in replaces_units loaded?
    if skin.replaces_units and next(skin.replaces_units) then
        for typ, unit in pairs(skin.replaces_units) do
            if not DB:has(ids["unit"], Idstring(unit)) then
                valid = false
                log(sl ..  "replaces_units, unit not loaded: " .. unit .. " type: " .. typ .. " skin_id: " .. skin.skin_id)
            end
        end
    end

    -- custom hud icon loaded?
    if skin.hud_icon then
        local texture = type(skin.hud_icon) == "table" and skin.hud_icon.texture or skin.hud_icon
        if not DB:has(ids["texture"], Idstring(texture)) then
            valid = false
            log(sl .. "custom hud icon not loaded, icon:" .. texture)
        end
    end

    -- parts in force_cosmetic_parts valid?
    if skin.force_cosmetic_parts then
        for base, replace in pairs(skin.force_cosmetic_parts) do
            if not factory.parts[base] then
                    valid = false
                    log(sl .. "cosmetic base_part not found: " .. base .. " skin_id: " .. skin.skin_id)
                end
                if not factory.parts[replace] then
                    valid = false
                    log(sl .. "cosmetic replace_part not found: " .. replace .. " skin_id: " .. skin.skin_id)
                end
        end
    end

    log(sl .. "Skin: " .. skin.skin_id .. " Valid?: " .. tostring(valid))
    return valid
end

SkinLib.Load()

-- PUBLIC

---Registers skin, takes either params table or SL_Skin instance
---@param params table
function SkinLib.RegisterSkin(params)
    local skin = {}
    if params._parts and params:_parts() ~= nil then
        for _, part in ipairs(params:_parts()) do
            SkinLib.RegisterPart(part)
        end
    end
    if type(params) == "table" and params._to_tbl then
        skin._cls = deep_clone(params)
        params = params:_to_tbl()
    end
    skin.params = params
    skin.id = params.skin_id
    SkinLib._add_skin(skin)
end

---Registers part, takes either params table or SL_Part instance
---@param params table
function SkinLib.RegisterPart(params)
    local part = {}
    if type(params) == "table" and params._to_tbl then
        part._cls = deep_clone(params)
        params = params:_to_tbl()
    end
    part.params = params
    part.id = params.part_id
    SkinLib._add_part(part)
end

---Compares required version to SkinLib version, returns `true` if requirement is met
---@param major integer
---@param minor integer
---@param patch integer
---@return boolean
function SkinLib.RequireVersion(major, minor, patch)
    local required = string.format("%d.%d.%d", major or 0, minor or 0, patch or 0)

    return BLT:CompareVersions(SkinLib._version, required) ~= 2
end

---Turns weapon_id into associated factory_id
---@param weapon_id string
---@return string|boolean
function SkinLib.weaponid2factoryid(weapon_id)
    return SkinLib.weapon_tbl[weapon_id] or false
end

---Turns factory_id into associated weapon_id
---@param factory_id string
---@return string|boolean
function SkinLib.factoryid2weaponid(factory_id)
    return SkinLib.weapon_tbl_reversed[factory_id] or false
end


---Returns the applied skin id for factory_id, if it is a SkinLib (custom) skin
---@param factory_id string
---@return string|nil
function SkinLib.get_applied_custom_skin(factory_id)
    if not (managers.weapon_inventory and factory_id) then
        return nil
    end
    local skin_id, skin_data = managers.weapon_inventory:get_applied_weapon_skin(factory_id)
    if skin_id and skin_data and skin_data.custom then
        return skin_id
    end
    return nil
end

---Builds the synced cosmetics string for weapons: "<skin_id>", plus "!" if ForceCosmeticParts is on
---@param skin_id string
---@return string
function SkinLib.make_cosmetics_string(skin_id)
    return SkinLib.settings.ForceCosmeticParts and (skin_id .. "!") or skin_id
end

---Parses a synced cosmetics string ("<skin_id>" or "<skin_id>!")
---and returns the skin id and the sender's ForceCosmeticParts setting, if it is a custom skin that is valid for factory_id (npc or not).
---Returns nil if the skin is unknown locally, so peers without the same skin see the default.
---@param cosmetics_string string|nil
---@param factory_id string
---@return string|nil, boolean|nil
function SkinLib.get_synced_custom_skin(cosmetics_string, factory_id)
    if type(cosmetics_string) ~= "string" or cosmetics_string == "" then
        return nil
    end
    local skin_id = cosmetics_string:match("^(.+)!$")
    local force_parts = skin_id ~= nil
    skin_id = skin_id or cosmetics_string
    local skin = tweak_data.weapon.weapon_skins[skin_id]
    if not (skin and skin.custom and skin.replaces_parts) then
        return nil
    end
    if SkinLib.factoryid2weaponid((factory_id:gsub("_npc$", ""))) ~= skin.weapon_id then
        return nil
    end
    for _, replacement in pairs(skin.replaces_parts) do
        if not tweak_data.weapon.factory.parts[replacement] then
            return nil
        end
    end
    return skin_id, force_parts
end

-- cosmetics strings the players synced for their weapons: peer_id -> factory_id -> cosmetics string
SkinLib._peer_skins = {}

---@param peer_id number
---@param factory_id string npc or not
---@param cosmetics_string string|nil
function SkinLib.set_peer_skin(peer_id, factory_id, cosmetics_string)
    SkinLib._peer_skins[peer_id] = SkinLib._peer_skins[peer_id] or {}
    SkinLib._peer_skins[peer_id][(factory_id:gsub("_npc$", ""))] = cosmetics_string
end

---@param peer_id number
---@param factory_id string npc or not
---@return string|nil cosmetics_string
function SkinLib.get_peer_skin(peer_id, factory_id)
    local skins = SkinLib._peer_skins[peer_id]
    return skins and skins[(factory_id:gsub("_npc$", ""))]
end

---Skin data whose force_cosmetic_parts apply to a weapon right now: the previewed skin in the skin selection, otherwise the applied one
---@param factory_id string
---@return table|nil
function SkinLib.get_force_skin_data(factory_id)
    if SkinLib._preview_skin_id then
        return tweak_data.weapon.weapon_skins[SkinLib._preview_skin_id]
    end
    if managers.weapon_inventory then
        local _, skin_data = managers.weapon_inventory:get_applied_weapon_skin(factory_id)
        return skin_data
    end
end

---Applies force_cosmetic_parts of a skin to a blueprint (base part -> replacement, "" removes it)
---@param blueprint table
---@param skin_data table|nil
---@return table
function SkinLib.apply_force_cosmetic_parts(blueprint, skin_data)
    local replaces = skin_data and skin_data.force_cosmetic_parts
    if not replaces then
        return blueprint
    end
    local result = {}
    for _, part in ipairs(blueprint) do
        local replacement = replaces[part]
        if replacement == nil then
            table.insert(result, part)
        elseif replacement ~= "" then
            table.insert(result, replacement)
        end
    end
    return result
end
