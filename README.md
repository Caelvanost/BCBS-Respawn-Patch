# BCBS Respawn Patch

Standalone dynamic checkpoint add-on for **Basic Co-op Bleedout System for Skyrim Together**.

This project does not modify or redistribute `aaaEssentialPlayerScript` from SM Essential Player SE. The checkpoint logic lives in its own player alias script, while a very small SKSE plugin listens for successful game-save events.

## Features

- Checkpoint after **any successful local game save**: manual save, quicksave, or autosave.
- Each Skyrim Together client updates its own BCBS checkpoint independently.
- Checkpoint when entering an interior.
- Checkpoint when leaving an interior.
- Checkpoint when moving between interior cells.
- Automatic checkpoint every **5 real-time minutes** while outdoors and outside combat.
- No checkpoint updates while the local player is downed.
- Uses the existing BCBS recall marker from `PartyBleedoutCheck.esp`.

## Architecture

Papyrus checkpoint logic:

`Source/Scripts/BCBSRespawnCheckpointAlias.psc`

Native SKSE save-event listener:

`src/main.cpp`

SKSE broadcasts `kSaveGame` when the local game is saved. The native listener increments the patch-owned `BCBSRP_SaveSerial` global. The player alias script observes that signal and moves the existing BCBS recall marker to the local player's position.

The patch does **not** alter the BCBS bleedout or party-defeat logic. It only moves the recall marker BCBS already uses as its respawn destination.

## Multiplayer behavior

Checkpoints are intentionally **local per client**.

If Player 1 saves, Player 1's local BCBS recall marker is updated. If Player 2 saves, Player 2's local marker is updated. Automatic interior and outdoor checkpoints are also evaluated independently on each client.

## Requirements

- Skyrim Special Edition / Anniversary Edition
- SKSE64
- Address Library for SKSE Plugins
- Skyrim Together Reborn
- Basic Co-op Bleedout System for Skyrim Together (`PartyBleedoutCheck.esp`)

The parent BCBS mod may have additional requirements of its own.

## Plugin setup

See [`Source/Plugin/PLUGIN_SETUP.md`](Source/Plugin/PLUGIN_SETUP.md).

## Build

The native listener uses CommonLibSSE-NG and the same vcpkg registry configuration used by the other Caelvanost SKSE projects.

Typical configure/build commands:

```powershell
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
cmake --build build --config Release
```

The Papyrus source must also be compiled to `BCBSRespawnCheckpointAlias.pex` after the patch ESP and its `SaveSerial` property are configured.

## Status

Checkpoint updates have been observed working in the earlier Papyrus implementation. The standalone quest + native save listener architecture still needs in-game validation, followed by a full two-player party defeat -> teleport -> recovery test before the first stable Nexus release.
