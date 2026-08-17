# BCBS Respawn Patch

Standalone dynamic checkpoint add-on for **Basic Co-op Bleedout System for Skyrim Together**.

This project no longer modifies or redistributes `aaaEssentialPlayerScript` from SM Essential Player SE. The checkpoint logic now lives in its own player alias script and is intended to be attached to a small Start Game Enabled quest in the patch plugin.

## Features

- Manual checkpoint update with **F5**.
- Checkpoint when entering an interior.
- Checkpoint when leaving an interior.
- Checkpoint when moving between interior cells.
- Automatic checkpoint every **5 real-time minutes** while outdoors and outside combat.
- No checkpoint updates while the local player is downed.
- Uses the existing BCBS recall marker from `PartyBleedoutCheck.esp`.

## Architecture

The runtime logic is contained in:

`Source/Scripts/BCBSRespawnCheckpointAlias.psc`

The script extends `ReferenceAlias` and should be attached to a Player reference alias on a small Start Game Enabled quest owned by this patch.

The patch does **not** alter the BCBS bleedout or party-defeat logic. It only moves the recall marker BCBS already uses as its respawn destination.

## Requirements

- Skyrim Special Edition / Anniversary Edition
- SKSE64
- Skyrim Together Reborn
- Basic Co-op Bleedout System for Skyrim Together (`PartyBleedoutCheck.esp`)

The parent BCBS mod may have additional requirements of its own.

## Plugin setup

See [`Source/Plugin/PLUGIN_SETUP.md`](Source/Plugin/PLUGIN_SETUP.md).

## Status

Checkpoint updates have been observed working in-game. Full two-player party defeat -> teleport -> recovery still needs final validation before the first stable Nexus release.
