; nxt-ui-helper.g
; Helper macro for UI interaction patterns
;
; Usage: M98 P"macros/system/nxt-ui-helper.g" S<action_type> T<timeout_seconds>
; 
; Parameters:
; S = Action type (1=spindle_start, 2=spindle_stop, 3=coolant_on, 4=coolant_off)
; T = Timeout in seconds (default: 30)

; Map action codes to action strings
var actionMap = { "spindle_start", "spindle_stop", "coolant_on", "coolant_off" }
var timeout = { exists(param.T) ? param.T : 30 }
var actionType = { exists(param.S) && param.S >= 1 && param.S <= 4 ? actionMap[param.S - 1] : null }

if { actionType == null }
    echo "ERROR: nxt-ui-helper.g requires valid S parameter (1-4)"
    M99

; Set up the pending action
set global.nxtPendingAction = { actionType }
set global.nxtActionResponse = null

; Check if UI is ready
if { global.nxtUiReady }
    echo "Waiting for UI confirmation for action: " ^ global.nxtPendingAction
    
    ; Wait for response with timeout
    var startTime = { state.upTime }
    while { global.nxtActionResponse == null && (state.upTime - startTime) < timeout }
        G4 P100 ; Wait 100ms
    
    ; Check response
    if { global.nxtActionResponse == "confirm" }
        echo "Action confirmed by user via UI"
        set global.nxtPendingAction = null
        ; Return success via job result
        M400 ; Wait for moves to complete
    elif { global.nxtActionResponse == "cancel" }
        echo "Action cancelled by user via UI"
        set global.nxtPendingAction = null
        abort "Action cancelled by user"
    else
        ; Timeout
        set global.nxtPendingAction = null
        abort "UI confirmation timeout after " ^ timeout ^ " seconds"

else
    ; Fallback to M291 dialog
    var message = ""
    if { actionType == "spindle_start" }
        set message = "Start Spindle?"
    elif { actionType == "spindle_stop" }  
        set message = "Stop Spindle?"
    elif { actionType == "coolant_on" }
        set message = "Turn on Coolant?"
    elif { actionType == "coolant_off" }
        set message = "Turn off Coolant?"
    
    M291 P{message} R"NeXT Confirmation" S3 T{timeout}
    ; M291 with S3 returns automatically on Yes/No, no need to check response