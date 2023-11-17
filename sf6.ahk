#Requires AutoHotkey v2.0
#SingleInstance Force

; Instructions (jank first draft)
; 1. Find kCharacters, fill that list with the characters you want to change.
;    The first entry will have all recordings overwritten, the rest only the
;    quantity that you specify in the sequences list.
; 2. Verify that your keyboard settings match mine. In particular, make sure
;    that in game, kDu is jump (I have it set to space in game but up is still
;    w in the menu).
; 3. With this script running, place your cursor on "Training" in the fighting
;    ground and press F11.
; 4. Press F10 to stop the script early if necessary.


; May increase for slower computer
kLoadPlaySeconds := 15

; I really wanted to be able to combine any number of buttons with a clean
; operation, so I used bitmasks, combineable through "+" or "|". If I do another
; pass, I would make some variable arg functions that can combine strings the
; way we need.
kLp := 1 << 0
kMp := 1 << 1
kHp := 1 << 2 
kLk := 1 << 3
kMk := 1 << 4 
kHk := 1 << 5
kDu := 1 << 6
kDl := 1 << 7
kDd := 1 << 8
kDr := 1 << 9
; Menu buttons
kMUp := 1 << 10
kMLt := 1 << 11
kMRt := 1 << 12
kStart := 1 << 13
kConfirm := 1 << 14
kDelete := 1 << 15
; Chords
kThrow := kLp + kLk
kParry := kMp + kMk
kDI := kHp + kHk
kBlock := kDd + kDl

kButtonToDownUp := [
    ["{u down}", "{u up}"],
    ["{i down}", "{i up}"],
    ["{o down}", "{o up}"],
    ["{j down}", "{j up}"],
    ["{k down}", "{k up}"],
    ["{l down}", "{l up}"],
    ["{space down}", "{space up}"],
    ["{a down}", "{a up}"],
    ["{s down}", "{s up}"],
    ["{d down}", "{d up}"],
    ["{w down}", "{w up}"],
    ["{q down}", "{q up}"],
    ["{e down}", "{e up}"],
    ["{tab down}", "{tab up}"],
    ["{f down}", "{f up}"],
    ["{backspace down}", "{backspace up}"],
]

kSecond := 60

Sf6GlobalState := {
    isFirst: true,
    prevCharAddress : [],
}

F11::
{
    Sf6DoAll()
}

Sf6DoAll() {
    global Sf6GlobalState
    for pair in kCharacters {
        addr := pair[1]
        if Sf6GlobalState.isFirst {
            Sf6SelectCharacterScreenFromFG()
            Sf6SelectCharacterAddress(addr, true)
            Sf6SelectCharacterAddress(addr, false)
        } else {
            Sf6SelectCharacterScreenFromPlay()
            Sf6MenuSequence(Sf6GlobalState.prevCharAddress)
            Sf6SelectCharacterAddress(addr, true)
            Sf6MenuSequence(Sf6GlobalState.prevCharAddress)
            Sf6SelectCharacterAddress(addr, true)
        }
        Sf6WaitFrames(kLoadPlaySeconds * kSecond)
        Sf6GlobalState.prevCharAddress := Sf6SequenceMenuReflect(addr)

        Sf6PlayGrabP2AsP1()
        if Sf6GlobalState.isFirst {
            Sf6SettingsRecordFixAll()
        }
        Sf6RecordSequences(pair[2])
        Sf6GlobalState.isFirst := false
    }
}

Sf6WaitFrames(count) {
    if GetKeyState("F10") {
        Sf6KeyUpdate(0)
        Exit
    }
    DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
    DllCall("QueryPerformanceCounter", "Int64*", &counterBefore := 0)
    while true {
        Sleep 0
        DllCall("QueryPerformanceCounter", "Int64*", &counterAfter := 0)
        if (counterAfter - counterBefore) / freq * 1000 > (count * 16.666) {
            break
        }
    }
}

Sf6CurrentBits := 0
Sf6KeyUpdate(newBits) {
    Global Sf6CurrentBits
    Loop kButtonToDownUp.Length {
        i := A_Index - 1
        bitmask := 1 << i
        inCurrent := Sf6CurrentBits & bitmask 
        inNew := newBits & bitmask
        if inNew && !inCurrent {
            Send kButtonToDownUp[i + 1][1]
        }
        if !inNew && inCurrent {
            Send kButtonToDownUp[i + 1][2]
        }
    }
    Sf6CurrentBits := newBits
}

