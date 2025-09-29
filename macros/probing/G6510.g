; G6510.g: SINGLE SURFACE PROBE
;
; Probes a single surface (X, Y, or Z axis) and logs the result to the Probe Results Table.
; In NeXT architecture, this macro does not set WCS origins - results are logged for later use.
;
; USAGE: G6510 [X<pos>|Y<pos>|Z<pos>] [F<feedrate>] [R<retries>]
;
; Parameters:
;   X|Y|Z: Target coordinate for probing (exactly one axis must be specified)
;   F:     Optional feedrate override
;   R:     Optional number of probe retries

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6510: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6510: Touch probe must be selected for surface probing"

; Count axis parameters to ensure exactly one is provided
var axisCount = 0
var targetAxis = -1
var targetCoord = 0

if { exists(param.X) }
    set var.axisCount = { var.axisCount + 1 }
    set var.targetAxis = 0
    set var.targetCoord = { param.X }

if { exists(param.Y) }
    set var.axisCount = { var.axisCount + 1 }
    set var.targetAxis = 1
    set var.targetCoord = { param.Y }

if { exists(param.Z) }
    set var.axisCount = { var.axisCount + 1 }
    set var.targetAxis = 2
    set var.targetCoord = { param.Z }

; Validate exactly one axis parameter
if { var.axisCount != 1 }
    abort "G6510: Exactly one of X, Y, or Z must be specified"

; Park to safe position
G27 Z1

echo { "G6510: Starting single surface probe on " ^ move.axes[var.targetAxis].letter ^ " axis" }

; Build probe command parameters
var probeCmd = "G6512 "
if { var.targetAxis == 0 }
    set var.probeCmd = { var.probeCmd ^ "X" ^ var.targetCoord }
elif { var.targetAxis == 1 }
    set var.probeCmd = { var.probeCmd ^ "Y" ^ var.targetCoord }
else
    set var.probeCmd = { var.probeCmd ^ "Z" ^ var.targetCoord }

; Add probe ID
set var.probeCmd = { var.probeCmd ^ " I" ^ global.nxtTouchProbeID }

; Add optional parameters
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }

if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

; Execute the probe
{var.probeCmd}

; Log result to Probe Results Table
; Find first empty slot or use slot 0 as default
var resultSlot = 0
while { var.resultSlot < #global.nxtProbeResults }
    ; Check if this slot is empty (all zeros)
    if { global.nxtProbeResults[var.resultSlot][0] == 0 && global.nxtProbeResults[var.resultSlot][1] == 0 && global.nxtProbeResults[var.resultSlot][2] == 0 }
        break
    set var.resultSlot = { var.resultSlot + 1 }

; If no empty slot found, use slot 0 (overwrite oldest)
if { var.resultSlot >= #global.nxtProbeResults }
    set var.resultSlot = 0

; Initialize the result entry if needed
if { #global.nxtProbeResults[var.resultSlot] < 3 }
    set global.nxtProbeResults[var.resultSlot] = { vector(3, 0.0) }

; Get current position to preserve non-probed axes
M5000

; Store the result - preserve current position for non-probed axes
set global.nxtProbeResults[var.resultSlot][0] = { var.targetAxis == 0 ? global.nxtLastProbeResult : global.nxtAbsPos[0] }
set global.nxtProbeResults[var.resultSlot][1] = { var.targetAxis == 1 ? global.nxtLastProbeResult : global.nxtAbsPos[1] }
set global.nxtProbeResults[var.resultSlot][2] = { var.targetAxis == 2 ? global.nxtLastProbeResult : global.nxtAbsPos[2] }

echo { "G6510: Surface probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6510: " ^ move.axes[var.targetAxis].letter ^ " surface at: " ^ global.nxtLastProbeResult }