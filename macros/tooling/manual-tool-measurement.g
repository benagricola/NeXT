; G37.1.g: MANUAL TOOL LENGTH MEASUREMENT
;
; Guides operator through manual Z-origin setting when toolsetter is not available.
; This is used when no toolsetter is configured or as a fallback method.
;
; USAGE: G37.1
;
; The operator is guided through:
; 1. Jogging the tool to the desired Z origin
; 2. Setting the WCS Z origin to that position
; 3. Clearing any existing tool offset

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Ensure we have a selected tool
if { state.currentTool < 0 }
    abort "G37.1: No tool selected for manual length measurement"

; Ensure all axes are homed
if { !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed }
    abort "G37.1: All axes must be homed for manual measurement"

; Stop spindle and park
G27 Z1

echo "G37.1: Manual tool length measurement for T" ^ state.currentTool

; Guide operator through manual positioning
var currentWCS = { (move.workplaceNumber > 0) ? move.workplaceNumber : 1 }

if { global.nxtUiReady }
    M291.9 P{"Jog tool T" ^ state.currentTool ^ " to desired Z origin position"} R"Manual Tool Measurement" S3 T0 K{"jogging"}
else
    M291.9 P{"Use DWC controls to jog tool T" ^ state.currentTool ^ " to desired Z origin position, then press OK"} R"Manual Tool Measurement" S3 T0

; Get current position after jogging
M5000
var currentZ = global.nxtAbsPos[2]

; Clear any existing tool offset first
G10 P{state.currentTool} X0 Y0 Z0

; Set the WCS Z origin to current position
G10 L20 P{var.currentWCS} Z{var.currentZ}

echo "G37.1: Z origin set to " ^ var.currentZ ^ " for WCS G" ^ (53 + var.currentWCS)
echo "G37.1: Tool T" ^ state.currentTool ^ " offset cleared (set to 0)"

; Inform operator
if { global.nxtUiReady }
    M291.9 P{"Z origin set for tool T" ^ state.currentTool ^ " in WCS G" ^ (53 + var.currentWCS)} R"Manual Measurement Complete" S1 T0
else
    M291.9 P{"Z origin set for tool T" ^ state.currentTool ^ " in WCS G" ^ (53 + var.currentWCS)} R"Manual Measurement Complete" S1 T0

echo "G37.1: Manual tool length measurement completed"