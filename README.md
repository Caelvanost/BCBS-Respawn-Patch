# BCBS Respawn Patch

Standalone dynamic checkpoint add-on for **Basic Co-op Bleedout System for Skyrim Together**.

This project does not modify or redistribute `aaaEssentialPlayerScript` from SM Essential Player SE. The checkpoint logic lives in its own player alias script, while a very small SKSE plugin listens for game-save events.

## Features

- Checkpoint after **any local game save event**: manual save, quicksave, or autosave.
- Each Skyrim Together client updates its own BCBS checkpoint independently.
- Checkpoint when entering an interior.
- Checkpoint when leaving an interior.
- Checkpoint when moving between interior cells.
- Configurable automatic outdoor checkpoints while outside combat.
- SkyUI MCM with a **1-30 minute** outdoor interval, **5 minutes by default**.
- Option to disable timed outdoor checkpoints without disabling save/interior checkpoints.
- Option to hide normal `Checkpoint updated.` notifications.
- No checkpoint updates while the local player is downed.
- Uses the existing BCBS recall marker from `PartyBleedoutCheck.esp`.

## MCM

The **BCBS Respawn Patch** SkyUI MCM contains three settings:

- **Timed outdoor checkpoints** — enabled by default.
- **Outdoor checkpoint interval** — 1 to 30 real-time minutes, default 5 minutes.
- **Checkpoint notifications** — enabled by default.

MCM settings are local to each client. Player 1 and Player 2 can use different outdoor intervals if desired.

## Architecture

Papyrus checkpoint logic:

`Source/Scripts/BCBSRespawnCheckpointAlias.psc`

SkyUI MCM:

`Source/Scripts/BCBSRespawnMCM.psc`

Native SKSE save-event listener:

`src/main.cpp`

SKSE broadcasts `kSaveGame` when the local game is saved. The native listener increments the patch-owned `BCBSRP_SaveSerial` global. The player alias script observes that signal and moves the existing BCBS recall marker to the local player's position.

MCM settings are stored in patch-owned globals so the checkpoint controller can read changes immediately at runtime.

The patch does **not** alter the BCBS bleedout or party-defeat logic. It only moves the recall marker BCBS already uses as its respawn destination.

## Multiplayer behavior

Checkpoints are intentionally **local per client**.

If Player 1 saves, Player 1's local BCBS recall marker is updated. If Player 2 saves, Player 2's local marker is updated. Automatic interior and outdoor checkpoints are also evaluated independently on each client.

## Requirements

- Skyrim Special Edition / Anniversary Edition
- SKSE64
- Address Library for SKSE Plugins
- SkyUI
- Skyrim Together Reborn
- Basic Co-op Bleedout System for Skyrim Together (`PartyBleedoutCheck.esp`)

The parent BCBS mod may have additional requirements of its own.

MCM Helper is **not** required.

## Plugin setup

See [`Source/Plugin/PLUGIN_SETUP.md`](Source/Plugin/PLUGIN_SETUP.md).

## Build

The native listener uses CommonLibSSE-NG and the same vcpkg registry configuration used by the other Caelvanost SKSE projects.

Typical configure/build commands:

```powershell
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
cmake --build build --config Release
```

Compile both Papyrus scripts:

```text
BCBSRespawnCheckpointAlias.psc
BCBSRespawnMCM.psc
```

Compiling the MCM script requires the SkyUI SDK/source scripts in the Papyrus compiler import path.

## Status

Checkpoint updates have been observed working in the earlier Papyrus implementation. The standalone quest + native save listener + MCM architecture still needs in-game validation, including confirming manual/quicksave/autosave behavior, MCM settings, and a full two-player party defeat -> teleport -> recovery test before the first stable Nexus release.
