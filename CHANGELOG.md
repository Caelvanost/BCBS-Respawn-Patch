# Changelog

## Unreleased

- Refactored the checkpoint controller into a standalone player alias script.
- Removed the modified `aaaessentialplayerscript.psc` from the repository.
- Removed the dependency on SM Essential Player SE source code for this patch's implementation.
- Added plugin setup documentation for a dedicated Start Game Enabled quest and PlayerRef alias.
- Added a minimal CommonLibSSE-NG SKSE plugin that listens for `kSaveGame`.
- Replaced the hardcoded F5 trigger with checkpoints after local game-save events; intended coverage is manual saves, quicksaves, and autosaves.
- Added the patch-owned `BCBSRP_SaveSerial` global as the native-to-Papyrus save-event bridge.
- Added a SkyUI MCM for client-local checkpoint configuration.
- Added a 1-30 minute outdoor checkpoint interval slider, defaulting to 5 minutes.
- Added an option to disable timed outdoor checkpoints while preserving save/interior checkpoints.
- Added an option to hide normal checkpoint notifications.
- Added patch-owned globals for MCM configuration state.
- Preserved interior transition, combat, and bleedout checkpoint protections.
