; G6503.g: RECTANGLE BLOCK PROBE
;
; Probes the outside edges of a rectangular block to find center coordinates and dimensions.
; Probes all four sides of the block and calculates center and rotation.
; Logs the center coordinates to the Probe Results Table.
;
; USAGE: G6503 [X<width>] [Y<length>] [Z<depth>] [C<clearance>] [F<feedrate>] [R<retries>]
;
; Parameters:
;   X: Approximate block width (X-axis dimension, default: 20.0mm)
;   Y: Approximate block length (Y-axis dimension, default: 20.0mm)
;   Z: Probing depth below current Z (default: -5.0mm)
;   C: Clearance from block edges (default: 2.0mm)
;   F: Optional feedrate override
;   R: Optional number of probe retries

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6503: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6503: Touch probe must be selected for block probing"

; Default parameters
var blockWidth = { exists(param.X) ? param.X : 20.0 }
var blockLength = { exists(param.Y) ? param.Y : 20.0 }
var probeDepth = { exists(param.Z) ? param.Z : -5.0 }
var clearance = { exists(param.C) ? param.C : 2.0 }

; Validate parameters
if { var.blockWidth <= 0 || var.blockLength <= 0 }
    abort "G6503: Block dimensions must be positive"

if { var.clearance <= 0 }
    abort "G6503: Clearance must be positive"

; Park to safe position
G27 Z1

; Get current position as block center starting point
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }
var probeZ = { var.startZ + var.probeDepth }

echo "G6503: Starting rectangle block probe"
echo { "G6503: Approximate center: X=" ^ var.centerX ^ " Y=" ^ var.centerY }
echo { "G6503: Block dimensions: " ^ var.blockWidth ^ "mm x " ^ var.blockLength ^ "mm" }
echo { "G6503: Clearance: " ^ var.clearance ^ "mm" }

; Move to probing depth
G53 G0 Z{var.probeZ}

; Calculate probe positions (outside block, moving inward to edges)
var halfWidth = { var.blockWidth / 2 }
var halfLength = { var.blockLength / 2 }

; Probe +X edge (right side)
echo "G6503: Probing +X edge (right side)"
var probeStartX = { var.centerX + var.halfWidth + var.clearance }
G53 G0 X{var.probeStartX} Y{var.centerY}

var probeCmd = { "G6512 X" ^ (var.centerX + var.halfWidth - 1) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var xPlusEdge = { global.nxtLastProbeResult }

; Back off to safe position
G53 G0 X{var.probeStartX}

; Probe -X edge (left side)
echo "G6503: Probing -X edge (left side)"
var probeStartXMinus = { var.centerX - var.halfWidth - var.clearance }
G53 G0 X{var.probeStartXMinus} Y{var.centerY}

set var.probeCmd = { "G6512 X" ^ (var.centerX - var.halfWidth + 1) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var xMinusEdge = { global.nxtLastProbeResult }

; Back off to safe position
G53 G0 X{var.probeStartXMinus}

; Probe +Y edge (far side)
echo "G6503: Probing +Y edge (far side)"
var probeStartY = { var.centerY + var.halfLength + var.clearance }
G53 G0 X{var.centerX} Y{var.probeStartY}

set var.probeCmd = { "G6512 Y" ^ (var.centerY + var.halfLength - 1) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var yPlusEdge = { global.nxtLastProbeResult }

; Back off to safe position
G53 G0 Y{var.probeStartY}

; Probe -Y edge (near side)
echo "G6503: Probing -Y edge (near side)"
var probeStartYMinus = { var.centerY - var.halfLength - var.clearance }
G53 G0 X{var.centerX} Y{var.probeStartYMinus}

set var.probeCmd = { "G6512 Y" ^ (var.centerY - var.halfLength + 1) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var yMinusEdge = { global.nxtLastProbeResult }

; Calculate block center and dimensions
var calculatedCenterX = { (var.xPlusEdge + var.xMinusEdge) / 2 }
var calculatedCenterY = { (var.yPlusEdge + var.yMinusEdge) / 2 }
var measuredWidth = { var.xPlusEdge - var.xMinusEdge }
var measuredLength = { var.yPlusEdge - var.yMinusEdge }

; Log result to Probe Results Table
var resultSlot = 0
while { var.resultSlot < #global.nxtProbeResults }
    if { global.nxtProbeResults[var.resultSlot][0] == 0 && global.nxtProbeResults[var.resultSlot][1] == 0 && global.nxtProbeResults[var.resultSlot][2] == 0 }
        break
    set var.resultSlot = { var.resultSlot + 1 }

if { var.resultSlot >= #global.nxtProbeResults }
    set var.resultSlot = 0

if { #global.nxtProbeResults[var.resultSlot] < 3 }
    set global.nxtProbeResults[var.resultSlot] = { vector(3, 0.0) }

; Store the block center coordinates
set global.nxtProbeResults[var.resultSlot][0] = { var.calculatedCenterX }
set global.nxtProbeResults[var.resultSlot][1] = { var.calculatedCenterY }
set global.nxtProbeResults[var.resultSlot][2] = { var.startZ }  ; Use original Z

; Move to safe position
G53 G0 Z{var.startZ + 5}

echo { "G6503: Rectangle block probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6503: Block center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY }
echo { "G6503: Measured dimensions: " ^ var.measuredWidth ^ "mm x " ^ var.measuredLength ^ "mm" }
echo "G6503: Edge positions:"
echo { "G6503: +X edge: " ^ var.xPlusEdge }
echo { "G6503: -X edge: " ^ var.xMinusEdge }
echo { "G6503: +Y edge: " ^ var.yPlusEdge }
echo { "G6503: -Y edge: " ^ var.yMinusEdge }