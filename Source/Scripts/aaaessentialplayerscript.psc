Scriptname aaaEssentialPlayerScript extends ReferenceAlias  

import PO3_SKSEFunctions

int injuries = 0
float injuryrecovertime = 0.0
Spell property aaaGhost auto
Actor deadplayer
FormList property injuryPowers auto
int ghostthreshold = 1
aaaEssentialPlayerQuestScript property essentialQuest auto
Spell property configSpell auto
Armor property ClothesPrisonerTunic auto
Armor property UnPlayableColthesPrisonerTunic auto
float originalHealth = -1.0
Idle property idlestoploose auto
Idle property bleedoutstart auto
Idle property bleedoutstop auto
bool updated = false ; for new version
Quest property warewolfquest auto
ImpactDataSet property bleedImpact auto
MiscObject property Gold001 auto
Race property VampireLordRace auto
Race property WerewolfBeastRace auto
int previousCameraState = 0
GlobalVariable Property LocalPlayerIsBleedingOut auto
Spell Property HKPBCPartyBleedoutCheckSpell auto
SPELL Property HKPBCDetectionResetSpell Auto


; =========================================================
; CUSTOM CO-OP CHECKPOINT SYSTEM
; =========================================================

ObjectReference HKPBCRecallPoint

; 5 minutes réelles
Float OutdoorCheckpointInterval = 300.0

; F5 = DirectInput 63
Int QuickSaveKey = 63

Float lastOutdoorCheckpointTime = 0.0

Cell checkpointLastCell = None
Bool checkpointWasInterior = false

Bool checkpointSystemInitialized = false


; =========================================================
; INITIALISATION
; =========================================================

Event OnInit()

	InitializeCheckpointSystem()

	RegisterForSingleUpdate(1)

EndEvent


Event OnPlayerLoadGame()

	InitializeCheckpointSystem()

	RegisterForSingleUpdate(1)

EndEvent


; =========================================================
; CHECKPOINT INITIALIZATION
; =========================================================

Function InitializeCheckpointSystem()

	; HKPBCRecallPoint = FormID 000001 dans PartyBleedoutCheck.esp
	HKPBCRecallPoint = Game.GetFormFromFile(0x000001, "PartyBleedoutCheck.esp") as ObjectReference

	Actor Player = GetActorReference()

	if !Player
		return
	endif

	checkpointLastCell = Player.GetParentCell()
	checkpointWasInterior = Player.IsInInterior()

	; Réenregistre F5 à chaque chargement
	UnregisterForKey(QuickSaveKey)
	RegisterForKey(QuickSaveKey)

	; Le timer extérieur repart de zéro au chargement
	lastOutdoorCheckpointTime = Utility.GetCurrentRealTime()

	checkpointSystemInitialized = true

	Debug.Notification("Checkpoint system initialized.")

EndFunction


; =========================================================
; MAIN UPDATE
; =========================================================

Event OnUpdate()

	; Mise à jour du système de checkpoints
	UpdateCoopCheckpointSystem()

	;GetActorReference().DoCombatSpellApply(testSpell,GetActorReference())
	;GetActorReference().damageav("Health", 20)

	if (!GetActorReference().hasSpell(configSpell) && !essentialQuest.disableConfigSpell)
		GetActorReference().addSpell(configSpell, false)
	endif

	GetActorReference().StartDeferredKill()

	if (essentialQuest.mode != essentialQuest.ESSENTIALMODE)
		ghostthreshold = 1
	elseif (essentialQuest.mode == essentialQuest.ESSENTIALMODE)
		ghostthreshold = -1
	endif

	if (essentialQuest.mode == essentialQuest.HARDCOREMODE)
		; Upgrade fix to ensure those running on really old version hardcoremode are not left on that mode
		essentialQuest.mode = essentialQuest.NORMALMODE
	endif

	if (!updated)
		GetActorReference().SetNoBleedoutRecovery(false)	
		updated = true
	endif

	;if (deadplayer != none && deadplayer.getActorValue("InventoryWeight") <= 0 && deadplayer.isEnabled())
	;	deadplayer.disableNoWait(true)
	;	deadplayer.delete()
	;endif

	updateLogic()

	if (GetActorReference().getActorValue("Health") <= 0 && !getActorReference().isGhost() && !GetActorReference().isInKillMove())
		Debug.Trace("SMEssentialPlayer: Health less than 0 by timer")
		applyDyingLogic();
	endif

