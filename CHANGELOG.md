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
- Added `build_release.bat` to build the native DLL, compile both Papyrus scripts, stage the mod in `package/`, and create the versioned deployment archive in `dist/`.
- Added `VERSION` as the canonical version source and bumped the development version to `0.2.1`.
- Release archives now derive their version directly from `VERSION`.
- The canonical Creation Kit plugin is now `Source/Plugin/BCBSRespawnPatch.esp`.
- Adopted semantic project versioning: small changes increment the third number; larger changes increment the second number and reset the third to zero.