Sf6PlaySequence(sequence) {
    for pair in sequence {
        Sf6KeyUpdate(pair[1])
        Sf6WaitFrames(pair[2])
    }
    Sf6KeyUpdate(0)
}

Sf6PlayGrabP2AsP1() {
    Sf6PlaySequence([
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kThrow + kDl, 2], [0, 200],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
        [kDr, 2], [0, 2], [kDr, 2], [0, 40],
    ])
}

Sf6SequenceMenuReflect(sequence) {
    reflected := []
    for key in sequence {
        ; Flip left and right
        if key = kDr { 
            reflected.InsertAt(1, kDl)
        } else if key = kDl {
            reflected.InsertAt(1, kDr)
        } else if key = kDd {
            reflected.InsertAt(1, kMup)
        } else if key = kMUp {
            reflected.InsertAt(1, kDd)
        }
    }
    return reflected
}

Sf6MenuSequence(sequence) {
    for key in sequence {
        Sf6KeyUpdate(key)
        Sf6WaitFrames(2)
        Sf6KeyUpdate(0)
        Sf6WaitFrames(13)
    }
}

Sf6MenuOpen() {
    Sf6MenuSequence([
        kStart,
        kMLt + kMRt,
    ])
}

Sf6SettingsRecordFixAll() {
    kResetToRecording := [kMLt + kMRt, kMRt, kMRt, kMRt]
    kDeleteAll := [
        kDd, kDelete, kDd, kDelete, kDd, kDelete, kDd, kDelete, kDd, kDelete,
        kDd, kDelete, kDd, kDelete, kDd, kDelete, kDd, kDelete, kDd, kDelete,
    ]

    Sf6MenuOpen()
    ; First, guarantee no existing recordings
    Sf6MenuSequence(kResetToRecording)
    Sf6MenuSequence(kDeleteAll)
    Sf6MenuSequence(kResetToRecording)
    Sf6MenuSequence([KDd, kDd, kDr])
    Sf6MenuSequence(kDeleteAll)
    ; Next guarantee "Record"
    Sf6MenuSequence(kResetToRecording)
    ; Use odd option count of Replay Info Display to guarantee we end at replay
    Sf6MenuSequence([kDd, kDd, kDd, kDr, kDr, kDr])
    ; Then swap to record
    Sf6MenuSequence(kResetToRecording)
    Sf6MenuSequence([kMUp, kDr, kMUp, kMUp])
    ; Now guarantee "On Input"
    ; If on input, won't record. On Auto, will record
    Sf6MenuSequence(kResetToRecording)
    Sf6MenuSequence([kMUp, kConfirm, 0, 0, kStart, 0])
    Sf6MenuSequence([kDd, kDd, kDd, kDr, kDd, kDr, kDr, kDr])
    ; will pos on 8/Record on auto, put input to replay info display
    Sf6MenuSequence([kMup, kMup, kMup, kMup, kMup, kMup, kMup, kMup, kMup, 
        kDr, kDr, kDr])
    ; redo the guarantee of record
    Sf6MenuSequence(kResetToRecording)
    Sf6MenuSequence([kDd, kDd, kDd, kDr, kDr, kDr])
    Sf6MenuSequence(kResetToRecording)
    Sf6MenuSequence([kDd, kDd, kDr, kMup, kMup, kMup, kDelete, kStart, 0, 0])

}

; Sf6SettingsToggleRecordTrigger() {
;     Sf6MenuOpen()
;     Sf6MenuSequence([
;         kMRt, kMRt, kMRt, kDr, kStart,
;     ])
; }

; Sf6SettingsP1SideRight() {
;     Sf6MenuOpen()
;     Sf6MenuSequence([
;         kMRt, kDd, kDd, kDd, kDr, kStart,
;     ])
; }

; Sf6SettingsFrameMeter() {
;     Sf6MenuOpen()
;     Sf6MenuSequence([
;         kMLt, kMLt, kDd, kDd, kDd, kDr, kStart,
;     ])
; }