EndEvent


; =========================================================
; CHECKPOINT UPDATE LOGIC
; =========================================================

Function UpdateCoopCheckpointSystem()

	Actor Player = GetActorReference()

	if !Player
		return
	endif


	; -----------------------------------------------------
	; Si le système n'est pas initialisé, on le répare
	; automatiquement.
	; -----------------------------------------------------

	if !checkpointSystemInitialized

		InitializeCheckpointSystem()
		return

	endif


	; -----------------------------------------------------
	; Aucun checkpoint quand le joueur est KO / mort
	; -----------------------------------------------------

	if Player.GetActorValue("Health") <= 0
		return
	endif


	Cell currentCell = Player.GetParentCell()
	Bool currentlyInterior = Player.IsInInterior()


	; -----------------------------------------------------
	; CHANGEMENT DE CELLULE
	;
	; Extérieur -> extérieur : RIEN
	; Extérieur -> intérieur : CHECKPOINT
	; Intérieur -> extérieur : CHECKPOINT
	; Intérieur -> intérieur : CHECKPOINT
	; -----------------------------------------------------

	if currentCell != checkpointLastCell

		Bool previousInterior = checkpointWasInterior

		checkpointLastCell = currentCell
		checkpointWasInterior = currentlyInterior


		if previousInterior || currentlyInterior

			; Laisse terminer la transition de cellule
			Utility.Wait(2.0)

			SetCoopCheckpoint()
			return

		endif

	endif


	; -----------------------------------------------------
	; Sécurité si le statut intérieur/extérieur change
	; sans que la cellule ait été détectée correctement
	; -----------------------------------------------------

	if currentlyInterior != checkpointWasInterior

		checkpointWasInterior = currentlyInterior
		checkpointLastCell = currentCell

		Utility.Wait(2.0)

		SetCoopCheckpoint()
		return

	endif


	; -----------------------------------------------------
	; CHECKPOINT AUTOMATIQUE 5 MIN
	; UNIQUEMENT EN EXTERIEUR
	; -----------------------------------------------------

	if !currentlyInterior

		Float currentTime = Utility.GetCurrentRealTime()

		if currentTime - lastOutdoorCheckpointTime >= OutdoorCheckpointInterval

			; Pas de checkpoint automatique pendant un combat
			if !Player.IsInCombat()

				SetCoopCheckpoint()

			endif

		endif

	endif

EndFunction


; =========================================================
; F5 / QUICKSAVE
; =========================================================

Event OnKeyDown(Int keyCode)

	if keyCode == QuickSaveKey

		Actor Player = GetActorReference()

		if Player

			if Player.GetActorValue("Health") > 0

				SetCoopCheckpoint()

			endif

		endif

	endif

EndEvent


; =========================================================
; CREATION DU CHECKPOINT
; =========================================================

Function SetCoopCheckpoint()

	Actor Player = GetActorReference()

	if !Player
		return
	endif


	; Aucun checkpoint en bleedout
	if Player.GetActorValue("Health") <= 0
		return
	endif


	; Si la référence a été perdue, on la récupère
	if !HKPBCRecallPoint

		HKPBCRecallPoint = Game.GetFormFromFile(0x000001, "PartyBleedoutCheck.esp") as ObjectReference

	endif


	if !HKPBCRecallPoint

		Debug.Notification("Checkpoint marker not found.")
		return

	endif


	HKPBCRecallPoint.MoveTo(Player, 0.0, 0.0, 0.0, true)


	; Tout checkpoint remet le compteur des 5 minutes à zéro
	lastOutdoorCheckpointTime = Utility.GetCurrentRealTime()


	Debug.Notification("Checkpoint updated.")

EndFunction


; =========================================================
; ORIGINAL SM ESSENTIAL PLAYER CODE
; =========================================================

bool bleedingOut = false


