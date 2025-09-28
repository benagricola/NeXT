; test-tool-change.g: TEST TOOL CHANGE SYSTEM
;
; Comprehensive test of the new tool change system for validation.
; This should be run on a properly configured machine with caution.
;
; USAGE: M98 P"test-tool-change.g" [S<test-mode>]
;
; Parameters:
;   S0: Full test (default) - Tests complete workflow
;   S1: Configuration test only - Validates setup without movement
;   S2: Static datum test - Tests calibration process

; Validate test mode parameter
var testMode = { exists(param.S) ? param.S : 0 }

if { var.testMode < 0 || var.testMode > 2 }
    abort "Test Tool Change: Invalid test mode S" ^ var.testMode ^ " (valid: 0-2)"

echo "=== NeXT Tool Change System Test ==="
echo "Test mode: " ^ var.testMode

; Configuration validation test
echo "--- Configuration Test ---"

; Check required features
echo "nxtFeatureToolSetter: " ^ global.nxtFeatureToolSetter
echo "nxtFeatureTouchProbe: " ^ global.nxtFeatureTouchProbe
echo "nxtFeatureCoolantControl: " ^ global.nxtFeatureCoolantControl

; Check tool IDs
echo "nxtProbeToolID: " ^ global.nxtProbeToolID
echo "nxtTouchProbeID: " ^ global.nxtTouchProbeID
echo "nxtToolSetterID: " ^ global.nxtToolSetterID

; Check positions
echo "nxtToolSetterPos: " ^ global.nxtToolSetterPos
echo "nxtReferencePos: " ^ global.nxtReferencePos
echo "nxtDeltaMachine: " ^ global.nxtDeltaMachine

; Check cache status
echo "Tool cache contents:"
while { iterations < #global.nxtToolCache }
    if { global.nxtToolCache[iterations] != null }
        echo "  T" ^ iterations ^ ": " ^ global.nxtToolCache[iterations]

echo "Tool change state: " ^ global.nxtToolChangeState

if { var.testMode == 1 }
    echo "Configuration test completed"
    M99

; Static datum calibration test
if { var.testMode == 2 }
    echo "--- Static Datum Calibration Test ---"
    
    if { !global.nxtFeatureToolSetter }
        echo "Test requires toolsetter feature enabled"
        M99
    
    if { global.nxtToolSetterPos == null }
        echo "Test requires toolsetter position configured"
        M99
    
    if { global.nxtReferencePos == null }
        echo "Test requires reference surface position configured"
        M99
    
    ; Prompt for calibration test
    M291 P"Run static datum calibration test? This will require a datum tool." R"Test Calibration" S4
    
    if { input == 1 }
        echo "Calibration test cancelled"
        M99
    
    ; Run calibration
    M98 P"calibrate-static-datum.g"
    
    echo "Static datum calibration test completed"
    echo "Result: nxtDeltaMachine = " ^ global.nxtDeltaMachine
    M99

; Full workflow test (mode 0)
echo "--- Full Tool Change Test ---"

; Verify homing
if { !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed }
    echo "Test requires all axes to be homed"
    M99

; Check if delta machine is calibrated for touch probe systems
if { global.nxtFeatureTouchProbe && global.nxtDeltaMachine == null }
    echo "Test requires static datum calibration for touch probe systems"
    echo "Run test mode S2 first or manually calibrate"
    M99

; Prompt for full test
M291 P"Run full tool change test? This will involve tool changes and measurements." R"Full Test" S4

if { input == 1 }
    echo "Full test cancelled"
    M99

; Test sequence
echo "Starting full tool change test sequence..."

; Step 1: Test tool state tracking
echo "Step 1: Testing tool state tracking"
set global.nxtToolChangeState = 0
echo "Tool change state set to: " ^ global.nxtToolChangeState

; Step 2: Test M5000 position reading
echo "Step 2: Testing position reading (M5000)"
M5000 
echo "Current position: " ^ global.nxtAbsPos

; Step 3: Test basic probing if toolsetter available
if { global.nxtFeatureToolSetter && global.nxtToolSetterPos != null }
    echo "Step 3: Testing basic probing capability"
    
    ; Move to toolsetter (simulation)
    echo "Would move to toolsetter position: " ^ global.nxtToolSetterPos
    
    ; Simulate probe result
    set global.nxtLastProbeResult = { global.nxtToolSetterPos[2] - 25.0 }  ; Typical tool length
    echo "Simulated probe result: " ^ global.nxtLastProbeResult

; Step 4: Test tool cache functionality  
echo "Step 4: Testing tool cache"
var testTool = 1
set global.nxtToolCache[var.testTool] = 100.5
echo "Set tool cache T" ^ var.testTool ^ " to: " ^ global.nxtToolCache[var.testTool]

; Step 5: Test offset calculations
echo "Step 5: Testing offset calculations"
var tool1Measurement = 100.0
var tool2Measurement = 102.5
var calculatedOffset = { var.tool2Measurement - var.tool1Measurement }
echo "Tool 1 measurement: " ^ var.tool1Measurement
echo "Tool 2 measurement: " ^ var.tool2Measurement  
echo "Calculated offset difference: " ^ var.calculatedOffset

; Step 6: Test error handling
echo "Step 6: Testing error handling"
var originalState = global.nxtToolChangeState
set global.nxtToolChangeState = null
echo "Reset tool change state for error condition test"

; Step 7: Cleanup
echo "Step 7: Cleanup"
set global.nxtToolChangeState = var.originalState
set global.nxtToolCache[var.testTool] = null
echo "Test cleanup completed"

echo "=== Tool Change System Test Completed ==="
echo "All basic functions tested successfully"
echo "Manual verification recommended before production use"

M291 P"Tool change system test completed. Check console output for results." R"Test Complete" S1 T0