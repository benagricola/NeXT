; M291.9 - Enhanced User Dialog with UI Integration
; Extended version of M291 that integrates with NeXT UI when available
;
; Usage: M291.9 P<message> [R<title>] [S<type>] [K<choices>] [F<default>] [T<timeout>]
;
; Parameters (same as M291):
; P = Message text (required)
; R = Title/Caption (optional, default: "NeXT")
; S = Dialog type (0=message, 1=message+close, 2=message+ok, 3=message+ok+cancel, 4=message+yes+no)
; K = Custom button labels as JSON array (optional)
; F = Default button index (optional, 0-based)
; T = Timeout in seconds (optional, default: 30)

; Validate required parameters
if { !exists(param.P) }
    abort "M291.9: Message parameter P is required"

; Set defaults
var message = { param.P }
var title = { exists(param.R) ? param.R : "NeXT" }
var dialogType = { exists(param.S) ? param.S : 2 }
var choices = { exists(param.K) ? param.K : null }
var defaultChoice = { exists(param.F) ? param.F : 0 }
var timeout = { exists(param.T) ? param.T : 30 }

; Check if UI is ready and this is an interactive dialog (S=4)
if { global.nxtUiReady && var.dialogType == 4 }
    ; Use UI for interactive dialogs
    echo "M291.9: Using UI for interactive dialog"
    
    ; Set up UI dialog data
    set global.nxtDialogMessage = { var.message }
    set global.nxtDialogTitle = { var.title }
    set global.nxtDialogChoices = { var.choices }
    set global.nxtDialogDefault = { var.defaultChoice }
    set global.nxtDialogTimeout = { var.timeout }
    set global.nxtDialogActive = true
    set global.nxtDialogResponse = null
    
    ; Wait for response with timeout
    var startTime = { state.upTime }
    while { global.nxtDialogResponse == null && (state.upTime - startTime) < var.timeout }
        G4 P200 ; Wait 200ms
    
    ; Process response
    if { global.nxtDialogResponse != null }
        ; Store response in input variable for compatibility
        set input = { global.nxtDialogResponse }
        echo "M291.9: UI response received: " ^ global.nxtDialogResponse
    else
        ; Timeout - default to cancel/no
        set input = 1
        echo "M291.9: UI dialog timeout after " ^ var.timeout ^ " seconds"
    
    ; Clean up
    set global.nxtDialogActive = false
    set global.nxtDialogResponse = null

else
    ; Fall back to standard M291 for all other cases
    echo "M291.9: Using standard M291 dialog"
    
    ; Execute M291 command directly with parameters
    ; Use null values for unset parameters
    M291 P{var.message} R{var.title} S{var.dialogType} K{var.choices} F{var.defaultChoice} T{var.timeout}