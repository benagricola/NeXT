; tpost.g: POST TOOL CHANGE - EXECUTE
;
; This macro is executed by RepRapFirmware (RRF) after a tool change has physically occurred.
; It is responsible for post-tool-change operations such as probing the new tool's length
; or probing a reference surface if a touch probe is installed.
;
; This file is automatically called by RRF during tool changes.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate preconditions
if { state.currentTool < 0 }
    abort "tpost.g: No tool currently selected"

; Validate that all critical axes are homed
var axisCount = { min(#move.axes, 4) }  ; Check up to 4 axes (X,Y,Z,A)
while { iterations < var.axisCount }
    if { !move.axes[iterations].homed }
        abort { "tpost.g: Axis " ^ move.axes[iterations].letter ^ " is not homed" }

; Ensure tpre.g completed successfully
if { global.nxtToolChangeState < 3 }
    abort "tpost.g: Tool pre-change process did not complete (tpre.g state check failed)"

; Set tool change state to post-change
set global.nxtToolChangeState = 4

; Stop and park spindle for safety
G27 Z1  ; Park Z axis first for safety

; Handle probe tool post-change operations
if { state.currentTool == global.nxtProbeToolID }
    ; Handle touch probe with both touch probe and toolsetter features enabled
    if { global.nxtFeatureTouchProbe && global.nxtFeatureToolSetter }
        ; Prompt user and probe reference surface to establish datum
        ; Check UI availability for confirmation
        if { global.nxtUiReady }
            ; TODO: Use UI confirmation when available
            echo "tpost.g: UI confirmation not yet implemented, falling back to M291"
        
        ; Fallback to M291 dialog
        M291 P"Touch probe installed. Will now probe reference surface to establish datum." R"Tool Change" S3 T15
        
        ; TODO: Implement G6511 equivalent (reference surface probe)
        ; For now, simulate the reference surface probing
        echo "tpost.g: Reference surface probing not yet implemented (G6511 equivalent)"
        ; This would call something like: G6511 S0 R1
        ; And set global.nxtReferenceSurface = result
        
    ; Handle datum tool with only toolsetter enabled (no touch probe feature)
    if { !global.nxtFeatureTouchProbe && global.nxtFeatureToolSetter }
        ; Prompt user and probe datum tool length with toolsetter
        ; Check UI availability for confirmation
        if { global.nxtUiReady }
            ; TODO: Use UI confirmation when available
            echo "tpost.g: UI confirmation not yet implemented, falling back to M291"
        
        ; Fallback to M291 dialog
        M291 P"Datum tool installed. Will now probe tool length with toolsetter." R"Tool Change" S3 T15
        
        ; Probe datum tool length
        G37
        
        echo "tpost.g: Datum tool probed successfully"

; Handle standard cutting tool post-change operations
if { state.currentTool != global.nxtProbeToolID }
    ; Automatic tool length measurement with toolsetter
    if { global.nxtFeatureToolSetter && global.nxtToolSetterPos != null }
        echo "tpost.g: Measuring new tool length with toolsetter"
        G37  ; Probe the new tool length
        
        ; Calculate relative offset if previous tool measurement exists
        ; This implements the relative offset calculation logic
        ; TODO: Implement full relative offset calculation once we have the complete workflow
        echo "tpost.g: Tool length measurement complete"
        
    else
        ; No automatic toolsetter - would need manual Z origin setup
        ; TODO: Implement G37.1 equivalent for manual probing guidance
        echo "tpost.g: No toolsetter available - manual Z origin setup required"
        
        ; Check UI availability for confirmation
        if { global.nxtUiReady }
            ; TODO: Use UI for manual Z origin setup when available
            echo "tpost.g: UI for manual setup not yet implemented"
        
        ; For now, just inform the operator
        M291 P"Tool change complete. Manual Z origin setup may be required." R"Tool Change" S1 T10

; Clear tool change state to indicate completion
set global.nxtToolChangeState = null

echo "tpost.g: Tool change process completed successfully"