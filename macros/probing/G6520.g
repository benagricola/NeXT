; G6520.g: VISE CORNER PROBE
;
; Specialized corner probe for vise setups. Probes the fixed jaw (Y-axis) and 
; movable jaw (X-axis) to find the vise corner and establish work coordinate origin.
; Logs the corner coordinates to the Probe Results Table.
;
; USAGE: G6520 [X<movable_jaw>] [Y<fixed_jaw>] [Z<top_surface>] [F<feedrate>] [R<retries>]
;
; Parameters:
;   X: Movable jaw surface coordinate (negative from current position)
;   Y: Fixed jaw surface coordinate (negative from current position)  
;   Z: Top surface of workpiece (negative from current position)
;   F: Optional feedrate override
;   R: Optional number of probe retries

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and probe tool is selected
if { !global.nxtFeatureTouchProbe }
    abort "G6520: Touch probe feature is disabled"

if { state.currentTool != global.nxtProbeToolID }
    abort "G6520: Touch probe must be selected for vise corner probing"

; Default parameters - probe surfaces in negative directions
var xTarget = { exists(param.X) ? param.X : -10.0 }  ; Movable jaw
var yTarget = { exists(param.Y) ? param.Y : -10.0 }  ; Fixed jaw
var zTarget = { exists(param.Z) ? param.Z : -5.0 }   ; Top surface

; Park to safe position
G27 Z1

; Get current position as starting point
M5000
var startX = { global.nxtAbsPos[0] }
var startY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

echo "G6520: Starting vise corner probe"
echo { "G6520: Starting position: X=" ^ var.startX ^ " Y=" ^ var.startY ^ " Z=" ^ var.startZ }

; First probe: Fixed jaw (Y-axis surface)
echo "G6520: Probing fixed jaw (Y-axis)"

; Build Y probe command
var probeCmd = { "G6512 Y" ^ (var.startY + var.yTarget) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

; Execute Y surface probe (fixed jaw)
{var.probeCmd}
var yJaw = { global.nxtLastProbeResult }

; Return to start position but at safe Z
G53 G0 Z{var.startZ + 5}  ; 5mm above start Z for safety
G53 G0 X{var.startX} Y{var.startY}
G53 G0 Z{var.startZ}

; Second probe: Movable jaw (X-axis surface)
echo "G6520: Probing movable jaw (X-axis)"

; Build X probe command
set var.probeCmd = { "G6512 X" ^ (var.startX + var.xTarget) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

; Execute X surface probe (movable jaw)
{var.probeCmd}
var xJaw = { global.nxtLastProbeResult }

; Return to start position for Z probe
G53 G0 Z{var.startZ + 5}
G53 G0 X{var.startX} Y{var.startY}
G53 G0 Z{var.startZ}

; Third probe: Top surface (Z-axis)
echo "G6520: Probing top surface (Z-axis)"

; Build Z probe command
set var.probeCmd = { "G6512 Z" ^ (var.startZ + var.zTarget) ^ " I" ^ global.nxtTouchProbeID }
if { exists(param.F) }
    set var.probeCmd = { var.probeCmd ^ " F" ^ param.F }
if { exists(param.R) }
    set var.probeCmd = { var.probeCmd ^ " R" ^ param.R }

; Execute Z surface probe (top surface)
{var.probeCmd}
var zSurface = { global.nxtLastProbeResult }

; Calculate vise corner coordinates
var cornerX = { var.xJaw }
var cornerY = { var.yJaw }
var cornerZ = { var.zSurface }

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

; Store the vise corner coordinates
set global.nxtProbeResults[var.resultSlot][0] = { var.cornerX }
set global.nxtProbeResults[var.resultSlot][1] = { var.cornerY }
set global.nxtProbeResults[var.resultSlot][2] = { var.cornerZ }

; Move to safe position
G53 G0 Z{var.startZ + 10}

echo { "G6520: Vise corner probe complete. Result logged to slot " ^ var.resultSlot }
echo { "G6520: Vise corner at X=" ^ var.cornerX ^ " Y=" ^ var.cornerY ^ " Z=" ^ var.cornerZ }
echo { "G6520: Fixed jaw (Y): " ^ var.yJaw }
echo { "G6520: Movable jaw (X): " ^ var.xJaw }
echo { "G6520: Top surface (Z): " ^ var.zSurface }