; Sf6SettingsInit() {
;     if kRestoreDefaultSettings {
;         Sf6MenuOpen()
;         Sf6MenuSequence([
;             kMUp, kMUp, kMUp, kMUp, 
;             0, 0,
;             kConfirm,
;             0, 0,
;             kConfirm,
;         ])
;         Sf6WaitFrames(3 * kSecond)
;     }
;     Sf6SettingsToggleRecordTrigger()
;     Sf6SettingsP1SideRight()
;     Sf6SettingsFrameMeter()
; }

Sf6RecordToSlot(slot) {
    ; one based indexing as slots are named
    Sf6MenuOpen()
    Sf6MenuSequence([
        kMRt,
        kMRt,
        kMRt,
    ])
    if slot < 5 {
        Loop 1 + slot {
            Sf6MenuSequence([kDd])
        }
    } else {
        Loop 1 + 8 - slot {
            Sf6MenuSequence([kMup])
        }
    }
    Sf6MenuSequence([kConfirm])
    Sf6WaitFrames(kSecond)
}

Sf6RecordFinish() {
    Sf6MenuSequence([
        kStart, 0, kStart, 0,
    ])
}

Sf6RecordSequences(sequences) {
    local i := 0
    for seq in sequences {
        i += 1
        Sf6RecordToSlot(i)
        Sf6PlaySequence(seq)
        Sf6RecordFinish()
    }
}

Sf6SelectCharacterScreenFromFG() {
    Sf6MenuSequence([
        kConfirm, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        kConfirm, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        kConfirm, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ])
}

Sf6SelectCharacterScreenFromPlay() {
    Sf6MenuOpen()
    Sf6MenuSequence([kMup, kConfirm, 0, 0, kConfirm])
    Sf6WaitFrames(2 * kSecond)
}

Sf6SelectCharacterAddress(charAddress, isPlayer1) {
    if !isPlayer1 {
        Sf6MenuSequence([kDl])
    }
    Sf6MenuSequence(charAddress)
    Sf6MenuSequence([kConfirm, kConfirm])
}

kDash := [[kDl, 2], [kDl, 2]]
kS236 := [
    [kDd, 2], [kDd + kDr, 2], [kDr, 2],
]
kS623 := [
    [kDr, 2],
    [kDd, 2],
    [kDr, 2],
]
kS4268 := [
    [kDl, 2],
    [kDd, 2],
    [kDr, 2],
    [kDu, 2],
]
kSDriveRush := [
    [kParry + kDr, 2], [kParry, 2], [kParry + kDr, 2], [kParry, 2],
    [kParry + kDr, 2],
    [0, 9], ; Screen freeze and minimum delay
    [0, 5], ; go a little further
]

Sf6UniversalJumpIn(normal) {
    return [[kDr + kDu, 2], [0, 28], [normal, 2], [kBlock, 50],]
}
kUniversalShimmyRight := [ [kDr, 12], [kDl, 7], ]
kUniversalShimmyLeft := [ [kDr, 7], [kDl, 12], ]
kUniversalThrow := [ [kThrow, 2], [kBlock, 160], ]
kUniversalDashThrow := [
    [kDr, 3], [0, 2], [kDr, 2], [0, 18],
    [kThrow, 2], [kBlock, 160],
]

kLukeAddress := []
kLukeJumpIn := Sf6UniversalJumpIn(kLk)
kLukeRunPunch := []
kLukeRunPunch.Push(kS236*)
kLukeRunPunch.Push(
    [kHk, 2], [0, 10],
    [kHp, 2],
    [kBlock, 80],
)

kLukeRunKick := []
kLukeRunKick.Push(kS236*)
kLukeRunKick.Push(
    [kHk, 2], [0, 10],
    [kHk, 2],
    [kBlock, 80],
)

kLukeHpSandBlast := [
    [kHp, 2], [0, 10],
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kHp, 2],
    [kBlock, 100],
]

kLukeFastKnuckle := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kHp, 2],
    [kBlock, 90],
]

kLukePerfectKnuckle := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kHp, 18],
    [kBlock, 90],
]

kLukeSequences := [
    kLukeJumpIn,
    kLukeRunPunch,
    kLukeRunKick,
    kLukeHpSandBlast,
    kLukePerfectKnuckle,
    ; kLukeFastKnuckle,
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
]

