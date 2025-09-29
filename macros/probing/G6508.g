; G6508.g: OUTSIDE CORNER PROBE
;
; Probes an outside corner by probing two perpendicular surfaces.
; Finds the intersection point of the two surfaces and logs the result.
;
; USAGE: G6508 P<index> L<depth> [X<x-surface>] [Y<y-surface>] [F<speed>] [R<retries>] [C<clearance>]
;
; Parameters:
;   P: Result table index (0-based) where results will be stored - REQUIRED
;   L: Depth to move down before probing - REQUIRED
;   X: Target coordinate for X-axis surface probe (defaults to current X - overtravel)
;   Y: Target coordinate for Y-axis surface probe (defaults to current Y - overtravel)
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging
;   C: Clearance distance between probes (default: 5mm)
;
; The corner coordinates are logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6508: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6508: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6508: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Validate required parameters
if { !exists(param.P) || param.P == null || param.P < 0 }
    abort { "G6508: Result index parameter P is required and must be >= 0" }

if { param.P >= #global.nxtProbeResults }
    abort { "G6508: Result index P=" ^ param.P ^ " exceeds table size (" ^ #global.nxtProbeResults ^ ")" }

if { !exists(param.L) }
    abort { "G6508: Depth (L) parameter is required" }

; Set parameters
var clearance = { exists(param.C) ? param.C : 5.0 }
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var probeDepth = { param.L }

echo "G6508: Starting outside corner probe"

; Get current position for planning probe moves (preserve starting position)
M5000
var startX = { global.nxtAbsPos[0] }
var startY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Set default targets if not provided (current position for outside corner)
var xTarget = { exists(param.X) ? param.X : var.startX - 10.0 }
var yTarget = { exists(param.Y) ? param.Y : var.startY - 10.0 }

; Probe X surface first
echo "G6508: Probing X surface"

; Move to X probe position (away from corner by clearance distance)
var xProbeY = { var.yTarget > var.startY ? var.yTarget + var.clearance : var.yTarget - var.clearance }
G6550 X{var.startX} Y{var.xProbeY}

; Move down to probe depth
var probeZ = { var.startZ - var.probeDepth }
G6550 Z{var.probeZ}

; Execute X surface probe
G6512 X{var.xTarget} Y{var.xProbeY} Z{var.probeZ} F{var.feedRate} R{var.retries}
var xSurface = { global.nxtLastProbeResult }

; Return to start height
G6550 Z{var.startZ}

; Move away from X surface
var xClearPos = { var.xTarget > var.startX ? var.xTarget - var.clearance : var.xTarget + var.clearance }
G6550 X{var.xClearPos}

; Probe Y surface second
echo "G6508: Probing Y surface"

; Move to Y probe position (away from corner by clearance distance)
var yProbeX = { var.xTarget > var.startX ? var.xTarget + var.clearance : var.xTarget - var.clearance }
G6550 X{var.yProbeX} Y{var.startY}

; Move down to probe depth
G6550 Z{var.probeZ}

; Execute Y surface probe
G6512 X{var.yProbeX} Y{var.yTarget} Z{var.probeZ} F{var.feedRate} R{var.retries}
var ySurface = { global.nxtLastProbeResult }

; Return to start height
G6550 Z{var.startZ}

; Execute Y surface probe
G6512 X{var.yProbeX} Y{param.Y} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var ySurface = { global.nxtLastProbeResult }

; Return to start height
G6550 Z{var.startZ}

; The corner coordinates are the intersection of the two surfaces
var cornerX = { var.xSurface }
var cornerY = { var.ySurface }

; Log results to probe results table
; Use the specified result index directly
var resultIndex = { param.P }

; Initialize the result vector if needed
if { #global.nxtProbeResults[var.resultIndex] < 3 }
    set global.nxtProbeResults[var.resultIndex] = { vector(#move.axes + 1, 0.0) }

; Store both X and Y results
set global.nxtProbeResults[var.resultIndex][0] = { var.cornerX }
set global.nxtProbeResults[var.resultIndex][1] = { var.cornerY }

; Return to safe height
G27 Z1

echo "G6508: Outside corner probe completed"
echo "G6508: Corner found at X=" ^ var.cornerX ^ " Y=" ^ var.cornerY
echo "G6508: Result logged to table index " ^ var.resultIndex

echo "G6508: Outside corner probe completed"
echo "G6508: Corner found at X=" ^ var.cornerX ^ " Y=" ^ var.cornerY
echo "G6508: Result logged to table index " ^ var.resultIndex