; tfree.g: TOOL FREE - EXECUTED BY RRF BEFORE TOOL UNLOAD
;
; This macro is executed automatically by RepRapFirmware before a tool
; is freed (unloaded). It handles probe-on-removal logic for standard
; cutting tools and special handling for the touch probe.
;
; NO PARAMETERS - called automatically by RRF

; Skip if no tool is currently selected
if { state.currentTool < 0 }
    M99

; Validate all axes are homed
while { iterations < #move.axes }
    if { !move.axes[iterations].homed }
        abort { "tfree.g: Axis " ^ move.axes[iterations].letter ^ " must be homed before tool change" }

; Set tool change state to indicate tfree.g started
global nxtToolChangeState = 1

; Stop and park spindle for safety
G27 Z1

; Check if current tool is the probe tool
if { state.currentTool == global.nxtProbeToolID }
    ; Handle probe tool removal
    var probeType = { global.nxtFeatureTouchProbe ? "Touch Probe" : "Datum Tool" }
    M291 P{"Please remove the " ^ var.probeType ^ " and confirm when safely stowed."} R{"Remove " ^ var.probeType} S3
    
    ; Clear any cached measurements for the probe tool
    set global.nxtToolCache[state.currentTool] = { null }
else
    ; Handle standard cutting tool - perform probe-on-removal
    if { global.nxtFeatureToolSetter && global.nxtToolSetterPos != null }
        ; Measure tool length before removal for relative offset calculation
        echo "tfree.g: Measuring tool " ^ state.currentTool ^ " before removal"
        
        ; Move to toolsetter and measure
        G37
        
        ; Cache the measurement result for relative offset calculations
        set global.nxtToolCache[state.currentTool] = { global.nxtLastProbeResult }
        
        echo "tfree.g: Tool " ^ state.currentTool ^ " measured at Z=" ^ global.nxtLastProbeResult
    else
        ; No toolsetter - just prompt for manual removal
        M291 P{"Please remove Tool " ^ state.currentTool ^ " and confirm when complete."} R"Remove Tool" S3

; Set tool change state to indicate tfree.g completed
global nxtToolChangeState = 2

echo "tfree.g: Tool " ^ state.currentTool ^ " removal process completed"