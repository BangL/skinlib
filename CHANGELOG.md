## next:

## 0.5.0:
- skins without third person materials now also apply to the third person model (its materials are named wpn_third_* instead of wpn_fps_*)
- show skins in the ready up screen, also textures (the game only applied them to the weapon base, which the screen does not use)
- ready up screen: the skins other players synced for their equipped weapons show there too (SkinLib remembers them per player)
- ready up screen: weapons with a custom skin without third person materials are built from the first person parts
- new save system for owned custom skins featuring: a migrator for the old system, ability to keep owning skins that you uninstalled or couldnt load due to errors, saves are split so different steam accounts on the same machine will each have their own save data for SkinLib)

# 0.4.3:
- reworked preview crash fix

## 0.4.2:
- restore sender's ForceCosmeticParts setting for other players' weapons (reverts part of 0.4.1 fix)
- fix skin preview in the skin selection menu using the force_cosmetic_parts of the applied instead of the previewed skin
- fix rare crash happening when previewing a weapon with a skin applied

## 0.4.1:
- fix only forced parts updating when previewing in the skin selection menu
- sort skins in skin selection menu alphabetically

## 0.4.0:
- implement showing other player's weapon skins
- use xml version for SkinLib.RequireVersion()

## 0.3.2:
- fix overwriting wrong hud icon when applying weapon skins

## 0.3.1:
- add icon, concept by Dribbleondo
- fix "Expanded weapon rotation" in settings menu

## 0.3.0:
- added config menu for SkinLib features (russian translation by Punished Bernadetta)
- added validation for skins (helps with developing skins, hidden behind debug option)

## 0.2.0:
- added SL_Skin:set_force_cosmetic_parts() to override cosmetic parts with skins

## 0.1.1:
- fixed hud icon only applying on load

## 0.1.0:
- fixed SL_Skin:set_icon_large()
- added SL_Skin:set_hud_icon()

## 0.0.6:
- fixed custom throwable skins been shown as nothing to peers

## 0.0.5:
- fixed crash with throwable skins

## 0.0.4:
- fixed "Original" skin getting overwritten when previewing/equiping a SkinLib skin

## 0.0.3:
- enabled extra rotation on weapon/skin selection
- fix your weapons showing up broken for other players

## 0.0.2:
- fixed crash when firing with dp28 skin

## 0.0.1:
- initial release
