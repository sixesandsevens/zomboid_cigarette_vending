# Cigarette Vending Machines

A Project Zomboid Build 42 mod that adds cigarette vending machines: new world objects, vending interaction, and the supporting items/assets.

## Status

Released, evolving.

## Install

1. Subscribe on Workshop (or drop the folder into your local mods directory).
2. Enable `Cigarette Vending Machines` in the in-game Mods menu.
3. Start a new game or load a save (depending on your world-spawn setup).

## What This Mod Adds

- Cigarette vending machine objects (tile + definitions)
- Vending interaction behavior (client/server/shared Lua)
- Cigarette-related items and scripts needed for vending

## Compatibility

- Target: Project Zomboid Build 42
- Uses `tiledef=ashboro_cigarette_vending 689` and `pack=cigarette_vending_ashboro`

## Project Layout

- `mod.info` - mod metadata
- `media/lua/` - client, server, and shared logic
- `media/scripts/` - item/object definitions
- `media/textures/CigaretteVending/` - textures for machines and UI
- `media/models/` - optional models (if present)
- `media/maps/` - world spawn / map integration (if present)
- `media/sounds/` - sound effects (if present)

## Notes

If you are integrating this into an existing world, double-check how your map/spawn definitions are applied so machines appear where you expect.
