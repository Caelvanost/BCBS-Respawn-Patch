Scriptname BCBSRespawnMCM extends SKI_ConfigBase

; SkyUI MCM for BCBS Respawn Patch.
; Settings are stored in patch-owned GlobalVariables so each Skyrim Together
; client can configure its own local checkpoint behavior independently.

GlobalVariable Property OutdoorIntervalMinutes Auto
GlobalVariable Property TimedOutdoorEnabled Auto
GlobalVariable Property ShowNotifications Auto

Int timedOutdoorOID
Int outdoorIntervalOID
Int notificationsOID


Int Function GetVersion()
    return 1
EndFunction


Event OnConfigInit()
    ModName = "BCBS Respawn Patch"
EndEvent


Event OnPageReset(String page)
    SetTitleText("BCBS Respawn Patch")
    SetCursorFillMode(TOP_TO_BOTTOM)

    AddHeaderOption("Outdoor Checkpoints")

    Bool timedEnabled = GetTimedOutdoorEnabled()
    timedOutdoorOID = AddToggleOption("Timed outdoor checkpoints", timedEnabled)

    Int intervalFlags = OPTION_FLAG_NONE
    if !timedEnabled
        intervalFlags = OPTION_FLAG_DISABLED
    endif

    outdoorIntervalOID = AddSliderOption(
        "Outdoor checkpoint interval",
        GetOutdoorIntervalMinutes(),
        "{0} min",
        intervalFlags)

    AddEmptyOption()
    AddHeaderOption("Interface")
    notificationsOID = AddToggleOption(
        "Checkpoint notifications",
        GetNotificationsEnabled())
EndEvent


Event OnOptionSelect(Int option)
    if option == timedOutdoorOID
        Bool newValue = !GetTimedOutdoorEnabled()
        SetTimedOutdoorEnabled(newValue)
        SetToggleOptionValue(timedOutdoorOID, newValue)

        if newValue
            SetOptionFlags(outdoorIntervalOID, OPTION_FLAG_NONE)
        else
            SetOptionFlags(outdoorIntervalOID, OPTION_FLAG_DISABLED)
        endif

    elseif option == notificationsOID
        Bool newNotificationsValue = !GetNotificationsEnabled()
        SetNotificationsEnabled(newNotificationsValue)
        SetToggleOptionValue(notificationsOID, newNotificationsValue)
    endif
EndEvent


Event OnOptionSliderOpen(Int option)
    if option == outdoorIntervalOID
        SetSliderDialogStartValue(GetOutdoorIntervalMinutes())
        SetSliderDialogDefaultValue(5.0)
        SetSliderDialogRange(1.0, 30.0)
        SetSliderDialogInterval(1.0)
    endif
EndEvent


Event OnOptionSliderAccept(Int option, Float value)
    if option == outdoorIntervalOID
        SetOutdoorIntervalMinutes(value)
        SetSliderOptionValue(outdoorIntervalOID, value, "{0} min")
    endif
EndEvent


Event OnOptionDefault(Int option)
    if option == timedOutdoorOID
        SetTimedOutdoorEnabled(true)
        SetToggleOptionValue(timedOutdoorOID, true)
        SetOptionFlags(outdoorIntervalOID, OPTION_FLAG_NONE)

    elseif option == outdoorIntervalOID
        SetOutdoorIntervalMinutes(5.0)
        SetSliderOptionValue(outdoorIntervalOID, 5.0, "{0} min")

    elseif option == notificationsOID
        SetNotificationsEnabled(true)
        SetToggleOptionValue(notificationsOID, true)
    endif
EndEvent


Event OnOptionHighlight(Int option)
    if option == timedOutdoorOID
        SetInfoText("Enable periodic checkpoints while outdoors and outside combat. Save-based and interior-transition checkpoints are unaffected.")

    elseif option == outdoorIntervalOID
        SetInfoText("Real-time minutes between automatic outdoor checkpoints. Default: 5 minutes. Range: 1-30 minutes.")

    elseif option == notificationsOID
        SetInfoText("Show the 'Checkpoint updated.' notification when a checkpoint is created. Error notifications remain visible.")
    endif
EndEvent


Bool Function GetTimedOutdoorEnabled()
    if TimedOutdoorEnabled
        return TimedOutdoorEnabled.GetValue() >= 0.5
    endif

    return true
EndFunction


Function SetTimedOutdoorEnabled(Bool enabled)
    if TimedOutdoorEnabled
        if enabled
            TimedOutdoorEnabled.SetValue(1.0)
        else
            TimedOutdoorEnabled.SetValue(0.0)
        endif
    endif
EndFunction


Float Function GetOutdoorIntervalMinutes()
    Float value = 5.0

    if OutdoorIntervalMinutes
        value = OutdoorIntervalMinutes.GetValue()
    endif

    if value < 1.0
        value = 1.0
    elseif value > 30.0
        value = 30.0
    endif

    return value
EndFunction


Function SetOutdoorIntervalMinutes(Float value)
    if value < 1.0
        value = 1.0
    elseif value > 30.0
        value = 30.0
    endif

    if OutdoorIntervalMinutes
        OutdoorIntervalMinutes.SetValue(value)
    endif
EndFunction


Bool Function GetNotificationsEnabled()
    if ShowNotifications
        return ShowNotifications.GetValue() >= 0.5
    endif

    return true
EndFunction


Function SetNotificationsEnabled(Bool enabled)
    if ShowNotifications
        if enabled
            ShowNotifications.SetValue(1.0)
        else
            ShowNotifications.SetValue(0.0)
        endif
    endif
EndFunction
