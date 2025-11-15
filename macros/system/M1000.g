; M1000.g: NEXT CUSTOM DIALOG DISPLAY
;
; This macro handles custom dialog display for NeXT UI integration.
; It provides an alternative to M291 that can be rendered in persistent UI sections
; rather than blocking the entire interface.
;
; USAGE: M1000 P<message> [R<title>] [K<choices>] [F<flag>]
;
; PARAMETERS:
; P<message> - Dialog message content (required)
; R<title>   - Dialog title (optional, defaults to "NeXT")
; K<choices> - Array of choice buttons (optional, e.g., K{"OK", "Cancel"})
; F<flag>    - Dialog behavior flag (optional):
;              0 = Non-blocking info (default)
;              1 = Requires user response 
;              2 = Critical/warning dialog
;
; BEHAVIOR:
; - If nxtUiReady is false, falls back to standard M291 dialog
; - If nxtUiReady is true, stores dialog data in global variables for UI pickup
; - Provides M292-compatible response handling

; Validate required message parameter
if { !exists(param.P) }
    abort "M1000: Message parameter P is required!"

; Set default values
var title = { exists(param.R) ? param.R : "NeXT" }
var flag = { exists(param.F) ? param.F : 0 }
var hasChoices = { exists(param.K) }

; If NeXT UI is not ready, fall back to standard M291
if { !global.nxtUiReady }
    if { var.hasChoices }
        if { exists(param.R) }
            M291 P{param.P} R{param.R} S4 K{param.K} F{var.flag}
        else
            M291 P{param.P} S4 K{param.K} F{var.flag}
    else
        if { exists(param.R) }
            M291 P{param.P} R{param.R} S3 F{var.flag}
        else
            M291 P{param.P} S3 F{var.flag}
    M99 ; Exit - M291 will handle the dialog

; --- NeXT UI Custom Dialog Handling ---

; Store dialog data in global variables for UI consumption
global nxtDialogMessage = { param.P }
global nxtDialogTitle = { var.title }
global nxtDialogFlag = { var.flag }
global nxtDialogActive = true
global nxtDialogResponse = null

; Store choices if provided
if { var.hasChoices }
    global nxtDialogChoices = { param.K }
    global nxtDialogHasChoices = true
else
    global nxtDialogChoices = null
    global nxtDialogHasChoices = false

; Generate unique sequence number for response tracking
global nxtDialogSeq = { (global.nxtDialogSeq == null) ? 1 : global.nxtDialogSeq + 1 }

; For blocking dialogs (flag = 1 or 2), wait for user response
if { var.flag == 1 || var.flag == 2 }
    ; Wait for UI to set nxtDialogResponse (with timeout)
    var timeout = 30000 ; 30 second timeout
    var waitStart = { state.upTime }
    
    while { global.nxtDialogResponse == null && (state.upTime - var.waitStart) < var.timeout }
        G4 P0.1 ; Brief pause to prevent busy waiting
    
    ; Check for timeout
    if { global.nxtDialogResponse == null }
        set global.nxtDialogActive = { false }
        abort "M1000: Dialog timeout - no user response received!"
    
    ; Store response for caller access
    set input = { global.nxtDialogResponse }
    
    ; Clear dialog state
    set global.nxtDialogActive = { false }
    set global.nxtDialogResponse = { null }

; For non-blocking dialogs (flag = 0), just display and continue
; The UI will automatically clear nxtDialogActive when dismissed

echo { "M1000: Custom dialog displayed - " ^ var.title }