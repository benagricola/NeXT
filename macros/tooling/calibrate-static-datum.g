; calibrate-static-datum.g: CALIBRATE STATIC DATUM (nxtDeltaMachine)
;
; Performs one-time calibration of the static Z distance between the toolsetter
; and reference surface. This establishes the machine's core geometry.
;
; USAGE: M98 P"calibrate-static-datum.g"
;
; This process requires:
; 1. A datum tool (rigid, known geometry)
; 2. Configured toolsetter position
; 3. Configured reference surface position
;
; The operator will be guided through:
; 1. Installing the datum tool
; 2. Measuring the toolsetter activation point
; 3. Measuring the reference surface
; 4. Calculating and storing nxtDeltaMachine

echo "Static Datum Calibration: Starting calibration process"

; Validate required configuration
if { global.nxtToolSetterPos == null }
    abort "Static Datum Calibration: Toolsetter position not configured"

if { global.nxtReferencePos == null }
    abort "Static Datum Calibration: Reference surface position not configured"

if { !global.nxtFeatureToolSetter }
    abort "Static Datum Calibration: Toolsetter feature must be enabled"

; Ensure all axes are homed
if { !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed }
    abort "Static Datum Calibration: All axes must be homed"

; Stop spindle and park
G27 Z1

; Step 1: Install datum tool
echo "Static Datum Calibration: Step 1 - Install Datum Tool"
if { global.nxtUiReady }
    M291.9 P"Install datum tool (rigid reference tool) and press OK when ready" R"Static Datum Calibration" S3 T0
else
    M291.9 P"Install datum tool (rigid reference tool) and press OK when ready" R"Static Datum Calibration" S3 T0

; Step 2: Measure toolsetter with datum tool
echo "Static Datum Calibration: Step 2 - Measuring toolsetter activation point"

; Move to toolsetter position
G53 G0 X{global.nxtToolSetterPos[0]} Y{global.nxtToolSetterPos[1]}
G53 G0 Z{global.nxtToolSetterPos[2] + 10}  ; 10mm above toolsetter

; Probe the toolsetter
G6512 Z{global.nxtToolSetterPos[2] - 5} I{global.nxtToolSetterID}

var datumOnToolsetter = global.nxtLastProbeResult
echo "Static Datum Calibration: Datum tool on toolsetter: Z=" ^ var.datumOnToolsetter

; Step 3: Measure reference surface with datum tool
echo "Static Datum Calibration: Step 3 - Measuring reference surface"

; Guide operator to move to reference surface
if { global.nxtUiReady }
    M291.9 P"Move datum tool to reference surface position and press OK to continue" R"Static Datum Calibration" S3 T0
else
    M291.9 P"Move datum tool to reference surface position and press OK to continue" R"Static Datum Calibration" S3 T0

; Move to reference surface position
G53 G0 X{global.nxtReferencePos[0]} Y{global.nxtReferencePos[1]}
G53 G0 Z{global.nxtReferencePos[2] + 10}  ; 10mm above reference surface

; Probe the reference surface
if { global.nxtFeatureTouchProbe }
    ; Use touch probe sensor for reference surface
    G6512 Z{global.nxtReferencePos[2] - 5} I{global.nxtTouchProbeID}
else
    ; Manual probing on reference surface
    M291.9 P"Manually jog datum tool to touch reference surface, then press OK" R"Static Datum Calibration" S3 T0
    ; Get current position as the reference
    M5000
    set global.nxtLastProbeResult = global.nxtAbsPos[2]

var datumOnReference = global.nxtLastProbeResult
echo "Static Datum Calibration: Datum tool on reference surface: Z=" ^ var.datumOnReference

; Store the calculated delta machine
set global.nxtDeltaMachine = var.calculatedDelta

; Park and complete
G27 Z1

echo {"Static Datum Calibration: Calibration completed successfully"}
echo {"Static Datum Calibration: nxtDeltaMachine = " ^ global.nxtDeltaMachine ^ "mm"}

echo "Static Datum Calibration: Calculated nxtDeltaMachine = " ^ global.nxtDeltaMachine

; Step 5: Validation
if { abs(global.nxtDeltaMachine) > 100 }
    echo "Static Datum Calibration: WARNING - Large delta value (" ^ global.nxtDeltaMachine ^ "mm). Please verify measurements."

; Cache the datum tool measurement
set global.nxtToolCache[global.nxtProbeToolID] = var.datumOnReference

; Park and complete
G27 Z1

echo "Static Datum Calibration: Calibration completed successfully"
echo "Static Datum Calibration: nxtDeltaMachine = " ^ global.nxtDeltaMachine ^ "mm"

if { global.nxtUiReady }
    M291.9 P{"Static datum calibrated: " ^ global.nxtDeltaMachine ^ "mm. Remove datum tool when ready."} R"Calibration Complete" S1 T0
else
    M291.9 P{"Static datum calibrated: " ^ global.nxtDeltaMachine ^ "mm. Remove datum tool when ready."} R"Calibration Complete" S1 T0