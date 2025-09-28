; nxt-vars.g
; Defines default global variables for the NeXT system.

; --- Features ---
global nxtFeatureTouchProbe = false
global nxtFeatureToolSetter = false
global nxtFeatureCoolantControl = false ; Coolant Control feature flag

; --- Core Settings ---
global nxtProbeToolID = { limits.tools - 1 } ; Probe Tool ID, always the last tool
global nxtTouchProbeID = 0             ; The ID of the touch probe sensor
global nxtToolSetterID = 1             ; The ID of the tool setter sensor
global nxtError = null               ; Stores the last error message
global nxtLoaded = false              ; Tracks if NeXT has loaded successfully
global nxtUiReady = false          ; Flag to indicate if the NeXT UI is loaded and ready for interaction

; --- Tooling & Probing ---
global nxtDeltaMachine = null      ; The static Z distance between the toolsetter and reference surface
global nxtProbeResults = vector(10, {0.0, 0.0, 0.0}) ; A table to store the last 10 probe results
global nxtLastProbeResult = null   ; Stores the result of the last probing operation
global nxtProbeTipRadius = 0.0    ; Radius of the probe tip for compensation (mm)
global nxtProbeDeflection = 0.0   ; Probe deflection compensation value (mm)
global nxtToolSetterPos = null     ; Toolsetter position vector [X, Y, Z]
global nxtReferencePos = null      ; Reference surface position for touch probe calibration

; --- Tool Information Arrays ---
global nxtToolNames = vector(limits.tools, "")  ; Tool names/descriptions
global nxtToolRadii = vector(limits.tools, 0.0) ; Tool radii in mm

; --- Tool Change State Management ---
global nxtToolChangeState = null   ; Current state of tool change process (0-4)
global nxtPreviousToolOffset = null ; Z offset of the previous tool for relative calculations
global nxtAbsPos = vector(4, 0.0)  ; Current absolute machine position (from M5000)
global nxtProbeDetected = null     ; ID of the last probe that had a status change (for M8002)

; --- Coolant Control ---
global nxtCoolantAirID = null ; Coolant Air Output Pin ID
global nxtCoolantMistID = null ; Coolant Mist Output Pin ID
global nxtCoolantFloodID = null ; Coolant Flood Output Pin ID
global nxtPinStates = { vector(limits.gpOutPorts, 0.0) } ; Tracks the state of gpOut pins for coolant

; --- Spindle Control ---
global nxtSpindleID = null  ; Default Spindle ID
global nxtSpindleAccelSec = null  ; Spindle Acceleration Time (seconds)
global nxtSpindleDecelSec = null  ; Spindle Deceleration Time (seconds)

