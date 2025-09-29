; G6509.g: INSIDE CORNER PROBE
;
; Probes an inside corner by probing two perpendicular surfaces from the inside.
; Finds the intersection point of the two surfaces and logs the result.
;
; USAGE: G6509 [X<x-surface>] [Y<y-surface>] [F<speed>] [R<retries>] [C<clearance>] [L<depth>] [O<overtravel>]
;
; Parameters:
;   X: Target coordinate for X-axis surface probe (defaults to current X + overtravel)
;   Y: Target coordinate for Y-axis surface probe (defaults to current Y + overtravel)
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging
;   C: Clearance distance between probes (default: 5mm)
;   L: Depth to move down before probing (default: 5mm)
;   O: Overtravel distance beyond expected surfaces for default targets (default: 10mm)
;
; The corner coordinates are logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6509: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6509: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6509: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Set defaults
var clearance = { exists(param.C) ? param.C : 5.0 }
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var probeDepth = { exists(param.L) ? param.L : 5.0 }
var overtravel = { exists(param.O) ? param.O : 10.0 }

echo "G6509: Starting inside corner probe"

; Get current position for planning probe moves (preserve starting position)
M5000
var startX = { global.nxtAbsPos[0] }
var startY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Set default targets if not provided (current position + overtravel for inside corner)
var xTarget = { exists(param.X) ? param.X : var.startX + var.overtravel }
var yTarget = { exists(param.Y) ? param.Y : var.startY + var.overtravel }

; Probe X surface first
echo "G6509: Probing X surface"

; Move to X probe position (away from corner by clearance distance)
var xProbeY = { var.yTarget > var.startY ? var.yTarget - var.clearance : var.yTarget + var.clearance }
G6550 X{var.startX} Y{var.xProbeY}

; Move down to probe depth
var probeZ = { var.startZ - var.probeDepth }
G6550 Z{var.probeZ}

; Execute X surface probe
G6512 X{var.xTarget} Y{var.xProbeY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var xSurface = { global.nxtLastProbeResult }

; Return to start height
G6550 Z{var.startZ}

; Move away from X surface
var xClearPos = { var.xTarget > var.startX ? var.xTarget - var.clearance : var.xTarget + var.clearance }
G6550 X{var.xClearPos}

; Probe Y surface second
echo "G6509: Probing Y surface"

; Move to Y probe position (away from corner by clearance distance)
var yProbeX = { var.xTarget > var.startX ? var.xTarget - var.clearance : var.xTarget + var.clearance }
G6550 X{var.yProbeX} Y{var.startY}

; Move down to probe depth
G6550 Z{var.probeZ}

; Execute Y surface probe
G6512 X{var.yProbeX} Y{var.yTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var ySurface = { global.nxtLastProbeResult }

; Return to start height
G6550 Z{var.startZ}

; The corner coordinates are the intersection of the two surfaces
var cornerX = { var.xSurface }
var cornerY = { var.ySurface }

; Log results to probe results table
; Find the next available slot in the results table
var resultIndex = 0
while { var.resultIndex < #global.nxtProbeResults && 
        (global.nxtProbeResults[var.resultIndex][0] != 0 || global.nxtProbeResults[var.resultIndex][1] != 0) }
    set var.resultIndex = { var.resultIndex + 1 }

; If table is full, use the last slot
if { var.resultIndex >= #global.nxtProbeResults }
    set var.resultIndex = { #global.nxtProbeResults - 1 }

; Initialize the result vector if needed
if { #global.nxtProbeResults[var.resultIndex] < 3 }
    set global.nxtProbeResults[var.resultIndex] = { vector(3, 0.0) }

; Store both X and Y results
set global.nxtProbeResults[var.resultIndex][0] = { var.cornerX }
set global.nxtProbeResults[var.resultIndex][1] = { var.cornerY }

; Return to safe height
G27 Z1

echo "G6509: Inside corner probe completed"
echo "G6509: Corner found at X=" ^ var.cornerX ^ " Y=" ^ var.cornerY
echo "G6509: Result logged to table index " ^ var.resultIndex