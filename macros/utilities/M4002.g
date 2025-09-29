; M4002.g: BABYSTEP nxtDeltaMachine VALUE
;
; Allows fine adjustment of the static datum (nxtDeltaMachine) without
; requiring full recalibration. Useful for thermal drift compensation.
;
; USAGE: M4002 S<adjustment>
;
; Parameters:
;   S<adjustment>: The adjustment value in mm (positive or negative)
;                  Typical range: +/- 0.1mm

; Validate adjustment parameter
if { !exists(param.S) || param.S == null }
    abort "M4002: S parameter (adjustment in mm) required"

; Validate adjustment range (safety check)
if { abs(param.S) > 1.0 }
    abort "M4002: Adjustment too large (" ^ param.S ^ "mm). Maximum allowed: ±1.0mm"

; Check if delta machine is calibrated
if { global.nxtDeltaMachine == null }
    abort "M4002: nxtDeltaMachine not calibrated. Run static datum calibration first."

; Store original value
var originalDelta = global.nxtDeltaMachine

; Apply adjustment
set global.nxtDeltaMachine = { global.nxtDeltaMachine + param.S }

echo "M4002: Adjusted nxtDeltaMachine"
echo "M4002: Original value: " ^ var.originalDelta ^ "mm"
echo "M4002: Adjustment: " ^ param.S ^ "mm"
echo "M4002: New value: " ^ global.nxtDeltaMachine ^ "mm"

; Confirmation dialog
M291.9 P{"Delta adjusted by " ^ param.S ^ "mm. New value: " ^ global.nxtDeltaMachine ^ "mm"} R"Babystep Delta" S1 T0