; M8002.g: WAIT FOR PROBE STATUS CHANGE BY ID
;
; Waits for a specific probe to change its status (for touch probe detection).
;
; USAGE: M8002 K<probe-id> [D<delay-ms>] [W<max-wait-s>]
;
; Parameters:
;   K<probe-id>:  The ID of the probe to monitor for status change
;   D<delay-ms>:  Delay between checks in milliseconds (default: 100ms)
;   W<max-wait-s>: Maximum time to wait in seconds (default: 30s)

; Validate probe ID parameter
if { !exists(param.K) || param.K < 0 || param.K >= #sensors.probes }
    abort "M8002: Invalid probe ID K" ^ param.K

; Check probe type compatibility
if { sensors.probes[param.K].type < 5 || sensors.probes[param.K].type > 8 }
    abort "M8002: Probe " ^ param.K ^ " is not a compatible type (must be type 5-8)"

; Set defaults
var probeID = param.K
var delay = { exists(param.D) ? param.D : 100 }
var maxWaitMs = { (exists(param.W) ? param.W : 30) * 1000 }

; Initialize detection tracking
set global.nxtProbeDetected = null
var previousValue = null
var startTime = state.upTime
var currentTime = state.upTime

echo "M8002: Waiting for probe " ^ var.probeID ^ " status change..."

; Main detection loop
while { (var.currentTime - var.startTime) < var.maxWaitMs }
    var currentValue = sensors.probes[var.probeID].value[0]
    
    ; Check for status change
    if { var.previousValue != null && var.currentValue != var.previousValue }
        set global.nxtProbeDetected = var.probeID
        echo "M8002: Probe " ^ var.probeID ^ " status change detected"
        M99  ; Exit successfully
    
    ; Update tracking variables
    set var.previousValue = var.currentValue
    
    ; Wait before next check
    G4 P{var.delay}
    
    ; Update current time (handle potential rollover)
    set var.currentTime = state.upTime
    if { var.currentTime < var.startTime }
        ; Handle upTime rollover
        set var.currentTime = { var.currentTime + 4294967296 }

; Timeout reached
abort "M8002: Timeout waiting for probe " ^ var.probeID ^ " status change after " ^ (var.maxWaitMs/1000) ^ " seconds"