kJamieAddress := [kDr]
kJamieJumpIn := [
    [kDr + kDu, 2], [0, 28], [kMk, 2], [kBlock, 50],
]
kJamiePalm := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kHp, 2],
    [kBlock, 80],
]
kJamieODPalm := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kMp + kHp, 2], [kBlock, 80],
]
kJamieSweep := [
    [kDd + kHk, 2],
    [kBlock, 80],
]
kJamieSequences := [
    kJamieJumpIn,
    kJamiePalm,
    kJamieODPalm,
    kJamieSweep,
]

kManonAddress := [kDd, kDl]
kManonJumpIn := [
    [kDr + kDu, 2], [0, 28], [kMk, 2], [kBlock, 50],
]
kManonEnHaut := [
    [kDl + kMk, 2], [0, 12], [kMk, 2], [kBlock, 90],
]
kManonDegageL := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kLk, 2], [kBlock, 140],
]
kManonDegageM := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kMk, 2], [kBlock, 140],
]
kManonDegageH := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kHk, 2], [kBlock, 140],
]
kManonSequences := [
    kManonJumpIn,
    kManonEnHaut,
    kManonDegageL,
    kManonDegageM,
    kManonDegageH,
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
]

kKimberlyAddress := [kDd]
kKimberlyJumpIn := Sf6UniversalJumpIn(kMk)
kKimberlySequences := [
    kKimberlyJumpIn,
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
]

kMarisaAddress := [kDd, kDr]
kMarisaJumpIn := Sf6UniversalJumpIn(kLk)
kMarisaMMGladius := [
    [kMp, 2], [0, 12], [kMp, 2], [0, 12],
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kMp, 2],
    [kBlock, 90],
]
kMarisaSequences := [
    kMarisaJumpIn,
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    kMarisaMMGladius,
]

kJPAddress := [kDd, kDd, kDl]
kJPJumpIn := Sf6UniversalJumpIn(kLk)
kJPMp := [[kMp, 2], [kBlock, 65]]
kJPEmbrace := [
    [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kHk, 2], [kBlock, 130],
]
kJPTorbalanM := [
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kMk, 2], [kBlock, 60],
]
kJPTorbalanH := [
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kHk, 2], [kBlock, 60],
]
kJPTorbalanFeint := [
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kHk, 20], [kBlock, 16]
]
kJPSequences := [
    kJPJumpIn,
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    ; kUniversalShimmyRight,
    kJPMp,
    kJPTorbalanFeint,
    kJPTorbalanH,
    kJPTorbalanM,
    kJPEmbrace, ; Always last to so the recovery doesn't interfere
]

kJuriAddress := [kDd, kDd]
kJuriSequences := [
    Sf6UniversalJumpIn(kMk),
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
]

;DJ
; clk clp qcf lk, throw
; dr mp, cmp cmp, mk 
; jab jab mk
; jab jab medium sobat
; jab jab qcbk l
; jab jab qcbk m 
; jump in knee

kDeeJayAddress := [kDd, kDd, kDr]
kDeeJayDRPrefix := kSDriveRush.Clone()
kDeeJayDRPrefix.Push([kDd + kLp, 2], [0, 8], [kDd + kLp, 2], [0, 6])
kDeeJayDRFeintThrow := kDeeJayDRPrefix.Clone()
kDeeJayDRFeintThrow.Push(
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kLk, 2], [0, 37],
    [kThrow, 2], [kBlock, 160],
)
kDeeJayDRMk := kDeeJayDRPrefix.Clone()
kDeeJayDRMk.Push([0, 28], [kMk, 2], [0, 25], [kBlock, 30])
kDeeJayDR2Mk := kDeeJayDRPrefix.Clone()
kDeeJayDR2Mk.Push([0, 28], [kDd + kMk, 2], [0, 25], [kBlock, 30])
kDeeJayDRFeintThrow := kDeeJayDRPrefix.Clone()
kDeeJayDRFeintThrow.Push(
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kLk, 2], [0, 37],
    [kThrow, 2], [kBlock, 160],
)
kDeeJayDRFeintJabs := kDeeJayDRPrefix.Clone()
kDeeJayDRFeintJabs.Push(
    [kDd, 2], [kDd + kDr, 2], [kDr, 2], [kLk, 2], [0, 37],
    [kLp, 2], [kBlock, 40],
)
kDeeJaySequences := [
    Sf6UniversalJumpIn(kDd + kLk),
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    kDeeJayDRMk,
    kDeeJayDR2Mk,
    kDeeJayDRFeintThrow,
    kDeeJayDRFeintJabs,
]

