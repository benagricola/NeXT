; tpre.g: PRE TOOL CHANGE - EXECUTE
;
; This macro is executed by RepRapFirmware (RRF) before a tool change operation begins.
; It provides guidance to the operator, handles safety checks, and manages the state
; for the tool change process.
;
; This file is automatically called by RRF during tool changes.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate preconditions
if { state.nextTool < 0 }
    abort "tpre.g: No next tool selected"

; Ensure tfree.g completed successfully
if { global.nxtToolChangeState < 1 }
    abort "tpre.g: Tool free process did not complete (tfree.g state check failed)"

; Set tool change state to pre-change
set global.nxtToolChangeState = { 2 }

; Validate that all critical axes are homed
var axisCount = { min(#move.axes, 4) }  ; Check up to 4 axes (X,Y,Z,A)
while { iterations < var.axisCount }
    if { !move.axes[iterations].homed }
        abort { "tpre.g: Axis " ^ move.axes[iterations].letter ^ " is not homed" }

; Stop and park spindle for safety
G27 Z1  ; Park Z axis first for safety

; Handle probe tool installation
if { state.nextTool == global.nxtProbeToolID }
    ; Determine probe type based on touch probe feature
    var probeType = { global.nxtFeatureTouchProbe ? "Touch Probe" : "Datum Tool" }
    
    ; For touch probe with touch probe feature enabled
    if { global.nxtFeatureTouchProbe }
        ; Check UI availability for confirmation
        if { global.nxtUiReady }
            ; TODO: Use UI confirmation when available
            echo "tpre.g: UI confirmation not yet implemented, falling back to M291"
        
        ; Fallback to M291 dialog for touch probe installation
        M291 P{"Please install the " ^ var.probeType ^ " in the spindle"} R"Tool Change" S3 T30
        
        ; TODO: Implement probe activation check (M8002 equivalent)
        ; For now, assume probe is installed correctly
        echo "tpre.g: Touch probe installation confirmed (probe activation check not yet implemented)"
    else
        ; For datum tool (touch probe feature disabled)
        ; Check UI availability for confirmation
        if { global.nxtUiReady }
            ; TODO: Use UI confirmation when available
            echo "tpre.g: UI confirmation not yet implemented, falling back to M291"
        
        ; Fallback to M291 dialog for datum tool installation
        M291 P{"Please install the " ^ var.probeType ^ " in the spindle"} R"Tool Change" S3 T30

; Handle standard tool installation
if { state.nextTool != global.nxtProbeToolID }
    ; Validate configuration for tools requiring both touch probe and toolsetter
    if { global.nxtFeatureTouchProbe && global.nxtFeatureToolSetter }
        ; Ensure reference surface has been probed
        if { global.nxtReferenceSurface == null }
            abort "tpre.g: Reference surface not probed. Please run touch probe reference surface measurement first"
    
    ; Prepare tool installation message
    var toolMsg = { "Please install Tool " ^ state.nextTool ^ " in the spindle and confirm when ready" }
    
    ; Check UI availability for confirmation
    if { global.nxtUiReady }
        ; TODO: Use UI confirmation when available
        echo "tpre.g: UI confirmation not yet implemented, falling back to M291"
    
    ; Fallback to M291 dialog for tool installation
    M291 P{var.toolMsg} R"Tool Change" S3 T30

; Set state to indicate tpre.g has completed successfully
set global.nxtToolChangeState = { 3 }