; G6508.g: OUTSIDE CORNER PROBE
;
; Probes two perpendicular outside surfaces to find the corner intersection point.
; Logs the corner coordinates to the Probe Results Table.
;
; USAGE: G6508 [X<surface1>] [Y<surface2>] [F<feedrate>] [R<retries>]
;
; Parameters:
;   X: X-axis surface coordinate to probe (negative direction from current position)
;   Y: Y-axis surface coordinate to probe (negative direction from current position)
;   F: Optional feedrate override
;   R: Optional number of probe retries
;
; Note: This implementation assumes probing in negative X and Y directions from current position

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6508: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6508: Touch probe must be selected for corner probing"

; Default parameters - probe 10mm in negative direction if not specified
var xTarget = { exists(param.X) ? param.X : -10.0 }
var yTarget = { exists(param.Y) ? param.Y : -10.0 }

; Park to safe position
G27 Z1

; Get current position as starting point
M5000
var startX = { global.nxtAbsPos[0] }
var startY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

echo "G6508: Starting outside corner probe"
echo { "G6508: Starting position: X=" ^ var.startX ^ " Y=" ^ var.startY }

; First probe: X-axis surface (probing in negative X direction)
echo "G6508: Probing X surface"

; Build X probe command
var probeCmd = { "G6512 X" ^ (var.startX + var.xTarget) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

; Execute X surface probe
{var.probeCmd}
var xSurface = { global.nxtLastProbeResult }

; Return to start position but at safe Z
G53 G0 Z{var.startZ + 5}  ; 5mm above start Z for safety
G53 G0 X{var.startX} Y{var.startY}
G53 G0 Z{var.startZ}

; Second probe: Y-axis surface (probing in negative Y direction)
echo "G6508: Probing Y surface"

; Build Y probe command
set var.probeCmd = { "G6512 Y" ^ (var.startY + var.yTarget) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

; Execute Y surface probe
{var.probeCmd}
var ySurface = { global.nxtLastProbeResult }

; Calculate corner coordinates (intersection of the two surfaces)
var cornerX = { var.xSurface }
var cornerY = { var.ySurface }
var cornerZ = { var.startZ }  ; Use starting Z as corner Z

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

; Store the corner coordinates
set global.nxtProbeResults[var.resultSlot][0] = { var.cornerX }
set global.nxtProbeResults[var.resultSlot][1] = { var.cornerY }
set global.nxtProbeResults[var.resultSlot][2] = { var.cornerZ }

; Move to safe position
G53 G0 Z{var.startZ + 5}

echo { "G6508: Outside corner probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6508: Corner found at X=" ^ var.cornerX ^ " Y=" ^ var.cornerY ^ " Z=" ^ var.cornerZ }