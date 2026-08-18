Scriptname BCBSRespawnCheckpointAlias extends ReferenceAlias

; BCBS Respawn Patch
; Standalone checkpoint controller for Basic Co-op Bleedout System.
; This script contains no code from SM Essential Player SE.
;
; Save detection is supplied by the companion SKSE plugin. The native plugin
; increments SaveSerial whenever SKSE reports kSaveGame. The intended behavior
; is to cover manual saves, quicksaves, and autosaves; validate all save types
; on the target runtime before release. This alias polls that value and updates
; the local BCBS recall marker.

GlobalVariable Property SaveSerial Auto
GlobalVariable Property OutdoorIntervalMinutes Auto
GlobalVariable Property TimedOutdoorEnabled Auto
GlobalVariable Property ShowNotifications Auto

ObjectReference HKPBCRecallPoint

Float lastOutdoorCheckpointTime = 0.0
Float lastSeenSaveSerial = 0.0

Cell checkpointLastCell = None
Bool checkpointWasInterior = false
Bool checkpointSystemInitialized = false


Event OnInit()
    InitializeCheckpointSystem()
    RegisterForSingleUpdate(1.0)
EndEvent


Event OnPlayerLoadGame()
    InitializeCheckpointSystem()
    RegisterForSingleUpdate(1.0)
EndEvent


Function InitializeCheckpointSystem()
    HKPBCRecallPoint = Game.GetFormFromFile(0x000001, "PartyBleedoutCheck.esp") as ObjectReference

    Actor playerRef = GetActorReference()
    if !playerRef
        checkpointSystemInitialized = false
        return
    endif

    checkpointLastCell = playerRef.GetParentCell()
    checkpointWasInterior = playerRef.IsInInterior()

    if SaveSerial
        ; Establish a baseline so loading an existing save does not itself
        ; create a new checkpoint.
        lastSeenSaveSerial = SaveSerial.GetValue()
    else
        lastSeenSaveSerial = 0.0
    endif

    lastOutdoorCheckpointTime = Utility.GetCurrentRealTime()
    checkpointSystemInitialized = true
EndFunction


Event OnUpdate()
    UpdateCoopCheckpointSystem()
    RegisterForSingleUpdate(1.0)
EndEvent


Function UpdateCoopCheckpointSystem()
    Actor playerRef = GetActorReference()
    if !playerRef
        return
    endif

    if !checkpointSystemInitialized
        InitializeCheckpointSystem()
        return
    endif

    ; A local game-save event requests a checkpoint. Each Skyrim Together
    ; client receives and handles its own save event independently.
    if SaveSerial
        Float currentSaveSerial = SaveSerial.GetValue()
        if currentSaveSerial != lastSeenSaveSerial
            lastSeenSaveSerial = currentSaveSerial

            ; Never move the checkpoint while the local player is downed.
            if playerRef.GetActorValue("Health") > 0.0
                SetCoopCheckpoint()
            endif
            return
        endif
    endif

    ; Never move automatic/cell checkpoints while the local player is downed.
    if playerRef.GetActorValue("Health") <= 0.0
        return
    endif

    Cell currentCell = playerRef.GetParentCell()
    Bool currentlyInterior = playerRef.IsInInterior()

    ; Exterior -> exterior: no cell-transition checkpoint.
    ; Exterior -> interior: checkpoint.
    ; Interior -> exterior: checkpoint.
    ; Interior -> interior: checkpoint.
    if currentCell != checkpointLastCell
        Bool previousInterior = checkpointWasInterior

        checkpointLastCell = currentCell
        checkpointWasInterior = currentlyInterior

        if previousInterior || currentlyInterior
            Utility.Wait(2.0)
            SetCoopCheckpoint()
            return
        endif
    endif

    ; Safety fallback if the interior/exterior state changes without the
    ; expected parent-cell change being observed.
    if currentlyInterior != checkpointWasInterior
        checkpointWasInterior = currentlyInterior
        checkpointLastCell = currentCell

        Utility.Wait(2.0)
        SetCoopCheckpoint()
        return
    endif

    ; Automatic outdoor checkpoints are optional and their interval is read
    ; from patch-owned globals configured through the SkyUI MCM.
    if !currentlyInterior && AreTimedOutdoorCheckpointsEnabled()
        Float currentTime = Utility.GetCurrentRealTime()
        Float intervalSeconds = GetOutdoorCheckpointIntervalSeconds()

        if currentTime - lastOutdoorCheckpointTime >= intervalSeconds
            if !playerRef.IsInCombat()
                SetCoopCheckpoint()
            endif
        endif
    endif
EndFunction


Bool Function AreTimedOutdoorCheckpointsEnabled()
    if TimedOutdoorEnabled
        return TimedOutdoorEnabled.GetValue() >= 0.5
    endif

    ; Safe fallback for an older/misconfigured ESP.
    return true
EndFunction


Float Function GetOutdoorCheckpointIntervalSeconds()
    Float minutes = 5.0

    if OutdoorIntervalMinutes
        minutes = OutdoorIntervalMinutes.GetValue()
    endif

    ; Keep runtime behavior sane even if the global was edited externally.
    if minutes < 1.0
        minutes = 1.0
    elseif minutes > 30.0
        minutes = 30.0
    endif

    return minutes * 60.0
EndFunction


Bool Function AreCheckpointNotificationsEnabled()
    if ShowNotifications
        return ShowNotifications.GetValue() >= 0.5
    endif

    return true
EndFunction


Function SetCoopCheckpoint()
    Actor playerRef = GetActorReference()
    if !playerRef
        return
    endif

    if playerRef.GetActorValue("Health") <= 0.0
        return
    endif

    if !HKPBCRecallPoint
        HKPBCRecallPoint = Game.GetFormFromFile(0x000001, "PartyBleedoutCheck.esp") as ObjectReference
    endif

    if !HKPBCRecallPoint
        ; Keep configuration/runtime errors visible even when normal checkpoint
        ; notifications are disabled.
        Debug.Notification("BCBS Respawn Patch: checkpoint marker not found.")
        return
    endif

    HKPBCRecallPoint.MoveTo(playerRef, 0.0, 0.0, 0.0, true)
    lastOutdoorCheckpointTime = Utility.GetCurrentRealTime()

    if AreCheckpointNotificationsEnabled()
        Debug.Notification("Checkpoint updated.")
    endif
EndFunction
