-- add WeaponSkinParts to WeaponFactoryTweakData, right before WeaponFactoryManager uses it.

-- Hooks:Register("SkinLibCollectData") funny BLT-design flaw: you actually never need to call this register func at all, everything will work perfectly fine without it.

Hooks:PreHook(WeaponFactoryManager, "_read_factory_data", "SkinLib.WeaponFactoryManager._read_factory_data", function(self)
    --[[

    -- dev code to extract weapon part ids & factory ids
    local ids = {}
    for _, factory_id in pairs(SkinLib.weapon_tbl) do
        ids[factory_id] = {}
        for _, part_id in pairs(tweak_data.weapon.factory[factory_id].uses_parts) do
            ids[factory_id][#ids[factory_id]+1] = part_id
        end
    end
    local f = io.open("part_ids.json", "w")
    if f then
        f:write(json.encode(ids))
        f:close()
    end
    
    ]]

    -- collect parts & skins from mods
    Hooks:Call("SkinLibCollectData", SkinLib)

    -- handle registered parts
    for id, part in pairs(SkinLib._get_parts()) do
        if not SkinLib._is_part_injected(id) and SkinLib._can_inject_part(part.params) then
            if SkinLib.debug() then
                SkinLib._validate_part(part.params, tweak_data.weapon.factory)
            end
            -- setup materials
            local m_fps = {}
            local m_tps = {}
            local unique_materials = {}

            local tps_derived

            local materials_fps = part.params.fps or {}
            local materials_tps = part.params.tps or {}

            -- fps
            for name, _ in pairs(materials_fps) do
                m_fps[name] = {}
                m_fps[name].bump_normal_texture = part.params.fps[name].bump_normal_texture or nil
                m_fps[name].diffuse_texture = part.params.fps[name].diffuse_texture or nil
                m_fps[name].material_texture = part.params.fps[name].material_texture or nil
                m_fps[name].reflection_texture = part.params.fps[name].reflection_texture or nil
                unique_materials = SkinLib._add_unique_material(unique_materials, name)
            end
            -- tps
            if part.params.tps ~= nil then
                for name, _ in pairs(materials_tps) do
                    -- tps provided
                    m_tps[name] = {}
                    m_tps[name].bump_normal_texture = part.params.tps[name].bump_normal_texture or nil
                    m_tps[name].diffuse_texture = part.params.tps[name].diffuse_texture or nil
                    m_tps[name].material_texture = part.params.tps[name].material_texture or nil
                    m_tps[name].reflection_texture = part.params.tps[name].reflection_texture or nil
                    unique_materials = SkinLib._add_unique_material(unique_materials, name)
                end
                if part.params.unit == nil and part.params.third_unit == nil then
                    local old_name, new_name = SkinLib._fix_tps_material_name(part.params.base_part, m_tps, unique_materials)
                    if old_name then
                        log("[SkinLib] part " .. tostring(part.params.part_id) .. ": third person material '" .. old_name .. "' does not exist, using '" .. new_name .. "'")
                    end
                end
            else
                tps_derived = SkinLib._derive_tps_materials(part.params.base_part, m_fps)
            end
            if tps_derived then
                -- built from the vanilla third person materials of the base part, with the diffuse of the skin
                for name, textures in pairs(tps_derived) do
                    m_tps[name] = textures
                    unique_materials = SkinLib._add_unique_material(unique_materials, name)
                end
            elseif part.params.tps == nil then
                -- no vanilla data: use fps as tps, the third person model names its materials wpn_third_* instead of wpn_fps_*
                for name, textures in pairs(m_fps) do
                    m_tps[name] = textures
                    local third_name = (name:gsub("^wpn_fps_", "wpn_third_"))
                    if third_name ~= name then
                        m_tps[third_name] = textures
                        unique_materials = SkinLib._add_unique_material(unique_materials, third_name)
                    end
                end
            end
            -- insert into uses_parts
            table.insert(tweak_data.weapon.factory[part.params.weapon_factory_id].uses_parts, part.params.part_id)
            -- the npc factory is a clone made before our injection, so peers need the part too
            local npc_factory = tweak_data.weapon.factory[part.params.weapon_factory_id .. "_npc"]
            if npc_factory then
                table.insert(npc_factory.uses_parts, part.params.part_id)
            end

            -- insert part
            tweak_data.weapon.factory.parts[part.params.part_id] = deep_clone(tweak_data.weapon.factory.parts[part.params.base_part])
            if #unique_materials ~= 0 then
                -- fix "Original" skin
                if SkinLib._fix_tbl[part.params.base_part] then
                    tweak_data.weapon.factory.parts[part.params.base_part].unique_materials = SkinLib._fix_tbl[part.params.base_part]["unique"]
                    tweak_data.weapon.factory.parts[part.params.base_part].materials_fps = SkinLib._fix_tbl[part.params.base_part]["fps"]
                    tweak_data.weapon.factory.parts[part.params.base_part].materials_tps = SkinLib._fix_tbl[part.params.base_part]["tps"]
                end


                -- add skin data to part
                tweak_data.weapon.factory.parts[part.params.part_id].materials_fps = m_fps
                tweak_data.weapon.factory.parts[part.params.part_id].materials_tps = m_tps
                tweak_data.weapon.factory.parts[part.params.part_id].unique_materials = unique_materials
            end
            if part.params.unit ~= nil then
                tweak_data.weapon.factory.parts[part.params.part_id].unit = part.params.unit
            end
            if part.params.third_unit ~= nil then
                tweak_data.weapon.factory.parts[part.params.part_id].third_unit = part.params.third_unit
            end

            -- custom fields for our network code
            tweak_data.weapon.factory.parts[part.params.part_id].custom = true
            tweak_data.weapon.factory.parts[part.params.part_id].base_part = part.params.base_part
            -- nothing to provide if the vanilla third person part has no materials
            tweak_data.weapon.factory.parts[part.params.part_id].tps_provided = part.params.tps ~= nil or tps_derived ~= nil or not SkinLib._base_part_has_tps_materials(part.params.base_part)

            SkinLib._set_injected_part(id)
        end
    end

    -- handle registered skins
    for id, skin in pairs(SkinLib._get_skins()) do
		if not SkinLib._is_skin_injected(id) and SkinLib._can_inject_skin(skin.params) then
            if SkinLib.debug() then
			    SkinLib._validate_skin(skin.params, tweak_data.weapon.factory)
            end
			local si = {}
			si.dlc = skin.params.dlc or nil
			si.name_id = skin.params.name_id
			si.replaces_parts = skin.params.replaces_parts or nil
			si.weapon_desc_id = skin.params.weapon_desc_id or nil
			si.weapon_id = skin.params.weapon_id
			si.weapon_name_id = skin.params.weapon_name_id or nil
			si.challenge = skin.params.challenge or nil
			si.droppable = skin.params.droppable or nil
			si.gold_price = skin.params.gold_price or nil
			si.rarity = LootDropTweakData[skin.params.rarity] or nil
			si.replaces_units = skin.params.replaces_units or nil
            si.icon_large = skin.params.icon_large or nil

            -- custom fields
            si.custom = true
            si.hud_icon = skin.params.hud_icon or nil
            si.force_cosmetic_parts = skin.params.force_cosmetic_parts or nil
            si.fps_rotation = skin.params.fps_rotation or nil
            si.fps_offset = skin.params.fps_offset or nil
            si.tps_rotation = skin.params.tps_rotation or nil
            si.tps_offset = skin.params.tps_offset or nil
            si.melee_decal_effect = skin.params.melee_decal_effect
            si.melee_sounds = skin.params.melee_sounds or nil

			tweak_data.weapon.weapon_skins[id] = si
			SkinLib._set_injected_skin(id)
		end
	end
end)


-- the forced replacement parts must be preloaded too, else assembling spawns parts whose units are not loaded (engine crash)
local preload_blueprint_original = WeaponFactoryManager.preload_blueprint
---@diagnostic disable-next-line: duplicate-set-field
function WeaponFactoryManager:preload_blueprint(factory_id, blueprint, third_person, done_cb, only_record)
    if SkinLib.settings.ForceCosmeticParts then
        blueprint = SkinLib.apply_force_cosmetic_parts(blueprint, SkinLib.get_force_skin_data(factory_id))
    end
    return preload_blueprint_original(self, factory_id, blueprint, third_person, done_cb, only_record)
end

---@diagnostic disable-next-line: duplicate-set-field
function WeaponFactoryManager:assemble_from_blueprint(factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
    -- ready up: the weapon of another player gets the skin it told us about instead of ours
    local peer = SkinLib._ready_up_peer
    SkinLib._ready_up_peer = nil
    local skin_id
    if peer then
        if peer:id() ~= managers.network:session():local_peer():id() then
            local force_parts
            skin_id, force_parts = SkinLib.get_synced_custom_skin(SkinLib.get_peer_skin(peer:id(), factory_id), factory_id)
            if skin_id then
                blueprint = self:modify_skin_blueprint(factory_id, blueprint, skin_id)
                if force_parts then
                    blueprint = SkinLib.apply_force_cosmetic_parts(blueprint, tweak_data.weapon.weapon_skins[skin_id])
                end
            end
            return self:_assemble_ready_up(peer, skin_id, factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
        end
        skin_id = SkinLib.get_applied_custom_skin(factory_id)
    end

    if SkinLib.settings.ForceCosmeticParts then
        blueprint = SkinLib.apply_force_cosmetic_parts(blueprint, SkinLib.get_force_skin_data(factory_id))
    end
    if peer then
        return self:_assemble_ready_up(peer, skin_id, factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
    end
    return self:_assemble(factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
end

-- the ready up screen puts the parts on the first person weapon unit. a custom skin without third person materials only fits the first person
-- parts, so such a weapon is built from them there.
function WeaponFactoryManager:_assemble_ready_up(peer, skin_id, factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
    if skin_id and SkinLib.skin_lacks_tps(skin_id) then
        third_person = false
    end
    SkinLib._ready_up_first_person = SkinLib._ready_up_first_person or {}
    SkinLib._ready_up_first_person[peer:id()] = not third_person
    return self:_assemble(factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
end