Function applyDyingLogic()

	;HKBPC: added section to apply bleedout check spell. START
	
	LocalPlayerIsBleedingOut.SetValue(1)
	HKPBCPartyBleedoutCheckSpell.RemoteCast(Game.GetPlayer(), Game.GetPlayer(), Game.GetPlayer())
	PreventActorDetection(Game.GetPlayer())
	GetActorReference().StopCombatAlarm()
		
	;HKBPC: END
	
	GotoState("HandleBleedOut")

	;HKBPC: commented out setghost, as otherwise spellcast won't work. START
	;GetActorReference().setGhost(true)
	;HKPBC END

	if (essentialQuest.losemoney > 0)

		int totalgold = GetActorReference().getItemCount(Gold001)

		if (totalgold > 0)

			int goldtoremove = totalgold / (100 / essentialQuest.losemoney)
			GetActorReference().removeItem(Gold001, goldtoremove)

		endif

	endif


	injuries = injuries + 1
	injuryrecovertime = Utility.getCurrentRealTime()


	If (isGhostMode())

		setHealthAfterBleedOut(true)
		makeGhost()

	else

		bleedingOut = true

		Game.DisablePlayerControls()

		if (isFirstPerson())

			GetActorReference().SetUnconscious(true);
			previousCameraState = Game.GetCameraState()

			Debug.Trace("SMEssentialPlayer: Current camera state:" + previousCameraState)

			if (isSafeCamera(previousCameraState) && previousCameraState != 0 && !isMorphed())

				Game.ForceFirstPerson()
				Game.ShakeCamera(none, 0.5, 5)

			endif	

		else

			previousCameraState = Game.GetCameraState()

			if (isSafeCamera(previousCameraState) && previousCameraState != 8 && previousCameraState != 9)

				Game.ForceThirdPerson()

			endif

			GetActorReference().PlayIdle(bleedoutstart)

		endif

	endif

	RegisterForSingleUpdate(0.1)

endFunction


Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, \
  bool abBashAttack, bool abHitBlocked)

	if (getActorReference().isGhost())
		return
	endif

	if (getActorReference().isInKillMove())
		return
	endif

	if (GetActorReference().getActorValue("Health") <= 0)

		Debug.Trace("SMEssentialPlayer: Health less than 0 by hit")
		applyDyingLogic();

	endif

EndEvent


Function recoverBleedOut()

	;HK: to determine local player BO state outside this script.
	LocalPlayerIsBleedingOut.SetValue(0)
	HKPBCDetectionResetSpell.RemoteCast(Game.GetPlayer(), Game.GetPlayer(), Game.GetPlayer())
	ResetActorDetection(Game.GetPlayer())
	
	Debug.Trace("SMEssentialPlayer: Current camera state recover:" + camerastate)

	setHealthAfterBleedOut(false)

	int camerastate = Game.GetCameraState()

	if (isFirstPerson())

		if (isSafeCamera(camerastate) && (previousCameraState == 8 || previousCameraState == 9))

			Game.ForceThirdPerson()

		endif

	else

		GetActorReference().PlayIdle(bleedoutstop)

		Utility.wait(2)

		if (isSafeCamera(camerastate) && previousCameraState == 0)

			Game.ForceFirstPerson()

		endif


		Form leftHand = GetActorReference().GetEquippedObject(0)
		Form rightHand = GetActorReference().GetEquippedObject(1)


		if (leftHand as Spell != none)

			GetActorReference().UnequipSpell((leftHand as Spell), 0)
			GetActorReference().EquipSpell((leftHand as Spell), 0)

		elseif (leftHand != none)

			GetActorReference().UnequipItemEx(leftHand, 2)
			GetActorReference().EquipItemEx(leftHand, 2)

		endif


		if (rightHand as Spell != none)

			GetActorReference().UnequipSpell((rightHand as Spell), 1)
			GetActorReference().EquipSpell((rightHand as Spell), 1)

		elseif (rightHand != none)

			GetActorReference().UnequipItemEx(rightHand, 1)
			GetActorReference().EquipItemEx(rightHand, 1)

		endif

	endif


	Game.EnablePlayerControls()

	GetActorReference().SetUnconscious(false);

	addInjury()

	setHealthAfterBleedOut(false)

	GotoState("")

	GetActorReference().PlayIdle(idlestoploose)

endfunction


State HandlingKillMove

	Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, \
	bool abBashAttack, bool abHitBlocked)

		;Do Nothing

	EndEvent

EndState


