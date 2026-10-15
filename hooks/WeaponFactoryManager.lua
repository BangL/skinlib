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
        if not SkinLib._is_part_injected(id) then
            if SkinLib.debug() then
                SkinLib._validate_part(part.params, tweak_data.weapon.factory)
            end
            -- setup materials
            local m_fps = {}
            local m_tps = {}
            local unique_materials = {}

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
            else
                -- use fps as tps
                m_tps = m_fps
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

            SkinLib._set_injected_part(id)
        end
    end

    -- handle registered skins
    for id, skin in pairs(SkinLib._get_skins()) do
		if not SkinLib._is_skin_injected(id) then
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

			tweak_data.weapon.weapon_skins[id] = si
			SkinLib._set_injected_skin(id)
		end
	end
end)


---@diagnostic disable-next-line: duplicate-set-field
function WeaponFactoryManager:assemble_from_blueprint(factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
    if SkinLib.settings.ForceCosmeticParts then
        local _, skin_data = managers.weapon_inventory:get_applied_weapon_skin(factory_id)
        blueprint = SkinLib.apply_force_cosmetic_parts(blueprint, skin_data)
    end
    return self:_assemble(factory_id, p_unit, blueprint, third_person, done_cb, skip_queue)
end
