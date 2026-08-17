# Changelog

## Unreleased

- Refactored the checkpoint controller into a standalone player alias script.
- Removed the modified `aaaessentialplayerscript.psc` from the repository.
- Removed the dependency on SM Essential Player SE source code for this patch's implementation.
- Added plugin setup documentation for a dedicated Start Game Enabled quest and PlayerRef alias.
- Added a minimal CommonLibSSE-NG SKSE plugin that listens for `kSaveGame`.
- Replaced the hardcoded F5 trigger with checkpoints after local game-save events; intended coverage is manual saves, quicksaves, and autosaves.
- Added the patch-owned `BCBSRP_SaveSerial` global as the native-to-Papyrus save-event bridge.
- Preserved interior transition, outdoor timer, combat, and bleedout checkpoint behavior.
