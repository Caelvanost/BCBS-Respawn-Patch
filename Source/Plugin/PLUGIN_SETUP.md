# BCBS Respawn Patch plugin setup

Create a small plugin named `BCBSRespawnPatch.esp` (ESL flag is suitable if desired) containing the controller quest, its player alias, and one internal global variable used to bridge SKSE save events to Papyrus.

## Global variable

Create a Global Variable with this exact EditorID:

`BCBSRP_SaveSerial`

Recommended settings:

- Type: **Float**
- Initial value: `0.0`

The native SKSE plugin looks this form up by EditorID whenever SKSE reports `kSaveGame` and increments its value. The value is only an internal event serial; it has no gameplay meaning.

## Quest

Create a quest with a unique EditorID, for example:

`BCBSRespawnCheckpointQuest`

Recommended settings:

- **Start Game Enabled:** yes
- **Run Once:** no
- No stages or objectives are required.

## Player alias

Add one Reference Alias to the quest:

- Alias name: `Player`
- Fill type: **Specific Reference**
- Reference: **PlayerRef** (`00000014`)

Attach this script to the alias:

`BCBSRespawnCheckpointAlias`

Fill its property:

- `SaveSerial` -> `BCBSRP_SaveSerial`

## Runtime behavior

The Papyrus script resolves the existing BCBS recall marker with:

`Game.GetFormFromFile(0x000001, "PartyBleedoutCheck.esp")`

The native SKSE plugin listens for `SKSE::MessagingInterface::kSaveGame`. When the local game reports a completed save, it increments `BCBSRP_SaveSerial`. On its next update, the Papyrus alias sees the changed serial and moves that client's BCBS recall marker to the local player.

The intended behavior is that **manual saves, quicksaves, and autosaves** all update the checkpoint. Each Skyrim Together client handles its own saves independently. Confirm all three save types on the target Skyrim/SKSE runtime during validation before release.

No record from SM Essential Player SE is overridden or modified by this patch.

## Suggested plugin masters

The plugin itself only needs Skyrim's normal masters for its quest/player alias/global records. `PartyBleedoutCheck.esp` remains a functional requirement because the controller resolves its recall marker by filename at runtime.

## Packaging

The release archive should contain:

```text
BCBSRespawnPatch.esp
Scripts/
  BCBSRespawnCheckpointAlias.pex
SKSE/
  Plugins/
    BCBSRespawnPatch.dll
```

Optionally include the source separately:

```text
Source/Scripts/BCBSRespawnCheckpointAlias.psc
```

Do **not** include `aaaessentialplayerscript.pex` or `aaaessentialplayerscript.psc`.

## Validation checklist

Before the first public Nexus release, verify on both clients:

1. Loading a save initializes the controller without Papyrus or SKSE log errors.
2. A manual save shows `Checkpoint updated.` shortly after the save completes.
3. A quicksave shows `Checkpoint updated.` shortly after the save completes.
4. An autosave shows `Checkpoint updated.` shortly after the save completes.
5. Saving on Player 1 updates only Player 1's local checkpoint; Player 2 must receive/create their own save event for their own marker.
6. Entering an interior updates the checkpoint after the transition.
7. Moving between interior cells updates the checkpoint.
8. Leaving an interior updates the checkpoint.
9. Outdoor exploration updates the checkpoint after five real-time minutes when not in combat.
10. No checkpoint is created while the player is downed.
11. A full two-player defeat teleports both players to their latest local checkpoints and play can continue normally.

Check `Documents/My Games/Skyrim Special Edition/SKSE/BCBSRespawnPatch.log` if save events are not being detected.
