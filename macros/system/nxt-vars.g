; nxt-vars.g
; Defines default global variables for the NeXT system.

; --- System Information ---
global nxtAbsPos = vector(4, 0.0)       ; Current tool-compensated absolute position [X,Y,Z,A]

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
global nxtExpertMode = false        ; Expert mode flag to skip safety warnings

; --- Tooling & Probing ---
global nxtDeltaMachine = null      ; The static Z distance between the toolsetter and reference surface
global nxtProbeResults = vector(10, {0.0, 0.0, 0.0}) ; A table to store the last 10 probe results
global nxtToolCache = vector(limits.tools, null) ; A cache for tool measurement results per session
global nxtLastProbeResult = null   ; Stores the result of the last probing operation
global nxtProbeTipRadius = 0.0    ; Radius of the probe tip for compensation (mm)
global nxtProbeDeflection = 0.0   ; Probe deflection compensation value (mm)
global nxtToolSetterPos = null     ; Toolsetter position vector [X, Y, Z]

; --- Coolant Control ---
global nxtCoolantAirID = null ; Coolant Air Output Pin ID
global nxtCoolantMistID = null ; Coolant Mist Output Pin ID
global nxtCoolantFloodID = null ; Coolant Flood Output Pin ID
global nxtPinStates = { vector(limits.gpOutPorts, 0.0) } ; Tracks the state of gpOut pins for coolant

; --- Spindle Control ---
global nxtSpindleID = null  ; Default Spindle ID
global nxtSpindleAccelSec = null  ; Spindle Acceleration Time (seconds)
global nxtSpindleDecelSec = null  ; Spindle Deceleration Time (seconds)

; --- Tool Change System ---
global nxtToolChangeState = null  ; Tool change state tracking (0=free, 1=freed, 2=pre, 3=ready, 4=post)
global nxtReferenceSurface = null  ; Reference surface Z position for touch probe datum