kCammyAddress := [kDd, kDd, kDr, kDr]
kCammySequences := [
    [[kDr + kDu, 2], [0, 28], [kHk, 2], [kBlock, 28]],
    [[kDl + kDu, 2], [kBlock, 55]],
    [[kDu, 2], [kBlock, 55]],
    [[kDr + kDu, 2], [0, 20], [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kMk, 2],
        [kBlock, 50]],
    [[kDr + kDu, 2], [0, 45], [kThrow, 5], [0, 18]],
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    [[kDI, 2], [0, 2]],
    ; [[kThrow, 2], [0, 2]],
    ; kSDriveRush,
    ; [[kHk, 2], [kBlock, 40]],
    ; [[kDd + kHk, 2], [kBlock, 40]],
    ; [[kDd + kHp, 2], [kBlock, 40]],
]

kRyuAddress := [kDd, kDd, kDd, kDl]
kRyuSequences := [
    Sf6UniversalJumpIn(kMk),
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    [[kThrow, 2], [0, 2]],
    kSDriveRush,
    [[kHk, 2], [kBlock, 40]],
    [[kDd + kHk, 2], [kBlock, 40]],
    [[kDd + kHp, 2], [kBlock, 40]],
]

KEHondaAddress := [kDd, kDd, kDd]
kEHondaSequences := [
    [[kBlock, 46], [kDu + kLk, 2]],
    [[kBlock, 46], [kDu + kMk, 2]],
    [[kBlock, 46], [kDu + kHk, 2]],
    [[kBlock, 46], [kDu + kHk + kLk, 2]],
    [[kBlock, 46], [kDr + kLp, 2]],
    [[kBlock, 46], [kDr + kMp, 2]],
    [[kBlock, 46], [kDr + kHp, 2]],
    [[kBlock, 46], [kDr + kHp + kLp, 2]],
]

KBlankaAddress := [kDd, kDd, kDd, kDr]
kBlankaSequences := [
    [[kBlock, 23], [kDl + kDu, 23], [kDr + kLp, 2]],
    [[kBlock, 23], [kDl + kDu, 23], [kDr + kMp, 2]],
    [[kBlock, 23], [kDl + kDu, 23], [kDr + kHp, 2]],
    [[kBlock, 23], [kDl + kDu, 23], [kDr + kHp + kLp, 2]],
    [[kBlock, 46], [kDr + kLp, 2]],
    [[kBlock, 46], [kDr + kMp, 2]],
    [[kBlock, 46], [kDr + kHp, 2]],
    ; OD Ball has to be last as it switches sides
    [[kBlock, 46], [kDr + kHp + kLp, 2]],
]

kGuileAddress := [kDd, kDd, kDd, kDr, kDr]
kGuileSequences := [
    Sf6UniversalJumpIn(kLk),
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    [[kThrow, 2], [0, 2]],
    kSDriveRush,
    [[kHk, 2], [kBlock, 40]],
    [[kDd + kHk, 2], [kBlock, 40]],
    [[kDd + kHp, 2], [kBlock, 40]],
]

kKenAddress := [kDd, kDd, kDd, kDd, kDl]
; DragonLash seems to have 10 or so frames of hitstun
kKenDragonLashThrow := []
kKenDragonLashThrow.Push(kS623*)
kKenDragonLashThrow.Push(
    [kHk, 2], [0, 63],
    [kThrow, 2], [kBlock, 160]
)
kKenDragonLashJabs := []
kKenDragonLashJabs.Push(kS623*)
kKenDragonLashJabs.Push(
    [kHk, 2], [0, 63],
    [kLp, 2], [0, 9],
    [kLp, 2], [0, 12],
)
kKenDragonLashJabs.Push(kS236*)
kKenDragonLashJabs.Push(
    [kLk, 2], [0, 40],
    [kDr + kLk, 2], [kBlock, 75],
)
kKenRunStepKick := [
    [kLk + kMk, 2], [0, 16],
    [kHk, 2], [kBlock, 75],
]
kKenRunThunderKick := [
    [kLk + kMk, 2], [0, 16],
    [kMk, 2], [kBlock, 75],
]
kKenDRThrow := []
kKenDRThrow.Push(kSDriveRush*)
kKenDRThrow.Push(
    [kThrow, 5], [kBlock, 160]
)
kKenDRHp := []
kKenDRHp.Push(kSDriveRush*)
kKenDRHp.Push(
    [kHp, 2], [0, 43],
    [kLp, 2], [0, 10],
    [kBlock, 25]
)
kKenMk := [
    [kMk, 4], 
    [kBlock, 65],
]
kKenHk := [
    [kHk, 4], 
    [kBlock, 75],
]

