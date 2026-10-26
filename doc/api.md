# SkinLib API reference

All skin mods register their data inside the `SkinLibCollectData` hook. The hook receives the `SkinLib` table (`self`). Load your script via `<pre hook_id="lib/setups/setup" script_path="core.lua" />` and declare `SkinLib` as `<dependency>`.

```lua
Hooks:Add("SkinLibCollectData", "UniqueName.SkinLibCollectData", function(self)
    -- build SL_Material / SL_Part / SL_Skin, then self.RegisterSkin(skin)
end)
```

All setters return the object, so calls chain with `:`.

## SL_Skin

`SL_Skin:new(skin_id, weapon_id)` - `weapon_id` is the short id (`welrod`, `carbine`, ...), see the table in the [guide](guide.md). Skin ids must be unique.

| Method | Meaning |
| :-- | :-- |
| `set_name_id(id)` | Localization key of the skin name |
| `set_weapon_name_id(id)` | Localization key of the weapon name shown with the skin |
| `set_weapon_desc_id(id)` | Localization key of the weapon description |
| `set_gold_price(n)` | Makes the skin buyable for `n` gold |
| `set_droppable(bool)` | Skin can drop as loot |
| `set_rarity(r)` | `LootDropTweakData.RARITY_COMMON` / `_UNCOMMON` / `_RARE` |
| `set_challenge(tbl)` | Challenge data for unlocking the skin |
| `add_part(part)` / `add_parts({...})` | Adds `SL_Part`s; they are registered with the skin and replace their `base_part` |
| `set_replaces_unit(base, replacement)` / `set_replaces_units({base = replacement})` | Replaces whole units (keys like `unit`, `unit_dummy`, `unit_hand`; used e.g. for grenades; melee weapons use `unit` and `third_unit`) |
| `set_fps_rotation(yaw, pitch, roll)` / `set_fps_offset(x, y, z)` | Turns / moves the first person melee unit in the hand (melee skins) |
| `set_icon_large(path)` | Icon for the reward screen |
| `set_hud_icon(path_or_table)` | HUD weapon icon (needs the `Custom HUD Icon` option) |
| `set_force_cosmetic_parts({base = replacement})` | Forces cosmetic parts while the skin is applied; `""` as replacement removes the part (needs `Force Cosmetic Parts`) |

## SL_Part

`SL_Part:new(part_id, weapon_factory_id, base_part)`
- `part_id`: new unique id
- `weapon_factory_id`: e.g. `wpn_fps_pis_welrod`
- `base_part`: vanilla part this one replaces

| Method | Meaning |
| :-- | :-- |
| `add_fps_material(mat)` | First person material; `mat` is an `SL_Material` or `(name, bump_normal, diffuse, material, reflection)` |
| `add_tps_material(mat)` | Third person material, same arguments. Optional: derived from the vanilla data if missing |
| `add_unit(path)` | Own first person unit (custom model) |
| `add_third_unit(path)` | Own third person unit |

Custom models need their `.unit`, `.model`, `.object`, `.material_config`, `.cooked_physics` as assets, see [m1garbine_skinlib](examples/m1garbine_skinlib).

## SL_Material

`SL_Material:new(name, bump_normal_texture, diffuse_texture, material_texture, reflection_texture)`

Texture paths are in-game paths without extension. `name` is the material name from the unit's `material_config` (`wpn_fps_*` / `wpn_third_*`). Any texture left `nil` keeps the vanilla one.

## SkinLib functions

| Function | Meaning |
| :-- | :-- |
| `SkinLib.RegisterSkin(skin)` | Registers an `SL_Skin` (or params table) and its parts |
| `SkinLib.RegisterPart(part)` | Registers a single part |
| `SkinLib.RequireVersion(major, minor, patch)` | `true` if the installed SkinLib is at least that version |
| `SkinLib.weaponid2factoryid(id)` / `SkinLib.factoryid2weaponid(id)` | Convert between `welrod` and `wpn_fps_pis_welrod` |
| `SkinLib.get_applied_custom_skin(factory_id)` | Id of the applied custom skin, or `nil` |
| `SkinLib.settings` | `Debug`, `ForceCosmeticParts`, `CustomHudIcon`, `ExpandWeaponRotation` |

Functions prefixed with `_` are internal.

## Validation

With `Debug` on, every part and skin is checked on load and the result is logged (`Valid?: true/false`): duplicate part ids, unknown factory/base parts, textures or units not found in the database, wrong types, invalid rarity.

## Multiplayer

The skin id is synced with the weapon. Peers with the same skin mod see it, others see the default.

## Examples

- [timelines_skinlib_fluent](examples/timelines_skinlib_fluent) - texture-only skin (fluent API)
- [m1garbine_skinlib](examples/m1garbine_skinlib) - custom model + textures
- [koishi343d_skinlib](examples/koishi343d_skinlib) - grenade, `set_replaces_units` + HUD icon
- [skeleton](skeleton) - empty template
