; tfree.g: FREE CURRENT TOOL
;
; This macro is executed by RepRapFirmware (RRF) before a tool is "freed" (unloaded).
; If the current tool is a touch probe or datum tool, it prompts the operator to safely remove it.
; For standard tools, it performs probe-on-removal length measurement.
;
; This file is automatically called by RRF during tool changes.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Initialize tool change state
set global.nxtToolChangeState = { 0 }

; Validate that all critical axes are homed
var axisCount = { min(#move.axes, 4) }  ; Check up to 4 axes (X,Y,Z,A)
while { iterations < var.axisCount }
    if { !move.axes[iterations].homed }
        abort { "tfree.g: Axis " ^ move.axes[iterations].letter ^ " is not homed" }

; Stop and park spindle for safety
G27 Z1  ; Park Z axis first for safety

; Handle probe tool removal
if { state.currentTool >= 0 && state.currentTool == global.nxtProbeToolID }
    ; Determine probe type based on touch probe feature
    var probeType = { global.nxtFeatureTouchProbe ? "Touch Probe" : "Datum Tool" }
    
    ; Check UI availability for confirmation
    if { global.nxtUiReady }
        ; TODO: Use UI confirmation when available
        echo "tfree.g: UI confirmation not yet implemented, falling back to M291"
    
    ; Fallback to M291 dialog
    M291 P{"Please remove the " ^ var.probeType ^ " and confirm when safely stowed"} R"Tool Change" S3 T30
    
    ; Set state to indicate tfree completed initial steps
    set global.nxtToolChangeState = { 1 }
    M99  ; Exit early for probe tools

; Handle standard tool removal with probe-on-removal measurement
; Only measure if toolsetter is enabled and configured
if { global.nxtFeatureToolSetter && global.nxtToolSetterPos != null }
    ; Probe the current tool before removal for relative offset calculation
    echo "tfree.g: Measuring current tool length for relative offset calculation"
    G37  ; Probe current tool length
    
    ; Store the measurement in the tool cache
    if { state.currentTool >= 0 && state.currentTool < #global.nxtToolCache }
        set global.nxtToolCache[state.currentTool] = { global.nxtLastProbeResult }
        echo { "tfree.g: Cached tool " ^ state.currentTool ^ " length: " ^ global.nxtLastProbeResult }

; For tools without toolsetter, just prompt for manual removal
if { !global.nxtFeatureToolSetter }
    ; Check UI availability for confirmation
    if { global.nxtUiReady }
        ; TODO: Use UI confirmation when available
        echo "tfree.g: UI confirmation not yet implemented, falling back to M291"
    
    ; Fallback to M291 dialog
    M291 P{"Please remove Tool " ^ state.currentTool ^ " and confirm when safely stowed"} R"Tool Change" S3 T30

; Set state to indicate tfree has completed
set global.nxtToolChangeState = { 1 }