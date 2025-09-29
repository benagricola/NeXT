; G6510.g: SINGLE SURFACE PROBE
;
; Probes a single surface and logs the result to the probe results table.
; This cycle performs a single-axis probe move and records the compensated result.
;
; USAGE: G6510 [X<pos>|Y<pos>|Z<pos>] [F<speed>] [R<retries>]
;
; Parameters:
;   X|Y|Z: Exactly ONE axis parameter must be provided, specifying the target coordinate
;   F:     Optional speed override in mm/min
;   R:     Number of retries for averaging (default: probe.maxProbeCount + 1)
;
; The result is logged to nxtProbeResults table, not applied to any WCS.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6510: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6510: Touch probe ID not configured" }

; Validate exactly one axis parameter is provided
var axisCount = 0
var probeAxis = -1
var targetCoord = 0

if { exists(param.X) }
    set var.axisCount = { var.axisCount + 1 }
    set var.probeAxis = 0
    set var.targetCoord = { param.X }

if { exists(param.Y) }
    set var.axisCount = { var.axisCount + 1 }
    set var.probeAxis = 1
    set var.targetCoord = { param.Y }

if { exists(param.Z) }
    set var.axisCount = { var.axisCount + 1 }
    set var.probeAxis = 2
    set var.targetCoord = { param.Z }

if { var.axisCount != 1 }
    abort { "G6510: Exactly one of X, Y, or Z must be specified" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6510: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Park in Z before starting
G27 Z1

echo "G6510: Starting single surface probe on " ^ move.axes[var.probeAxis].letter ^ " axis"

; Execute the single-axis probe
if { var.probeAxis == 0 }
    G6512 X{var.targetCoord} I{global.nxtTouchProbeID} F{param.F} R{param.R}
elif { var.probeAxis == 1 }
    G6512 Y{var.targetCoord} I{global.nxtTouchProbeID} F{param.F} R{param.R}
else
    G6512 Z{var.targetCoord} I{global.nxtTouchProbeID} F{param.F} R{param.R}

; Log result to probe results table
; Find the next available slot in the results table
var resultIndex = 0
while { var.resultIndex < #global.nxtProbeResults && global.nxtProbeResults[var.resultIndex][var.probeAxis] != 0 }
    set var.resultIndex = { var.resultIndex + 1 }

; If table is full, use the last slot
if { var.resultIndex >= #global.nxtProbeResults }
    set var.resultIndex = { #global.nxtProbeResults - 1 }

; Initialize the result vector if needed
if { #global.nxtProbeResults[var.resultIndex] < 3 }
    set global.nxtProbeResults[var.resultIndex] = { vector(3, 0.0) }

; Store the result
set global.nxtProbeResults[var.resultIndex][var.probeAxis] = { global.nxtLastProbeResult }

; Return to safe height
G27 Z1

echo "G6510: Single surface probe completed"
echo "G6510: Result logged to table index " ^ var.resultIndex ^ ", " ^ move.axes[var.probeAxis].letter ^ "=" ^ global.nxtLastProbeResult