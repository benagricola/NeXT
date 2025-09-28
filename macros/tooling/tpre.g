; tpre.g: PRE TOOL CHANGE - EXECUTE
;
; Executed by RRF before a tool change operation begins.
; Handles operator guidance and preparation for the new tool installation.
; Implements relative offset calculation logic between tools.

; Validate that tfree.g completed successfully
if { state.nextTool < 0 }
    abort "tpre.g: No next tool selected"

if { global.nxtToolChangeState < 1 }
    abort "tpre.g: tfree.g did not complete successfully"

; Set tool change state to pre-change
set global.nxtToolChangeState = 2

; Ensure all axes are homed
if { !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed }
    abort "tpre.g: All axes must be homed before tool change"

; Stop spindle and park to safe position
G27 Z1

; Handle probe tool installation
if { state.nextTool == global.nxtProbeToolID }
    if { global.nxtFeatureTouchProbe }
        ; Touch probe installation
        if { global.nxtUiReady }
            ; TODO: Use UI confirmation when available
            M291 P"Install Touch Probe and press OK when ready" R"Tool Change" S3 T0
        else
            M291 P"Install Touch Probe and press OK when ready" R"Tool Change" S3 T0
        
        ; Wait for probe activation to confirm installation
        M8002 K{global.nxtTouchProbeID} W30
        
        if { global.nxtProbeDetected != global.nxtTouchProbeID }
            abort "tpre.g: Touch probe not detected after installation"
    else
        ; Datum tool installation
        if { global.nxtUiReady }
            M291 P"Install Datum Tool and press OK when ready" R"Tool Change" S3 T0
        else
            M291 P"Install Datum Tool and press OK when ready" R"Tool Change" S3 T0
else
    ; Standard cutting tool installation
    
    ; Check if we need reference surface measurement for touch probe system
    if { global.nxtFeatureTouchProbe && global.nxtFeatureToolSetter && global.nxtDeltaMachine == null }
        abort "tpre.g: Reference surface (nxtDeltaMachine) must be calibrated before using cutting tools with touch probe system. Run tool calibration first."
    
    ; Prompt operator to install the cutting tool
    var toolName = { exists(tools[state.nextTool].name) ? tools[state.nextTool].name : ("Tool T" ^ state.nextTool) }
    
    if { global.nxtUiReady }
        M291 P{"Install " ^ var.toolName ^ " and press OK when ready"} R"Tool Change" S3 T0
    else
        M291 P{"Install " ^ var.toolName ^ " and press OK when ready"} R"Tool Change" S3 T0

; Set tool change state to indicate tpre.g completion
set global.nxtToolChangeState = 3