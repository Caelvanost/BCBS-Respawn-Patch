Scriptname BCBSRespawnCheckpointAlias extends ReferenceAlias

; BCBS Respawn Patch
; Standalone checkpoint controller for Basic Co-op Bleedout System.
; This script contains no code from SM Essential Player SE.
;
; Save detection is supplied by the companion SKSE plugin. The native plugin
; increments SaveSerial whenever SKSE reports kSaveGame (manual save,
; quicksave, or autosave). This alias polls that value and updates the local
; BCBS recall marker.

GlobalVariable Property SaveSerial Auto

ObjectReference HKPBCRecallPoint

; Five real-time minutes between automatic outdoor checkpoints.
Float OutdoorCheckpointInterval = 300.0

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

    ; A successful local game save (manual save, quicksave, or autosave)
    ; requests a checkpoint. Each Skyrim Together client receives and handles
    ; its own save event independently.
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

    ; Automatic checkpoint every five real-time minutes while outdoors,
    ; but never during combat.
    if !currentlyInterior
        Float currentTime = Utility.GetCurrentRealTime()

        if currentTime - lastOutdoorCheckpointTime >= OutdoorCheckpointInterval
            if !playerRef.IsInCombat()
                SetCoopCheckpoint()
            endif
        endif
    endif
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
        Debug.Notification("BCBS Respawn Patch: checkpoint marker not found.")
        return
    endif

    HKPBCRecallPoint.MoveTo(playerRef, 0.0, 0.0, 0.0, true)
    lastOutdoorCheckpointTime = Utility.GetCurrentRealTime()

    Debug.Notification("Checkpoint updated.")
EndFunction
