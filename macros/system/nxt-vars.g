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
global nxtProbeResults = vector(10, null) ; A table to store the last 10 probe results (initialized to proper length per machine)
global nxtToolCache = vector(limits.tools, null) ; A cache for tool measurement results per session
global nxtLastProbeResult = null   ; Stores the result of the last probing operation
global nxtProbeTipRadius = 0.0    ; Radius of the probe tip for compensation (mm)
global nxtProbeDeflection = 0.0   ; Probe deflection compensation value (mm)
global nxtToolSetterPos = null     ; Toolsetter position vector [X, Y, Z]
global nxtToolChangeState = null   ; Tracks the current tool change state (1=tfree, 2=tfree done, 3=tpre done, 4=tpost, null=complete)

; --- Coolant Control ---
global nxtCoolantAirID = null ; Coolant Air Output Pin ID
global nxtCoolantMistID = null ; Coolant Mist Output Pin ID
global nxtCoolantFloodID = null ; Coolant Flood Output Pin ID
global nxtPinStates = { vector(limits.gpOutPorts, 0.0) } ; Tracks the state of gpOut pins for coolant

; --- Spindle Control ---
global nxtSpindleID = null  ; Default Spindle ID
global nxtSpindleAccelSec = null  ; Spindle Acceleration Time (seconds)
global nxtSpindleDecelSec = null  ; Spindle Deceleration Time (seconds)

; --- Dialog System (for M1000 and UI integration) ---
global nxtDialogActive = false    ; Flag indicating if a dialog is currently active
global nxtDialogMessage = null    ; Current dialog message text
global nxtDialogTitle = null      ; Current dialog title
global nxtDialogButtons = null    ; Array of button labels for current dialog
global nxtDialogResponse = null   ; Response from user (button index clicked)

