# BCBS Respawn Patch plugin setup

Create a small plugin named `BCBSRespawnPatch.esp` (ESL flag is suitable if desired) containing only the controller quest and its player alias.

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

The script has no properties that need to be filled in the Creation Kit.

## Runtime behavior

At runtime the script resolves the existing BCBS recall marker with:

`Game.GetFormFromFile(0x000001, "PartyBleedoutCheck.esp")`

No record from SM Essential Player SE is overridden or modified by this patch.

## Suggested plugin masters

The plugin itself only needs Skyrim's normal masters for its quest/player alias records. `PartyBleedoutCheck.esp` remains a functional requirement because the controller resolves its recall marker by filename at runtime.

## Packaging

The release archive should contain:

```text
BCBSRespawnPatch.esp
Scripts/
  BCBSRespawnCheckpointAlias.pex
```

Optionally include the source separately:

```text
Source/Scripts/BCBSRespawnCheckpointAlias.psc
```

Do **not** include `aaaessentialplayerscript.pex` or `aaaessentialplayerscript.psc`.

## Validation checklist

Before the first public Nexus release, verify on both clients:

1. Loading a save initializes the controller without Papyrus errors.
2. Pressing F5 shows `Checkpoint updated.` and moves the BCBS recall marker.
3. Entering an interior updates the checkpoint after the transition.
4. Moving between interior cells updates the checkpoint.
5. Leaving an interior updates the checkpoint.
6. Outdoor exploration updates the checkpoint after five real-time minutes when not in combat.
7. No checkpoint is created while the player is downed.
8. A full two-player defeat teleports both players to the latest checkpoint and play can continue normally.
