; tpre.g: TOOL PRE-CHANGE - EXECUTED BY RRF BEFORE TOOL LOAD
;
; This macro is executed automatically by RepRapFirmware before a new tool
; is loaded. It validates the tool change state and prepares for offset
; calculation based on the relative offsetting workflow.
;
; NO PARAMETERS - called automatically by RRF

; Validate that tfree.g completed properly
if { global.nxtToolChangeState != 2 }
    abort { "tpre.g: Tool change state invalid. tfree.g must complete before tpre.g" }

; Validate all axes are homed
while { iterations < #move.axes }
    if { !move.axes[iterations].homed }
        abort { "tpre.g: Axis " ^ move.axes[iterations].letter ^ " must be homed before tool change" }

; Set tool change state to indicate tpre.g started
global nxtToolChangeState = 3

; Stop and park spindle for safety
G27 Z1

; Get the tool number that will be loaded (from the pending tool change)
var newTool = { state.nextTool }

if { var.newTool < 0 }
    abort { "tpre.g: No valid tool selected for loading" }

; Prompt user to install the new tool
if { var.newTool == global.nxtProbeToolID }
    var probeType = { global.nxtFeatureTouchProbe ? "Touch Probe" : "Datum Tool" }
    M291 P{"Please install " ^ var.probeType ^ " (T" ^ var.newTool ^ ") and confirm when ready."} R{"Install " ^ var.probeType} S3
else
    M291 P{"Please install Tool " ^ var.newTool ^ " and confirm when ready."} R"Install Tool" S3

echo "tpre.g: Ready to load Tool " ^ var.newTool