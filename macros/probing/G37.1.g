; G37.1.g: MANUAL TOOL LENGTH SETUP
;
; Guides the operator through manually setting up tool length/Z origin
; when automatic toolsetter is not available.
;
; USAGE: G37.1

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate current tool
if { state.currentTool < 0 }
    abort "G37.1: No tool currently selected"

; Park machine to safe position first
G27 Z1

echo { "G37.1: Manual tool length setup for Tool " ^ state.currentTool }

; Check UI availability for manual setup guidance
if { global.nxtUiReady }
    ; TODO: Use UI for manual tool setup when available
    echo "G37.1: UI for manual tool setup not yet implemented, falling back to M291"

; Fallback to M291 dialogs for manual setup
M291 P{"Manual Tool Setup: Please jog Tool " ^ state.currentTool ^ " to the workpiece surface and set the Z origin as needed"} R"Manual Tool Setup" S1 T30

echo "G37.1: Manual tool length setup process initiated"
echo "G37.1: Use machine jogging controls to position tool and set work coordinate system as needed"