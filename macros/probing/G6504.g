; G6504.g: WEB (X/Y) PROBE
;
; Probes a web or ridge feature by measuring opposite surfaces in X and/or Y directions.
; This is useful for centering on thin features or measuring web thickness.
; Logs the center coordinates to the Probe Results Table.
;
; USAGE: G6504 [X<target>] [Y<target>] [Z<depth>] [F<feedrate>] [R<retries>]
;        G6504 X<target> ; Probe web in X direction only
;        G6504 Y<target> ; Probe web in Y direction only
;        G6504 X<target> Y<target> ; Probe web in both directions
;
; Parameters:
;   X: X-axis probing distance (+ and - from current position)
;   Y: Y-axis probing distance (+ and - from current position)
;   Z: Probing depth below current Z (default: -5.0mm)
;   F: Optional feedrate override
;   R: Optional number of probe retries

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6504: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6504: Touch probe must be selected for web probing"

; Check that at least one axis is specified
if { !exists(param.X) && !exists(param.Y) }
    abort "G6504: At least one of X or Y must be specified"

; Default parameters
var probeDepth = { exists(param.Z) ? param.Z : -5.0 }
var probeX = { exists(param.X) }
var probeY = { exists(param.Y) }
var xDistance = { exists(param.X) ? param.X : 0 }
var yDistance = { exists(param.Y) ? param.Y : 0 }

; Validate parameters
if { var.probeX && var.xDistance <= 0 }
    abort "G6504: X distance must be positive"

if { var.probeY && var.yDistance <= 0 }
    abort "G6504: Y distance must be positive"

; Park to safe position
G27 Z1

; Get current position as web center starting point
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }
var probeZ = { var.startZ + var.probeDepth }

echo "G6504: Starting web probe"
echo { "G6504: Starting position: X=" ^ var.centerX ^ " Y=" ^ var.centerY }
if { var.probeX }
    echo { "G6504: X-axis probing distance: ±" ^ var.xDistance ^ "mm" }
if { var.probeY }
    echo { "G6504: Y-axis probing distance: ±" ^ var.yDistance ^ "mm" }

; Move to probing depth
G53 G0 Z{var.probeZ}

; Initialize result variables
var xPlus = { var.centerX }
var xMinus = { var.centerX }
var yPlus = { var.centerY }
var yMinus = { var.centerY }

; Probe X-axis surfaces if requested
if { var.probeX }
    ; Probe +X surface
    echo "G6504: Probing +X surface"
    G53 G0 X{var.centerX} Y{var.centerY}
    
    var probeCmd = { "G6512 X" ^ (var.centerX + var.xDistance) ^ " I" ^ global.nxtTouchProbeID }
    if { exists(param.F) }
        set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
    if { exists(param.R) }
        set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }
    
    {var.probeCmd}
    set var.xPlus = { global.nxtLastProbeResult }
    
    ; Return to center
    G53 G0 X{var.centerX}
    
    ; Probe -X surface
    echo "G6504: Probing -X surface"
    set var.probeCmd = { "G6512 X" ^ (var.centerX - var.xDistance) ^ " I" ^ global.nxtTouchProbeID }
    if { exists(param.F) }
        set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
    if { exists(param.R) }
        set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }
    
    {var.probeCmd}
    set var.xMinus = { global.nxtLastProbeResult }
    
    ; Return to center
    G53 G0 X{var.centerX}

; Probe Y-axis surfaces if requested
if { var.probeY }
    ; Probe +Y surface
    echo "G6504: Probing +Y surface"
    G53 G0 X{var.centerX} Y{var.centerY}
    
    var probeCmd = { "G6512 Y" ^ (var.centerY + var.yDistance) ^ " I" ^ global.nxtTouchProbeID }
    if { exists(param.F) }
        set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
    if { exists(param.R) }
        set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }
    
    {var.probeCmd}
    set var.yPlus = { global.nxtLastProbeResult }
    
    ; Return to center
    G53 G0 Y{var.centerY}
    
    ; Probe -Y surface
    echo "G6504: Probing -Y surface"
    set var.probeCmd = { "G6512 Y" ^ (var.centerY - var.yDistance) ^ " I" ^ global.nxtTouchProbeID }
    if { exists(param.F) }
        set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
    if { exists(param.R) }
        set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }
    
    {var.probeCmd}
    set var.yMinus = { global.nxtLastProbeResult }
    
    ; Return to center
    G53 G0 Y{var.centerY}

; Calculate web center coordinates
var calculatedCenterX = { (var.xPlus + var.xMinus) / 2 }
var calculatedCenterY = { (var.yPlus + var.yMinus) / 2 }

; Calculate web thickness
var webThicknessX = { var.probeX ? (var.xPlus - var.xMinus) : 0 }
var webThicknessY = { var.probeY ? (var.yPlus - var.yMinus) : 0 }

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

; Store the web center coordinates
set global.nxtProbeResults[var.resultSlot][0] = { var.calculatedCenterX }
set global.nxtProbeResults[var.resultSlot][1] = { var.calculatedCenterY }
set global.nxtProbeResults[var.resultSlot][2] = { var.startZ }  ; Use original Z

; Move to safe position
G53 G0 Z{var.startZ + 5}

echo { "G6504: Web probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6504: Web center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY }
if { var.probeX }
    echo { "G6504: X-axis web thickness: " ^ var.webThicknessX ^ "mm" }
if { var.probeY }
    echo { "G6504: Y-axis web thickness: " ^ var.webThicknessY ^ "mm" }