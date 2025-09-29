; G6511.g: REFERENCE SURFACE PROBE
;
; Probes a reference surface with the touch probe to establish a datum
; for calculating tool offsets when using both touch probe and toolsetter.
;
; USAGE: G6511 [S<standalone>] [R<force_reprobe>]
;
; Parameters:
;   S: Standalone mode (0=part of workflow, 1=standalone operation, default=1)
;   R: Force re-probe (0=use cached if available, 1=always reprobe, default=0)

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled
if { !global.nxtFeatureTouchProbe }
    abort "G6511: Touch probe feature is disabled"

; Validate that touch probe is currently selected
if { state.currentTool != global.nxtProbeToolID }
    abort "G6511: Touch probe must be selected to perform reference surface probing"

; Default parameters
var standalone = { exists(param.S) ? param.S : 1 }
var forceReprobe = { exists(param.R) ? param.R : 0 }

; Check if we already have a valid reference surface measurement
if { !var.forceReprobe && global.nxtReferenceSurface != null }
    if { var.standalone }
        echo { "G6511: Reference surface already measured: " ^ global.nxtReferenceSurface }
    M99  ; Exit if cached value is acceptable

; Park machine to safe position
G27 Z1

; For now, implement a basic reference surface probe
; TODO: In full implementation, this should guide user to reference surface location
; and perform the actual probing operation

if { var.standalone }
    echo "G6511: Reference surface probing functionality not yet fully implemented"
    
    ; Check UI availability for manual input
    if { global.nxtUiReady }
        ; TODO: Use UI for reference surface probing when available
        echo "G6511: UI for reference surface probing not yet implemented"
    else
        ; Fallback to M291 dialog for manual setup
        M291 P"Reference surface probing: Please manually jog touch probe to reference surface and set Z origin, then continue" R"Reference Surface" S3 T60
    
    ; For development, set a placeholder value
    ; In production, this would be the actual probed Z coordinate
    set global.nxtReferenceSurface = { 0.0 }  ; Placeholder - would be actual probe result
    
    echo "G6511: Reference surface measurement placeholder set"
else
    ; Non-standalone mode - called from tool change workflow
    echo "G6511: Reference surface probing called from tool change workflow"
    
    ; TODO: Implement automatic reference surface probing
    set global.nxtReferenceSurface = { 0.0 }  ; Placeholder
    
    echo "G6511: Reference surface measurement completed (placeholder)"