kKenSequences := [
    kKenDragonLashThrow,
    kKenDragonLashJabs,
    kKenRunStepKick,
    kKenRunThunderKick,
    ; kKenDRThrow,
    ; kKenDRHp,
    kKenMk,
    ; kKenHk,
    kUniversalDashThrow,
    kUniversalShimmyLeft,
    kUniversalShimmyRight
]

kChunLiAddress := [kDd, kDd, kDd, kDd]
kChunLiSequences := [
    Sf6UniversalJumpIn(kMk),
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    [[kThrow, 2], [0, 2]],
    kSDriveRush,
    [[kHp, 2], [kBlock, 40]],
    [[kDd + kMk, 2], [kBlock, 40]],
    [[kDd + kHk, 2], [kBlock, 40]],
]

kZangiefAddress := [kDd, kDd, kDd, kDd, kDr]
kZangiefKneeSpd := [
    [kDr + kMk, 2], [kBlock, 40],
    [kDl, 2], [kDd, 2], [kDr, 2], [kDu, 1], [kDu + kLp, 4],
]
kZangiefSequences := [
    Sf6UniversalJumpIn(kLk),
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    kUniversalDashThrow,
    [[kDr + kHk, 2], [kBlock, 80]],
    kZangiefKneeSpd,
    [[kDr, 2], [kDd, 2], [kDd + kDl, 2], [kDl, 2], [kLk, 2], [kBlock, 2]],
    [[kDd + kHk, 2], [kBlock, 40]],
]

kDhalsimAddress := [kDd, kDd, kDd, kDd, kDr, kDr]
kDhalsimSequences := [
    kUniversalShimmyRight,
    [[kMp, 2], [0, 2]],
    [[kHp, 2], [0, 2]],
    [[kDd + kMp, 2], [0, 2]],
    [[kDd + kHp, 2], [0, 2]],
    [[kLk, 2], [0, 2]],
    [[kMk, 2], [0, 2]],
    [[kHk, 2], [0, 2]],
]

kRashidAddress := [kDd, kDd, kDd, kDd, kDd]
kRashidSequences := [
    Sf6UniversalJumpIn(kMk),
    kUniversalShimmyLeft,
    kUniversalShimmyRight,
    kUniversalDashThrow,
    [[kDd, 4], [kDd + kDr, 2], [kDr, 2], [kLp, 2], [0, 54], [kLp, 2], [0, 4]],
    [[kDd, 4], [kDd + kDr, 2], [kDr, 2], [kLp, 2], [0, 54],
        [kThrow, 2], [kBlock, 160]],
    [[kDr + kHp, 2], [0, 2]],
    [[kDd, 4], [kDd + kDl, 2], [kDl, 2], [kDl + kLp, 2], [kDl, 5],
        [kDl + kLk, 45], [0, 2], [kHk, 2], [kBlock, 50]],
]

kCharacters := [
    [kRyuAddress, kRyuSequences],
    [kLukeAddress, kLukeSequences],
    [kJamieAddress, kJamieSequences],
    [kManonAddress, kManonSequences],
    [kKimberlyAddress, kKimberlySequences],
    [kMarisaAddress, kMarisaSequences],
    [kJPAddress, kJPSequences],
    [kJuriAddress, kJuriSequences],
    [kDeeJayAddress, kDeeJaySequences],
    [kCammyAddress, kCammySequences],
    [kEHondaAddress, kEHondaSequences],
    [kBlankaAddress, kBlankaSequences],
    [kGuileAddress, kGuileSequences],
    [kKenAddress, kKenSequences],
    [kChunLiAddress, kChunLiSequences],
    [kZangiefAddress, kZangiefSequences],
]
