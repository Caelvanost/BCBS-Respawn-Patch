# BCBS Respawn Patch

**Current version: `0.3.1`**

Standalone dynamic checkpoint add-on for **Basic Co-op Bleedout System for Skyrim Together**.

## Supported Skyrim runtimes

Version 0.3.0 uses one universal SKSE DLL for the AE-family runtimes used by this project:

- **Skyrim 1.6.1170** — supported target.
- **Skyrim 1.7.99** — supported target.
- **Skyrim 1.7.104** — supported target.

The 0.2.x DLL was built against CommonLibSSE-NG 3.5.3 and cannot read Skyrim 1.7's Address Library V5 files. Version 0.3.0 migrates the native plugin to the MIT universal-runtime CommonLibSSE-NG fork by Zzyxz, pinned to commit `6fcfb68af0870e345a3656ac6da371a694fdb374`. That fork supports Address Library format 2 used by Skyrim 1.6.x and format 5 used by Skyrim 1.7.x.

The 1.7.104 target still requires in-game validation before the beta is considered fully verified.

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

The MCM uses the standard SkyUI `SKI_ConfigBase` API. MCM Helper is not required.

## Architecture

Papyrus checkpoint logic:

`Source/Scripts/BCBSRespawnCheckpointAlias.psc`

SkyUI MCM:

`Source/Scripts/BCBSRespawnMCM.psc`

Creation Kit plugin source:

`Source/Plugin/BCBSRespawnPatch.esp`

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

## Versioning

`VERSION` is the canonical project version.

Version policy:

- small change / bugfix: increment the third number (`0.3.1` -> `0.3.2`);
- larger feature/change: increment the second number and reset the third to zero (`0.3.1` -> `0.4.0`).

When the version changes, keep the displayed version in this README and `vcpkg.json` synchronized with `VERSION`.

CMake reads `VERSION` directly, and `build_release.bat` uses the same file for the deployment archive name, so a build for version `X.Y.Z` produces:

```text
dist/BCBS-Respawn-Patch-vX.Y.Z.zip
```

## Build

The native listener uses a pinned MIT universal-runtime CommonLibSSE-NG fork that supports Skyrim 1.6.x and 1.7.x in the same DLL. CMake fetches the pinned source into `.deps/`; vcpkg supplies the remaining native dependencies with the `x64-windows-static` triplet.

### Automated release build

Before building, copy the current Creation Kit plugin to:

```text
Source/Plugin/BCBSRespawnPatch.esp
```

Run from the repository root:

```bat
build_release.bat
```

The script:

1. reads the release version from `VERSION`;
2. configures and builds `BCBSRespawnPatch.dll` in Release mode;
3. compiles `BCBSRespawnCheckpointAlias.psc` and `BCBSRespawnMCM.psc`;
4. copies `Source/Plugin/BCBSRespawnPatch.esp` into the release package;
5. stages the deployable mod in `package/`;
6. creates `dist/BCBS-Respawn-Patch-v<VERSION>.zip`.

The build expects both `git` and `cmake` in `PATH`, and `VCPKG_ROOT` to point to the local vcpkg installation. `SKYRIM_DIR` can be set to override the default development path:

```text
C:\Games\Steam\steamapps\common\Skyrim Special Edition
```

The Papyrus environment must provide the SkyUI source dependencies in `Data/Source/Scripts`, including at least:

```text
SKI_ConfigBase.psc
SKI_ConfigManager.psc
SKI_QuestBase.psc
TESV_Papyrus_Flags.flg
```

By default, `build_release.bat` uses:

```text
Data/Source/Scripts/TESV_Papyrus_Flags.flg
```

You can override the flags file path by setting `PAPYRUS_FLAGS` before running the build.

The generated release package contains only:

```text
BCBSRespawnPatch.esp
Scripts/
  BCBSRespawnCheckpointAlias.pex
  BCBSRespawnMCM.pex
SKSE/
  Plugins/
    BCBSRespawnPatch.dll
```

### Manual native build

Typical configure/build commands:

```powershell
cmake -S . -B build `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows-static
cmake --build build --config Release
```

The CommonLib source is fetched from `Zzyxz/CommonLibSSE-NG` at the pinned revision recorded in `CMakeLists.txt`. The old `colorglass` vcpkg registry and CommonLibSSE-NG 3.5.3 package are no longer used.

Compile both Papyrus scripts:

```text
BCBSRespawnCheckpointAlias.psc
BCBSRespawnMCM.psc
```

Compiling the MCM script requires the SkyUI SDK/source scripts in the Papyrus compiler import path.

## Status

Checkpoint updates have been observed working in the earlier Papyrus implementation. The standalone quest + native save listener + MCM architecture still needs in-game validation, including confirming manual/quicksave/autosave behavior, MCM settings, and a full two-player party defeat -> teleport -> recovery test before the first stable Nexus release.
