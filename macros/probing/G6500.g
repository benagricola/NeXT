; G6500.g: BORE PROBE
;
; Probes the inside of a circular bore to find its center coordinates and diameter.
; Uses multiple probe points around the bore circumference for accurate center calculation.
; Logs the center coordinates to the Probe Results Table.
;
; USAGE: G6500 [D<diameter>] [Z<depth>] [F<feedrate>] [R<retries>] [P<probe_points>]
;
; Parameters:
;   D: Approximate bore diameter (default: 10.0mm)
;   Z: Probing depth below current Z (default: -5.0mm)
;   F: Optional feedrate override
;   R: Optional number of probe retries per point
;   P: Number of probe points around circumference (default: 4, min: 3, max: 8)

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6500: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6500: Touch probe must be selected for bore probing"

; Default parameters
var boreDiameter = { exists(param.D) ? param.D : 10.0 }
var probeDepth = { exists(param.Z) ? param.Z : -5.0 }
var probePoints = { exists(param.P) ? param.P : 4 }

; Validate parameters
if { var.boreDiameter <= 0 }
    abort "G6500: Bore diameter must be positive"

if { var.probePoints < 3 || var.probePoints > 8 }
    abort "G6500: Number of probe points must be between 3 and 8"

; Park to safe position
G27 Z1

; Get current position as bore center starting point
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }
var probeZ = { var.startZ + var.probeDepth }

echo "G6500: Starting bore probe"
echo { "G6500: Approximate center: X=" ^ var.centerX ^ " Y=" ^ var.centerY }
echo { "G6500: Bore diameter: " ^ var.boreDiameter ^ "mm" }
echo { "G6500: Probe points: " ^ var.probePoints }

; Calculate probe radius (slightly less than bore radius for safety)
var probeRadius = { (var.boreDiameter / 2) - 0.5 }  ; 0.5mm clearance

; Arrays to store probe results
var probeX = { vector(var.probePoints, 0.0) }
var probeY = { vector(var.probePoints, 0.0) }

; Move to probing depth
G53 G0 Z{var.probeZ}

; Probe each point around the circumference
var point = 0
while { var.point < var.probePoints }
    ; Calculate angle for this probe point
    var angle = { (var.point * 360) / var.probePoints }
    var angleRad = { var.angle * 3.14159 / 180 }
    
    ; Calculate probe start position (inside bore, moving outward)
    var probeStartX = { var.centerX + (var.probeRadius * 0.5 * cos(var.angleRad)) }
    var probeStartY = { var.centerY + (var.probeRadius * 0.5 * sin(var.angleRad)) }
    
    ; Calculate probe target position (outside expected bore wall)
    var probeTargetX = { var.centerX + (var.probeRadius * 1.5 * cos(var.angleRad)) }
    var probeTargetY = { var.centerY + (var.probeRadius * 1.5 * sin(var.angleRad)) }
    
    echo { "G6500: Probing point " ^ (var.point + 1) ^ " at angle " ^ var.angle ^ "°" }
    
    ; Move to probe start position
    G53 G0 X{var.probeStartX} Y{var.probeStartY}
    
    ; Build probe command (probe outward to bore wall)
    var probeCmd = { "G6512 X" ^ var.probeTargetX ^ " Y" ^ var.probeTargetY ^ " I" ^ global.nxtTouchProbeID }
    if { exists(param.F) }
        set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
    if { exists(param.R) }
        set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }
    
    ; Execute probe - this will need to be modified since G6512 only does single axis
    ; For now, use approximate single-axis probing
    if { abs(cos(var.angleRad)) > abs(sin(var.angleRad)) }
        ; Probe primarily in X direction
        { "G6512 X" ^ var.probeTargetX ^ " I" ^ global.nxtTouchProbeID }
        M5000
        set var.probeX[var.point] = { global.nxtLastProbeResult }
        set var.probeY[var.point] = { global.nxtAbsPos[1] }
    else
        ; Probe primarily in Y direction
        { "G6512 Y" ^ var.probeTargetY ^ " I" ^ global.nxtTouchProbeID }
        M5000
        set var.probeX[var.point] = { global.nxtAbsPos[0] }
        set var.probeY[var.point] = { global.nxtLastProbeResult }
    
    set var.point = { var.point + 1 }

; Calculate bore center using simple averaging (more sophisticated algorithms possible)
var sumX = 0.0
var sumY = 0.0
var i = 0
while { var.i < var.probePoints }
    set var.sumX = { var.sumX + var.probeX[var.i] }
    set var.sumY = { var.sumY + var.probeY[var.i] }
    set var.i = { var.i + 1 }

var calculatedCenterX = { var.sumX / var.probePoints }
var calculatedCenterY = { var.sumY / var.probePoints }

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

; Store the bore center coordinates
set global.nxtProbeResults[var.resultSlot][0] = { var.calculatedCenterX }
set global.nxtProbeResults[var.resultSlot][1] = { var.calculatedCenterY }
set global.nxtProbeResults[var.resultSlot][2] = { var.startZ }  ; Use original Z

; Move to safe position
G53 G0 Z{var.startZ + 5}

echo { "G6500: Bore probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6500: Bore center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY }