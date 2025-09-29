; G6550.g: PROTECTED MOVE
;
; Performs a protected move with probe-aware safety checks.
; If a touch probe is triggered unexpectedly during movement, 
; the move is aborted immediately for safety.
;
; USAGE: G6550 [X<pos>] [Y<pos>] [Z<pos>] [A<pos>] I<probeID> [F<speed>]
;
; Parameters:
;   X|Y|Z|A: Target coordinates (any combination allowed)
;   I:       Probe ID to monitor (e.g., global.nxtTouchProbeID)
;   F:       Optional speed override in mm/min

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; --- Parameter Validation ---
if { !exists(param.I) || param.I == null || param.I < 0 }
    abort { "G6550: Probe ID parameter I is required" }

; Validate probe exists and is a touch probe
if { param.I >= #sensors.probes || sensors.probes[param.I] == null }
    abort { "G6550: Invalid probe ID " ^ param.I }

; Build target coordinates, using current position for unspecified axes
M5000
var targetX = { exists(param.X) ? param.X : global.nxtAbsPos[0] }
var targetY = { exists(param.Y) ? param.Y : global.nxtAbsPos[1] }
var targetZ = { exists(param.Z) ? param.Z : global.nxtAbsPos[2] }
var targetA = { exists(param.A) ? param.A : global.nxtAbsPos[3] }

; Validate target against machine limits
M6515 X{var.targetX} Y{var.targetY} Z{var.targetZ} A{var.targetA}

; Determine speed
var feedRate = { exists(param.F) ? param.F : sensors.probes[param.I].travelSpeed }

; Check if this is only a positive Z move (safe direction)
var currentZ = { global.nxtAbsPos[2] }
var isOnlyPositiveZ = { exists(param.Z) && var.targetZ > var.currentZ && 
                       !exists(param.X) && !exists(param.Y) && !exists(param.A) }

; If only moving up in Z, this is safe - no probe protection needed
if { var.isOnlyPositiveZ }
    G53 G1 F{var.feedRate} Z{var.targetZ}
    M99

; Check if probe is already triggered
if { sensors.probes[param.I].value[0] != 0 }
    ; Probe is triggered - calculate backoff position
    var backoffDistance = { sensors.probes[param.I].diveHeights[0] }
    
    ; Calculate direction vector from current to target
    var deltaX = { var.targetX - global.nxtAbsPos[0] }
    var deltaY = { var.targetY - global.nxtAbsPos[1] }
    var deltaZ = { var.targetZ - global.nxtAbsPos[2] }
    var deltaA = { exists(param.A) ? (var.targetA - global.nxtAbsPos[3]) : 0 }
    
    ; Calculate magnitude of movement vector
    var magnitude = { sqrt(var.deltaX^2 + var.deltaY^2 + var.deltaZ^2) }
    
    if { var.magnitude > 0 }
        ; Normalize and scale by backoff distance
        var backoffX = { global.nxtAbsPos[0] - (var.deltaX / var.magnitude * var.backoffDistance) }
        var backoffY = { global.nxtAbsPos[1] - (var.deltaY / var.magnitude * var.backoffDistance) }
        var backoffZ = { global.nxtAbsPos[2] - (var.deltaZ / var.magnitude * var.backoffDistance) }
        var backoffA = { global.nxtAbsPos[3] - (var.deltaA / var.magnitude * var.backoffDistance) }
        
        ; Move to backoff position
        G53 G1 F{var.feedRate} X{var.backoffX} Y{var.backoffY} Z{var.backoffZ} A{var.backoffA}
        M400
        
        ; Check if probe is still triggered after backoff
        if { sensors.probes[param.I].value[0] != 0 }
            abort { "G6550: Probe still triggered after backoff - unsafe to continue" }

; Execute the main protected move using G38.3 (move until probe triggers or target reached)
; G38.3 stops when the probe triggers, which provides the protection we need
G53 G38.3 K{param.I} F{var.feedRate} X{var.targetX} Y{var.targetY} Z{var.targetZ} A{var.targetA}

; Update position after move
M5000

echo "G6550: Protected move completed"