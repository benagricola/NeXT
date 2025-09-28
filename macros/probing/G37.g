; G37.g: AUTOMATED TOOL LENGTH MEASUREMENT
;
; Measures tool length using the toolsetter and applies appropriate offset.
; Works with the new relative offset system.
;
; USAGE: G37
;
; This macro:
; 1. Measures the current tool on the toolsetter
; 2. Calculates offset based on reference measurements
; 3. Applies the calculated offset to the tool

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate configuration
if { !global.nxtFeatureToolSetter }
    abort "G37: Toolsetter feature not enabled"

if { global.nxtToolSetterPos == null }
    abort "G37: Toolsetter position not configured"

; Ensure we have a selected tool
if { state.currentTool < 0 }
    abort "G37: No tool selected for measurement"

; Ensure all axes are homed
while { iterations < #move.axes }
    if { !move.axes[iterations].homed }
        abort {"G37: Axis " ^ move.axes[iterations].letter ^ " must be homed for measurement"}

; Stop spindle and park
G27 Z1

echo {"G37: Measuring tool T" ^ state.currentTool}

; Reset tool offset to 0 before probing
G10 P{state.currentTool} Z0

; Move to toolsetter position
G53 G0 X{global.nxtToolSetterPos[0]} Y{global.nxtToolSetterPos[1]}
G53 G0 Z{global.nxtToolSetterPos[2] + 10}  ; 10mm above toolsetter

; Probe the tool on toolsetter towards axis minimum
G6512 Z{move.axes[2].min} I{global.nxtToolSetterID}

var currentMeasurement = global.nxtLastProbeResult
echo {"G37: Tool T" ^ state.currentTool ^ " measured at Z=" ^ var.currentMeasurement}

; Cache the measurement for this session
; Note: Cached measurement is only valid until tool is physically removed
set global.nxtToolCache[state.currentTool] = var.currentMeasurement

; Calculate and apply offset based on system configuration
var newOffset = 0.0

if { state.currentTool == global.nxtProbeToolID }
    ; This is the probe/datum tool - set offset to 0 as reference
    set newOffset = 0.0
    echo {"G37: Probe/datum tool - offset set to 0 (reference)"}
else
    ; This is a cutting tool - calculate relative offset
    if { global.nxtFeatureTouchProbe && global.nxtDeltaMachine != null }
        ; Touch probe system - use delta machine for reference
        if { global.nxtToolCache[global.nxtProbeToolID] != null }
            ; Convert touch probe measurement to toolsetter coordinates
            var referenceOnToolsetter = { global.nxtToolCache[global.nxtProbeToolID] - global.nxtDeltaMachine }
            var lengthDiff = { var.currentMeasurement - var.referenceOnToolsetter }
            set newOffset = var.lengthDiff
            echo {"G37: Offset calculated relative to touch probe: " ^ var.newOffset}
        else
            echo {"G37: Warning - No touch probe reference available, setting offset to 0"}
            set newOffset = 0.0
    else
        ; No touch probe or datum tool system - use existing offset logic or set to 0
        if { global.nxtToolCache[global.nxtProbeToolID] != null }
            ; Use datum tool as reference
            var referenceOnToolsetter = global.nxtToolCache[global.nxtProbeToolID]
            var lengthDiff = { var.currentMeasurement - var.referenceOnToolsetter }
            set newOffset = var.lengthDiff
            echo {"G37: Offset calculated relative to datum tool: " ^ var.newOffset}
        else
            echo {"G37: Warning - No reference tool available, setting offset to 0"}
            set newOffset = 0.0

; Apply the calculated offset (only Z, preserve X/Y offsets)
G10 P{state.currentTool} Z{var.newOffset}

; Return to safe position
G27 Z1

echo {"G37: Tool T" ^ state.currentTool ^ " offset set to Z=" ^ var.newOffset}