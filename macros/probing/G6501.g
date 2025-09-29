; G6501.g: BOSS PROBE
;
; Probes the outside of a circular boss to find its center coordinates and diameter.
; Uses multiple probe points around the boss circumference for accurate center calculation.
; Logs the center coordinates to the Probe Results Table.
;
; USAGE: G6501 [D<diameter>] [Z<depth>] [C<clearance>] [F<feedrate>] [R<retries>] [P<probe_points>]
;
; Parameters:
;   D: Approximate boss diameter (default: 10.0mm)
;   Z: Probing depth below current Z (default: -5.0mm)
;   C: Clearance around boss (default: 2.0mm)
;   F: Optional feedrate override
;   R: Optional number of probe retries per point
;   P: Number of probe points around circumference (default: 4, min: 3, max: 8)

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6501: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6501: Touch probe must be selected for boss probing"

; Default parameters
var bossDiameter = { exists(param.D) ? param.D : 10.0 }
var probeDepth = { exists(param.Z) ? param.Z : -5.0 }
var clearance = { exists(param.C) ? param.C : 2.0 }
var probePoints = { exists(param.P) ? param.P : 4 }

; Validate parameters
if { var.bossDiameter <= 0 }
    abort "G6501: Boss diameter must be positive"

if { var.clearance <= 0 }
    abort "G6501: Clearance must be positive"

if { var.probePoints < 3 || var.probePoints > 8 }
    abort "G6501: Number of probe points must be between 3 and 8"

; Park to safe position
G27 Z1

; Get current position as boss center starting point
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }
var probeZ = { var.startZ + var.probeDepth }

echo "G6501: Starting boss probe"
echo { "G6501: Approximate center: X=" ^ var.centerX ^ " Y=" ^ var.centerY }
echo { "G6501: Boss diameter: " ^ var.bossDiameter ^ "mm" }
echo { "G6501: Clearance: " ^ var.clearance ^ "mm" }
echo { "G6501: Probe points: " ^ var.probePoints }

; Calculate probe radius (boss radius plus clearance)
var probeRadius = { (var.bossDiameter / 2) + var.clearance }

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
    
    ; Calculate probe start position (outside boss, moving inward)
    var probeStartX = { var.centerX + (var.probeRadius * cos(var.angleRad)) }
    var probeStartY = { var.centerY + (var.probeRadius * sin(var.angleRad)) }
    
    ; Calculate probe target position (inside expected boss wall)
    var probeTargetX = { var.centerX + ((var.bossDiameter / 2) * 0.8 * cos(var.angleRad)) }
    var probeTargetY = { var.centerY + ((var.bossDiameter / 2) * 0.8 * sin(var.angleRad)) }
    
    echo { "G6501: Probing point " ^ (var.point + 1) ^ " at angle " ^ var.angle ^ "°" }
    
    ; Move to probe start position
    G53 G0 X{var.probeStartX} Y{var.probeStartY}
    
    ; Probe inward to boss wall - use single-axis probing based on predominant direction
    if { abs(cos(var.angleRad)) > abs(sin(var.angleRad)) }
        ; Probe primarily in X direction (inward)
        { "G6512 X" ^ var.probeTargetX ^ " I" ^ global.nxtTouchProbeID }
        M5000
        set var.probeX[var.point] = { global.nxtLastProbeResult }
        set var.probeY[var.point] = { global.nxtAbsPos[1] }
    else
        ; Probe primarily in Y direction (inward)
        { "G6512 Y" ^ var.probeTargetY ^ " I" ^ global.nxtTouchProbeID }
        M5000
        set var.probeX[var.point] = { global.nxtAbsPos[0] }
        set var.probeY[var.point] = { global.nxtLastProbeResult }
    
    ; Back off to safe position after probe
    G53 G0 X{var.probeStartX} Y{var.probeStartY}
    
    set var.point = { var.point + 1 }

; Calculate boss center using simple averaging (more sophisticated algorithms possible)
var sumX = 0.0
var sumY = 0.0
var i = 0
while { var.i < var.probePoints }
    set var.sumX = { var.sumX + var.probeX[var.i] }
    set var.sumY = { var.sumY + var.probeY[var.i] }
    set var.i = { var.i + 1 }

var calculatedCenterX = { var.sumX / var.probePoints }
var calculatedCenterY = { var.sumY / var.probePoints }

; Calculate average radius for information
var sumRadius = 0.0
set var.i = 0
while { var.i < var.probePoints }
    var deltaX = { var.probeX[var.i] - var.calculatedCenterX }
    var deltaY = { var.probeY[var.i] - var.calculatedCenterY }
    var radius = { sqrt((var.deltaX * var.deltaX) + (var.deltaY * var.deltaY)) }
    set var.sumRadius = { var.sumRadius + var.radius }
    set var.i = { var.i + 1 }

var averageRadius = { var.sumRadius / var.probePoints }
var calculatedDiameter = { var.averageRadius * 2 }

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

; Store the boss center coordinates
set global.nxtProbeResults[var.resultSlot][0] = { var.calculatedCenterX }
set global.nxtProbeResults[var.resultSlot][1] = { var.calculatedCenterY }
set global.nxtProbeResults[var.resultSlot][2] = { var.startZ }  ; Use original Z

; Move to safe position
G53 G0 Z{var.startZ + 5}

echo { "G6501: Boss probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6501: Boss center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY }
echo { "G6501: Calculated diameter: " ^ var.calculatedDiameter ^ "mm" }