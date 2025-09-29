; G6505.g: POCKET (X/Y) PROBE
;
; Probes specific walls of a pocket in X and/or Y directions.
; This is useful for measuring pocket dimensions or centering on specific walls.
; Logs the measured coordinates to the Probe Results Table.
;
; USAGE: G6505 [X<direction>] [Y<direction>] [Z<depth>] [D<distance>] [F<feedrate>] [R<retries>]
;        G6505 X1 ; Probe +X wall only
;        G6505 X-1 ; Probe -X wall only  
;        G6505 Y1 ; Probe +Y wall only
;        G6505 Y-1 ; Probe -Y wall only
;        G6505 X1 Y1 ; Probe both +X and +Y walls
;
; Parameters:
;   X: X-axis probing direction (1 for +X, -1 for -X)
;   Y: Y-axis probing direction (1 for +Y, -1 for -Y)
;   Z: Probing depth below current Z (default: -5.0mm)
;   D: Maximum probing distance (default: 10.0mm)
;   F: Optional feedrate override
;   R: Optional number of probe retries

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6505: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6505: Touch probe must be selected for pocket probing"

; Check that at least one axis is specified
if { !exists(param.X) && !exists(param.Y) }
    abort "G6505: At least one of X or Y must be specified"

; Default parameters
var probeDepth = { exists(param.Z) ? param.Z : -5.0 }
var maxDistance = { exists(param.D) ? param.D : 10.0 }
var probeX = { exists(param.X) }
var probeY = { exists(param.Y) }
var xDirection = { exists(param.X) ? param.X : 0 }
var yDirection = { exists(param.Y) ? param.Y : 0 }

; Validate direction parameters
if { var.probeX && (var.xDirection != 1 && var.xDirection != -1) }
    abort "G6505: X direction must be 1 (+X) or -1 (-X)"

if { var.probeY && (var.yDirection != 1 && var.yDirection != -1) }
    abort "G6505: Y direction must be 1 (+Y) or -1 (-Y)"

if { var.maxDistance <= 0 }
    abort "G6505: Maximum distance must be positive"

; Park to safe position
G27 Z1

; Get current position as starting point
M5000
var startX = { global.nxtAbsPos[0] }
var startY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }
var probeZ = { var.startZ + var.probeDepth }

echo "G6505: Starting pocket wall probe"
echo { "G6505: Starting position: X=" ^ var.startX ^ " Y=" ^ var.startY }
if { var.probeX }
    echo { "G6505: X-axis direction: " ^ (var.xDirection > 0 ? "+X" : "-X") }
if { var.probeY }
    echo { "G6505: Y-axis direction: " ^ (var.yDirection > 0 ? "+Y" : "-Y") }

; Move to probing depth
G53 G0 Z{var.probeZ}

; Initialize result variables
var resultX = { var.startX }
var resultY = { var.startY }

; Probe X-axis wall if requested
if { var.probeX }
    var wallName = { var.xDirection > 0 ? "+X wall" : "-X wall" }
    echo { "G6505: Probing " ^ var.wallName }
    
    ; Move to starting position
    G53 G0 X{var.startX} Y{var.startY}
    
    ; Calculate target position
    var targetX = { var.startX + (var.xDirection * var.maxDistance) }
    
    ; Build probe command
    var probeCmd = { "G6512 X" ^ var.targetX ^ " I" ^ global.nxtTouchProbeID }
    if { exists(param.F) }
        set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
    if { exists(param.R) }
        set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }
    
    ; Execute probe
    {var.probeCmd}
    set var.resultX = { global.nxtLastProbeResult }
    
    ; Return to start position
    G53 G0 X{var.startX}

; Probe Y-axis wall if requested
if { var.probeY }
    var wallName = { var.yDirection > 0 ? "+Y wall" : "-Y wall" }
    echo { "G6505: Probing " ^ var.wallName }
    
    ; Move to starting position
    G53 G0 X{var.startX} Y{var.startY}
    
    ; Calculate target position
    var targetY = { var.startY + (var.yDirection * var.maxDistance) }
    
    ; Build probe command
    var probeCmd = { "G6512 Y" ^ var.targetY ^ " I" ^ global.nxtTouchProbeID }
    if { exists(param.F) }
        set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
    if { exists(param.R) }
        set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }
    
    ; Execute probe
    {var.probeCmd}
    set var.resultY = { global.nxtLastProbeResult }
    
    ; Return to start position
    G53 G0 Y{var.startY}

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

; Store the probe results (using probed coordinates, original for non-probed axes)
set global.nxtProbeResults[var.resultSlot][0] = { var.resultX }
set global.nxtProbeResults[var.resultSlot][1] = { var.resultY }
set global.nxtProbeResults[var.resultSlot][2] = { var.startZ }  ; Use original Z

; Move to safe position
G53 G0 Z{var.startZ + 5}

echo { "G6505: Pocket wall probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6505: Final position: X=" ^ var.resultX ^ " Y=" ^ var.resultY }
if { var.probeX }
    echo { "G6505: " ^ (var.xDirection > 0 ? "+X" : "-X") ^ " wall at: " ^ var.resultX }
if { var.probeY }
    echo { "G6505: " ^ (var.yDirection > 0 ? "+Y" : "-Y") ^ " wall at: " ^ var.resultY }