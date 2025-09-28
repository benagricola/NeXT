; tfree.g: FREE CURRENT TOOL
;
; Executed by RRF before a tool is freed (unloaded).
; Implements "probe-on-removal" logic for standard cutting tools.
;
; For standard cutting tools: Measures the tool length using the toolsetter
; before removal to cache the measurement for relative offset calculations.
; For probe tool: Prompts operator to safely remove and stow the probe.

; Set tool change state to initial
set global.nxtToolChangeState = 0

; Ensure all axes are homed
if { !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed }
    abort "tfree.g: All axes must be homed before tool change"

; Stop spindle and park to safe position
G27 Z1

; Check if this is the probe tool
if { state.currentTool == global.nxtProbeToolID }
    ; Probe tool removal - just prompt operator to remove
    var toolName = { global.nxtFeatureTouchProbe ? "Touch Probe" : "Datum Tool" }
    if { global.nxtUiReady }
        ; TODO: Use UI confirmation when available
        M291.9 P{"Remove " ^ var.toolName ^ " and confirm when safely stowed"} R"Tool Change" S3 T0
    else
        M291.9 P{"Remove " ^ var.toolName ^ " and confirm when safely stowed"} R"Tool Change" S3 T0
else
    ; Standard cutting tool removal - measure on toolsetter if feature is enabled
    if { global.nxtFeatureToolSetter && global.nxtToolSetterPos != null }
        ; Only measure if we don't already have a cached measurement for this session
        if { global.nxtToolCache[state.currentTool] == null }
            echo "tfree.g: Measuring tool T" ^ state.currentTool ^ " before removal"
            
            ; Move to toolsetter position
            G53 G0 X{global.nxtToolSetterPos[0]} Y{global.nxtToolSetterPos[1]}
            G53 G0 Z{global.nxtToolSetterPos[2] + 10}  ; 10mm above toolsetter
            
            ; Probe the tool on toolsetter
            G6512 Z{global.nxtToolSetterPos[2] - 5} I{global.nxtToolSetterID}
            
            ; Cache the measurement result for this session only
            ; Note: Tool length will change if the tool is physically removed and reinstalled
            set global.nxtToolCache[state.currentTool] = global.nxtLastProbeResult
            
            echo "tfree.g: Tool T" ^ state.currentTool ^ " measured at Z=" ^ global.nxtLastProbeResult
            
            ; Return to safe position
            G27 Z1

; Store the previous tool's offset for relative calculations
set global.nxtPreviousToolOffset = { tools[state.currentTool].offsets[2] }

; Set tool change state to indicate tfree.g completion
set global.nxtToolChangeState = 1