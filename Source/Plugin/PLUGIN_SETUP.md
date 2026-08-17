# BCBS Respawn Patch plugin setup

Create a small plugin named `BCBSRespawnPatch.esp` (ESL flag is suitable if desired) containing the controller quest, its player alias, and patch-owned global variables used for save-event and MCM configuration state.

## Runtime requirement

The configuration menu uses the standard SkyUI MCM API (`SKI_ConfigBase`), so **SkyUI is required** at runtime. MCM Helper is not required.

## Global variables

Create the following Global Variables with these exact EditorIDs.

### Save event bridge

`BCBSRP_SaveSerial`

- Type: **Float**
- Initial value: `0.0`

The native SKSE plugin looks this form up by EditorID whenever SKSE reports `kSaveGame` and increments its value. The value is only an internal event serial; it has no gameplay meaning.

### Outdoor interval

`BCBSRP_OutdoorIntervalMinutes`

- Type: **Float**
- Initial value: `5.0`

The MCM exposes this as a slider from **1 to 30 real-time minutes**.

### Timed outdoor checkpoints

`BCBSRP_TimedOutdoorEnabled`

- Type: **Float**
- Initial value: `1.0`

`1.0` means enabled and `0.0` means disabled.

### Checkpoint notifications

`BCBSRP_ShowNotifications`

- Type: **Float**
- Initial value: `1.0`

`1.0` shows normal `Checkpoint updated.` notifications. `0.0` hides them. Configuration/error notifications remain visible.

## Quest

Create a quest with a unique EditorID, for example:

`BCBSRespawnCheckpointQuest`

Recommended settings:

- **Start Game Enabled:** yes
- **Run Once:** no
- No stages or objectives are required.

### Quest script: MCM

Attach this script directly to the quest:

`BCBSRespawnMCM`

Fill its properties:

- `OutdoorIntervalMinutes` -> `BCBSRP_OutdoorIntervalMinutes`
- `TimedOutdoorEnabled` -> `BCBSRP_TimedOutdoorEnabled`
- `ShowNotifications` -> `BCBSRP_ShowNotifications`

This registers **BCBS Respawn Patch** in SkyUI's Mod Configuration Menu.

## Player alias

Add one Reference Alias to the quest:

- Alias name: `Player`
- Fill type: **Specific Reference**
- Reference: **PlayerRef** (`00000014`)

Attach this script to the alias:

`BCBSRespawnCheckpointAlias`

Fill its properties:

- `SaveSerial` -> `BCBSRP_SaveSerial`
- `OutdoorIntervalMinutes` -> `BCBSRP_OutdoorIntervalMinutes`
- `TimedOutdoorEnabled` -> `BCBSRP_TimedOutdoorEnabled`
- `ShowNotifications` -> `BCBSRP_ShowNotifications`

## MCM behavior

The menu exposes:

- **Timed outdoor checkpoints** — enabled by default.
- **Outdoor checkpoint interval** — 1 to 30 minutes, 5 minutes by default.
- **Checkpoint notifications** — enabled by default.

These settings are local to each Skyrim Together client because each client has its own game state/save and its own BCBS recall marker.

Disabling timed outdoor checkpoints does **not** disable save-based or interior-transition checkpoints.

## Runtime behavior

The Papyrus controller resolves the existing BCBS recall marker with:

`Game.GetFormFromFile(0x000001, "PartyBleedoutCheck.esp")`

The native SKSE plugin listens for `SKSE::MessagingInterface::kSaveGame`. When the local game reports a completed save, it increments `BCBSRP_SaveSerial`. On its next update, the Papyrus alias sees the changed serial and moves that client's BCBS recall marker to the local player.

The intended behavior is that **manual saves, quicksaves, and autosaves** all update the checkpoint. Each Skyrim Together client handles its own saves independently. Confirm all three save types on the target Skyrim/SKSE runtime during validation before release.

No record from SM Essential Player SE is overridden or modified by this patch.

## Suggested plugin masters

The plugin itself only needs Skyrim's normal masters for its quest/player alias/global records. `PartyBleedoutCheck.esp` remains a functional requirement because the controller resolves its recall marker by filename at runtime.

SkyUI is a runtime/script dependency for the MCM but does not need to be made an ESP master unless the plugin later adds direct form references to SkyUI records.

## Papyrus compilation

Compile both patch scripts:

```text
Source/Scripts/BCBSRespawnCheckpointAlias.psc
Source/Scripts/BCBSRespawnMCM.psc
```

The Papyrus compiler import paths must include the SkyUI SDK/source files needed by `SKI_ConfigBase` / `SKI_QuestBase` when compiling `BCBSRespawnMCM.psc`.

Expected outputs:

```text
Scripts/BCBSRespawnCheckpointAlias.pex
Scripts/BCBSRespawnMCM.pex
```

## Packaging

The release archive should contain:

```text
BCBSRespawnPatch.esp
Scripts/
  BCBSRespawnCheckpointAlias.pex
  BCBSRespawnMCM.pex
SKSE/
  Plugins/
    BCBSRespawnPatch.dll
```

Optionally include the source separately:

```text
Source/Scripts/BCBSRespawnCheckpointAlias.psc
Source/Scripts/BCBSRespawnMCM.psc
```

Do **not** include `aaaessentialplayerscript.pex` or `aaaessentialplayerscript.psc`.

## Validation checklist

Before the first public Nexus release, verify on both clients:

1. Loading a save initializes the controller without Papyrus or SKSE log errors.
2. `BCBS Respawn Patch` appears in SkyUI's MCM.
3. The default outdoor interval is 5 minutes.
4. The interval slider accepts values from 1 to 30 minutes.
5. Disabling timed outdoor checkpoints prevents timer-based exterior checkpoints.
6. Re-enabling timed outdoor checkpoints restores them.
7. Disabling checkpoint notifications hides normal `Checkpoint updated.` messages without disabling checkpoints.
8. A manual save updates the checkpoint.
9. A quicksave updates the checkpoint.
10. An autosave updates the checkpoint.
11. Saving on Player 1 updates only Player 1's local checkpoint; Player 2 must receive/create their own save event for their own marker.
12. Entering an interior updates the checkpoint after the transition.
13. Moving between interior cells updates the checkpoint.
14. Leaving an interior updates the checkpoint.
15. Outdoor exploration updates at the interval configured in that client's MCM when outside combat.
16. No checkpoint is created while the player is downed.
17. A full two-player defeat teleports both players to their latest local checkpoints and play can continue normally.

Check `Documents/My Games/Skyrim Special Edition/SKSE/BCBSRespawnPatch.log` if save events are not being detected.
