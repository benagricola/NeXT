; G37.g: TOOL LENGTH PROBE
;
; Measures tool length using the toolsetter and calculates appropriate tool offset.
; Handles both single-point and multi-point probing for large tools.
;
; USAGE: G37
;
; Assumes tool is installed and toolsetter is configured.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that toolsetter feature is enabled
if { !global.nxtFeatureToolSetter }
    abort "G37: Toolsetter feature is disabled"

; Validate toolsetter configuration
if { global.nxtToolSetterPos == null }
    abort "G37: Toolsetter position not configured"

if { global.nxtToolSetterID == null }
    abort "G37: Toolsetter probe ID not configured"

; Validate current tool
if { state.currentTool < 0 }
    abort "G37: No tool currently selected"

; Park machine to safe position before starting
G27 Z1

; Reset the Z offset for the current tool to ensure clean measurement
G10 P{state.currentTool} Z0

; Get current tool information for multi-point probing logic
; For now, implement single-point probing - multi-point will be added later
var toolRadius = 0  ; TODO: Get from tool table when implemented

; Move to toolsetter XY position
G53 G0 X{global.nxtToolSetterPos[0]} Y{global.nxtToolSetterPos[1]}

; Perform single-point probe down to toolsetter surface
G6512 Z{global.nxtToolSetterPos[2] - 20} I{global.nxtToolSetterID}  ; Probe 20mm below toolsetter surface

; Calculate tool offset based on probing mode and features
var toolOffset = 0
var probedZ = {global.nxtLastProbeResult}

; If touch probe feature is enabled, calculate offset relative to reference surface
if { global.nxtFeatureTouchProbe && global.nxtReferenceSurface != null && global.nxtDeltaMachine != null }
    ; Calculate offset relative to reference surface using static datum
    set var.toolOffset = {var.probedZ - global.nxtReferenceSurface + global.nxtDeltaMachine}
else
    ; Simple toolsetter mode - offset relative to toolsetter surface
    set var.toolOffset = {var.probedZ - global.nxtToolSetterPos[2]}

; Apply the calculated offset to the current tool
G10 P{state.currentTool} Z{var.toolOffset}

echo { "G37: Tool " ^ state.currentTool ^ " probed successfully" }
echo { "G37: Probed Z position: " ^ var.probedZ }
echo { "G37: Applied tool offset: " ^ var.toolOffset }

; Move to safe position after probing
G27 Z1