State HandleBleedOut

	Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, \
	bool abBashAttack, bool abHitBlocked)

		;Do Nothing

	EndEvent


	Function updateLogic()

		if (bleedingOut)

			if game.GetPlayer().GetActorValuePercentage("health") >= 0.66

				recoverBleedOut()

			elseif (isFirstPerson())

				GetActorReference().PlayImpactEffect(bleedImpact);

			endif

		endif

		RegisterForSingleUpdate(0.1)

	EndFunction
	

	Function applyDyingLogic()

		; do nothing

	endFunction

EndState


Function updateLogic()

	if (injuries > 0)

		if (Utility.getCurrentRealTime() - injuryrecovertime >= 30)

			Debug.Trace("SMEssentialPlayer: Reset injuries to 0")
			injuries = 0

		endif

	endif

	RegisterForSingleUpdate(1)

EndFunction


function makeGhost()

	Debug.Trace("SMEssentialPlayer: Ghost Reset injuries to 0")

	injuries = 0

	GetActorReference().StopCombatAlarm()
	GetActorReference().setGhost(false)

	GetActorReference().DoCombatSpellApply(aaaGhost,GetActorReference())

	if (deadplayer != none && deadplayer.isEnabled())

		if (essentialQuest.ishardcore != essentialQuest.HARDCOREGHOST)

			deadplayer.removeAllItems(GetActorReference(), true, false)

		endif

		deadplayer.disableNoWait(true)
		deadplayer.delete()

	endif


	int i = 0

	Actor tmpdeadplayer = GetActorReference().PlaceAtMe(GetActorReference().getActorBase(), 1, true, false) as Actor

	tmpdeadplayer.removeAllItems()


	if (essentialQuest.ishardcore != essentialQuest.EASYGHOST)

		GetActorReference().unequipAll()

	endif


	if (essentialQuest.ishardcore == essentialQuest.HARDCOREGHOST)

		GetActorReference().removeAllItems()

	elseif (essentialQuest.ishardcore == essentialQuest.NORMALGHOST)

		GetActorReference().removeAllItems(tmpdeadplayer, true, false)

	endif


	tmpdeadplayer.enableNoWait(true)
	tmpdeadplayer.kill()

	deadplayer = tmpdeadplayer


	if (essentialQuest.ishardcore == essentialQuest.HARDCOREGHOST)

		GetActorReference().addItem(ClothesPrisonerTunic, 1, true)
		GetActorReference().equipItem(ClothesPrisonerTunic, false, true)

	endif


	GoToState("")

	GetActorReference().PlayIdle(idlestoploose)

endfunction


function addInjury()

	if (essentialQuest.mode == essentialQuest.ESSENTIALMODE)

		injuries = 0

	endif


	if (essentialQuest.disableinjuries == 0)

		int chosen = Utility.RandomInt(0, injuryPowers.getSize() - 1)

		Spell injury = injuryPowers.getAt(chosen) as Spell

		GetActorReference().DoCombatSpellApply(injury,GetActorReference())

	endif

endfunction


bool function isSafeCamera(int cameramode)

	return cameramode == 0 || cameramode == 8 || cameramode == 9

endfunction


bool function isGhostMode()

	return (essentialQuest.mode == essentialQuest.GHOSTMODE || (ghostthreshold != -1 && injuries > ghostthreshold))

endfunction


bool function isFirstPerson()

	return (essentialQuest.essentialtype == essentialQuest.FIRSTPERSON || isMorphed()) 

endfunction


bool function isMorphed()

	Race playerRace = GetActorReference().getRace()

	return playerRace == WerewolfBeastRace || playerRace == VampireLordRace 

endfunction


function setHealthAfterBleedOut(bool maxhealth)

	GetActorReference().damageav("Health", 1)

	float health = GetActorReference().getActorValue("Health")


	if (maxhealth)

		GetActorReference().restoreav("Health",GetActorReference().getBaseActorValue("Health"))

	else

		int toheal = (GetActorReference().getBaseActorValue("Health") / (100 / essentialQuest.healthToHeal)) as int


		if (health < 0)

			GetActorReference().restoreav("Health", (health * -1) + toheal)

		elseif (health > toheal)

			GetActorReference().damageav("Health", health - toheal)
			GetActorReference().restoreav("Health",1)

		else

			GetActorReference().restoreav("Health", (toheal - health) + 1)

		endif

	endif

	bleedingOut = false

EndFunction