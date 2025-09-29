; G6502.g: RECTANGLE POCKET PROBE
;
; Probes the inside edges of a rectangular pocket to find center coordinates and dimensions.
; Probes all four walls of the pocket and calculates center and rotation.
; Logs the center coordinates to the Probe Results Table.
;
; USAGE: G6502 [X<width>] [Y<length>] [Z<depth>] [C<clearance>] [F<feedrate>] [R<retries>]
;
; Parameters:
;   X: Approximate pocket width (X-axis dimension, default: 20.0mm)
;   Y: Approximate pocket length (Y-axis dimension, default: 20.0mm) 
;   Z: Probing depth below current Z (default: -5.0mm)
;   C: Clearance from pocket walls (default: 1.0mm)
;   F: Optional feedrate override
;   R: Optional number of probe retries

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6502: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6502: Touch probe must be selected for pocket probing"

; Default parameters
var pocketWidth = { exists(param.X) ? param.X : 20.0 }
var pocketLength = { exists(param.Y) ? param.Y : 20.0 }
var probeDepth = { exists(param.Z) ? param.Z : -5.0 }
var clearance = { exists(param.C) ? param.C : 1.0 }

; Validate parameters
if { var.pocketWidth <= 0 || var.pocketLength <= 0 }
    abort "G6502: Pocket dimensions must be positive"

if { var.clearance <= 0 }
    abort "G6502: Clearance must be positive"

; Park to safe position
G27 Z1

; Get current position as pocket center starting point
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }
var probeZ = { var.startZ + var.probeDepth }

echo "G6502: Starting rectangle pocket probe"
echo { "G6502: Approximate center: X=" ^ var.centerX ^ " Y=" ^ var.centerY }
echo { "G6502: Pocket dimensions: " ^ var.pocketWidth ^ "mm x " ^ var.pocketLength ^ "mm" }
echo { "G6502: Clearance: " ^ var.clearance ^ "mm" }

; Move to probing depth
G53 G0 Z{var.probeZ}

; Calculate probe positions (inside pocket, moving outward to walls)
var halfWidth = { var.pocketWidth / 2 }
var halfLength = { var.pocketLength / 2 }
var safeWidth = { var.halfWidth - var.clearance }
var safeLength = { var.halfLength - var.clearance }

; Probe +X wall (right side)
echo "G6502: Probing +X wall (right side)"
G53 G0 X{var.centerX + var.safeWidth} Y{var.centerY}

var probeCmd = { "G6512 X" ^ (var.centerX + var.halfWidth + 2) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var xPlusWall = { global.nxtLastProbeResult }

; Return to center
G53 G0 X{var.centerX} Y{var.centerY}

; Probe -X wall (left side)
echo "G6502: Probing -X wall (left side)"
G53 G0 X{var.centerX - var.safeWidth} Y{var.centerY}

set var.probeCmd = { "G6512 X" ^ (var.centerX - var.halfWidth - 2) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var xMinusWall = { global.nxtLastProbeResult }

; Return to center
G53 G0 X{var.centerX} Y{var.centerY}

; Probe +Y wall (far side)
echo "G6502: Probing +Y wall (far side)"
G53 G0 X{var.centerX} Y{var.centerY + var.safeLength}

set var.probeCmd = { "G6512 Y" ^ (var.centerY + var.halfLength + 2) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var yPlusWall = { global.nxtLastProbeResult }

; Return to center
G53 G0 X{var.centerX} Y{var.centerY}

; Probe -Y wall (near side)
echo "G6502: Probing -Y wall (near side)"
G53 G0 X{var.centerX} Y{var.centerY - var.safeLength}

set var.probeCmd = { "G6512 Y" ^ (var.centerY - var.halfLength - 2) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

{var.probeCmd}
var yMinusWall = { global.nxtLastProbeResult }

; Calculate pocket center and dimensions
var calculatedCenterX = { (var.xPlusWall + var.xMinusWall) / 2 }
var calculatedCenterY = { (var.yPlusWall + var.yMinusWall) / 2 }
var measuredWidth = { var.xPlusWall - var.xMinusWall }
var measuredLength = { var.yPlusWall - var.yMinusWall }

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

; Store the pocket center coordinates
set global.nxtProbeResults[var.resultSlot][0] = { var.calculatedCenterX }
set global.nxtProbeResults[var.resultSlot][1] = { var.calculatedCenterY }
set global.nxtProbeResults[var.resultSlot][2] = { var.startZ }  ; Use original Z

; Move to safe position
G53 G0 Z{var.startZ + 5}

echo { "G6502: Rectangle pocket probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6502: Pocket center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY }
echo { "G6502: Measured dimensions: " ^ var.measuredWidth ^ "mm x " ^ var.measuredLength ^ "mm" }
echo "G6502: Wall positions:"
echo { "G6502: +X wall: " ^ var.xPlusWall }
echo { "G6502: -X wall: " ^ var.xMinusWall }
echo { "G6502: +Y wall: " ^ var.yPlusWall }
echo { "G6502: -Y wall: " ^ var.yMinusWall }