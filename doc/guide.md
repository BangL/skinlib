# SkinLib Step-by-Step guide

How to make a simple texture skin for a vanilla weapon. For all classes and methods see the [API reference](api.md).

## Requirements:

- [Raid Lua Dump](https://github.com/steam-test1/Raid-WW2-Lua-Dump)
- [Raid Modding Tools](steam://launch/3115910)
- Image editing software like [Gimp](https://gimp.org)
- Code editor like Notepad++ or VSCode

## Step 0: Decide which weapon you want to create a skin for


| Weapon Name          | Weapon ID   | Weapon Factory ID       |
| :--------------------- | :------------ | ------------------------- |
| PISTOLS              |             |                         |
| C96 Mauser           | c96         | wpn_fps_pis_c96         |
| Tokarev TT-33        | tt33        | wpn_fps_pis_tt33        |
| Parabellum P08       | georg       | wpn_fps_pis_georg       |
| Webley Mk VI         | webley      | wpn_fps_pis_webley      |
| Colt M1911           | m1911       | wpn_fps_pis_m1911       |
| Welrod               | welrod      | wpn_fps_pis_welrod      |
| Pocket Double-Barrel | shotty      | wpn_fps_pis_shotty      |
|                      |             |                         |
| SHOTGUNS             |             |                         |
| M12                  | m1912       | wpn_fps_sho_m1912       |
| Ithaca 37            | ithaca      | wpn_fps_sho_ithaca      |
| Browning Auto-5      | browning    | wpn_fps_sho_browning    |
| Double-Barrel        | geco        | wpn_fps_sho_geco        |
|                      |             |                         |
| SMGS                 |             |                         |
| Sten MkII            | sten        | wpn_fps_smg_sten        |
| Thompson M1A1        | thompson    | wpn_fps_smg_thompson    |
| MP 38                | mp38        | wpn_fps_smg_mp38        |
| Sterling             | sterling    | wpn_fps_smg_sterling    |
|                      |             |                         |
| ASSAULT RIFLES       |             |                         |
| M1 Carbine           | carbine     | wpn_fps_ass_carbine     |
| M1 Garand            | garand      | wpn_fps_ass_garand      |
| StG 44               | mp44        | wpn_fps_ass_mp44        |
|                      |             |                         |
| LMGS                 |             |                         |
| BAR                  | m1918       | wpn_fps_lmg_m1918       |
| Degtyaryov DP-28     | dp28        | wpn_fps_lmg_dp28        |
| Bren                 | bren        | wpn_fps_lmg_bren        |
| MG 42                | mg42        | wpn_fps_lmg_mg42        |
|                      |             |                         |
| SNIPERS              |             |                         |
| Springfield M1903    | m1903       | wpn_fps_snp_m1903       |
| Karabiner 98K        | kar_98k     | wpn_fps_snp_kar_98k     |
| Lee-Enfield          | lee_enfield | wpn_fps_snp_lee_enfield |
| Mosin Nagant         | mosin       | wpn_fps_snp_mosin       |

## Step 1: Extracting necessary files

1. Open [Raid Modding Tools](steam://launch/3115910)
2. Point it to your Raid installation folder's bundle.blb (Raid folder/assets/bundle_db.blb)
3. Extract files for your weapon of choice. Those are usually found in `units/vanilla/weapons/WEAPON_FACTORY_ID_pts`, alternatively check the `upd_` folders under `units`. Example for welrod: `units/vanilla/weapons/wpn_fps_pis_welrod_pts`

## Step 2: Editing the textures

1. Open & edit the texture for your skin
2. Export to DDS format, recommended settings (for GIMP): <br />
![recommended settings for dds export](images/export_dds.png)
3. Rename `YourTexture.dds` to `YourTexture.texture`

## Step 3: Writing the code

1. Copy the `skeleton` folder to your `mods` folder and rename it to something unique.
2. In `supermod.xml` edit `name`, `description`, `author`, `version`. Keep the `SkinLib` dependency and the `lib/setups/setup` hook.
3. Put your `.texture` files next to `supermod.xml` and register them as assets (add inside `<mod>`):

```xml
<assets>
    <file path="my_welrod_df.texture" name="units/upd_017/weapons/wpn_fps_pis_welrod_pts/textures/my_welrod_df.texture" />
    <file path="my_welrod_gsm.texture" name="units/upd_017/weapons/wpn_fps_pis_welrod_pts/textures/my_welrod_gsm.texture" />
</assets>
```

`name` is the in-game path. In Lua you reference it without the `.texture` extension. Use the weapon's vanilla texture folder.

4. In `core.lua` define the material(s), the parts, and register the skin. Each part replaces one vanilla part (`base_part`) and carries the new materials. Welrod example (full version: [timelines_skinlib_fluent](examples/timelines_skinlib_fluent/core.lua)):

```lua
Hooks:Add("SkinLibCollectData", "MyMod.SkinLibCollectData", function(self)
    local tex = "units/upd_017/weapons/wpn_fps_pis_welrod_pts/textures/"
    -- material name = the vanilla material of the weapon (wpn_fps_*), see Step 4
    local m_fps = SL_Material:new("wpn_fps_pis_welrod",
        tex .. "wpn_fps_pis_welrod_nm",  -- normal map (vanilla, reused)
        tex .. "my_welrod_df",           -- diffuse (yours)
        tex .. "my_welrod_gsm")          -- gloss/specular map (yours)

    local function part(name)
        return SL_Part:new("wpn_fps_pis_welrod_" .. name .. "_my", -- new unique part id
                           "wpn_fps_pis_welrod",                   -- weapon factory id
                           "wpn_fps_pis_welrod_" .. name)          -- vanilla part to replace
            :add_fps_material(m_fps)
    end

    self.RegisterSkin(
        SL_Skin:new("my_welrod_skin", "welrod")  -- unique skin id, weapon id
            :set_name_id("my_welrod_skin")
            :set_weapon_name_id("my_welrod_skin_name")
            :set_weapon_desc_id("my_welrod_skin_desc")
            :set_gold_price(50)                  -- buyable
            :set_droppable(true)                 -- also a loot drop
            :set_rarity(LootDropTweakData.RARITY_COMMON)
            :add_parts({
                part("body_standard"), part("bolt_standard"), part("m_standard"),
                part("catch"), part("trigger"), part("safety"),
            })
    )
end)
```

Third person materials (`add_tps_material`, names `wpn_third_*`) are optional: without them SkinLib derives them from the vanilla third person data and your diffuse texture.

5. Add the texts to `english.json` (keys = the ids from above):

```json
{
    "my_welrod_skin": "My Skin",
    "my_welrod_skin_name": "My Skin",
    "my_welrod_skin_desc": "Some flavor text"
}
```

## Step 4: Finding the right names

- Part ids / base parts: the weapon's factory entry in the Lua dump (`lib/tweak_data/weaponfactorytweakdata.lua`).
- Material names: the `.material_config` of the weapon unit (extracted in Step 1); first person `wpn_fps_*`, third person `wpn_third_*`. A wrong name makes the skin silently do nothing for that material.
- Vanilla textures: `.../textures/` next to the unit; usual suffixes `_df` (diffuse), `_nm` (normal), `_gsm` (gloss/specular).

## Step 5: Testing

1. Enable `Debug` in the SkinLib options. The log (`mods/logs/`) then lists `_validate_skin` / `_validate_part` lines with `Valid?: true/false` and the reason (missing texture, unknown base part, ...).
2. Open the weapon's skin selection in the camp and check the skin.
3. Most common error: missing textures. Compare the asset paths in `supermod.xml` with those in `core.lua`.

## Step 6: Distributing

Upload the mod folder to modworkshop and set the `<update>` identifier in `supermod.xml`. Keep `SkinLib` as `<dependency>`. Players without your mod see the default weapon.
