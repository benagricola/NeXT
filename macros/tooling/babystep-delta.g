; babystep-delta.g: BABYSTEP nxtDeltaMachine VALUE
;
; Allows fine adjustment of the static datum (nxtDeltaMachine) without
; requiring full recalibration. Useful for thermal drift compensation.
;
; USAGE: M98 P"babystep-delta.g" S<adjustment>
;
; Parameters:
;   S<adjustment>: The adjustment value in mm (positive or negative)
;                  Typical range: +/- 0.1mm

; Validate adjustment parameter
if { !exists(param.S) || param.S == null }
    abort "Babystep Delta: S parameter (adjustment in mm) required"

; Validate adjustment range (safety check)
if { abs(param.S) > 1.0 }
    abort "Babystep Delta: Adjustment too large (" ^ param.S ^ "mm). Maximum allowed: ±1.0mm"

; Check if delta machine is calibrated
if { global.nxtDeltaMachine == null }
    abort "Babystep Delta: nxtDeltaMachine not calibrated. Run static datum calibration first."

; Store original value
var originalDelta = global.nxtDeltaMachine

; Apply adjustment
set global.nxtDeltaMachine = { global.nxtDeltaMachine + param.S }

echo "Babystep Delta: Adjusted nxtDeltaMachine"
echo "Babystep Delta: Original value: " ^ var.originalDelta ^ "mm"
echo "Babystep Delta: Adjustment: " ^ param.S ^ "mm"
echo "Babystep Delta: New value: " ^ global.nxtDeltaMachine ^ "mm"

; Confirmation dialog
if { global.nxtUiReady }
    M291 P{"Delta adjusted by " ^ param.S ^ "mm. New value: " ^ global.nxtDeltaMachine ^ "mm"} R"Babystep Delta" S1 T0
else
    M291 P{"Delta adjusted by " ^ param.S ^ "mm. New value: " ^ global.nxtDeltaMachine ^ "mm"} R"Babystep Delta" S1 T0