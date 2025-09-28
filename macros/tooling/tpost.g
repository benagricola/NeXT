; tpost.g: POST TOOL CHANGE - EXECUTE
;
; Executed by RRF after a tool change has physically occurred.
; Implements the new relative offset calculation system.
; Handles different scenarios: probe->cutter, cutter->cutter, and calibration.

; Validate that tpre.g completed successfully
if { state.currentTool < 0 }
    abort "tpost.g: No tool selected"

if { global.nxtToolChangeState < 3 }
    abort "tpost.g: tpre.g did not complete successfully"

; Ensure all axes are homed
if { !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed }
    abort "tpost.g: All axes must be homed before tool measurement"

; Set tool change state to post-change
set global.nxtToolChangeState = 4

; Stop spindle and park to safe position
G27 Z1

; Handle probe tool installation
if { state.currentTool == global.nxtProbeToolID }
    if { global.nxtFeatureTouchProbe && global.nxtFeatureToolSetter }
        ; Touch probe installed - need to measure against reference surface
        ; This establishes the relationship between toolsetter and reference surface
        
        if { global.nxtReferencePos == null }
            abort "tpost.g: Reference surface position not configured. Please run calibration first."
        
        ; Move to reference surface and probe it
        echo "tpost.g: Measuring touch probe against reference surface"
        
        ; Move to reference surface XY position
        G53 G0 X{global.nxtReferencePos[0]} Y{global.nxtReferencePos[1]}
        G53 G0 Z{global.nxtReferencePos[2] + 10}  ; 10mm above reference
        
        ; Probe the reference surface
        G6512 Z{global.nxtReferencePos[2] - 5} I{global.nxtTouchProbeID}
        
        ; Set touch probe offset to 0 (it's our reference for the WCS)
        G10 P{state.currentTool} X0 Y0 Z0
        
        echo "tpost.g: Touch probe calibrated against reference surface"
        
    elif { global.nxtFeatureToolSetter }
        ; Toolsetter enabled but no touch probe - measure datum tool on toolsetter
        echo {"tpost.g: Measuring datum tool on toolsetter"}
        
        ; Probe the toolsetter from park position
        G6512 Z{move.axes[2].min} I{global.nxtToolSetterID}
        
        ; For datum tool, we establish the base reference but don't set an offset
        ; The measurement becomes the tool's reference offset
        ; Set datum tool offset to 0 (it's our reference)
        G10 P{state.currentTool} X0 Y0 Z0
        
        echo "tpost.g: Datum tool measured on toolsetter as reference"
    else
        ; No toolsetter - manual mode
        echo "tpost.g: Probe tool installed - manual mode"
        ; Set offset to 0, operator will set origins manually
        G10 P{state.currentTool} X0 Y0 Z0
else
    ; Standard cutting tool installation
    if { global.nxtFeatureToolSetter && global.nxtToolSetterPos != null }
        echo {"tpost.g: Measuring cutting tool T" ^ state.currentTool}
        
        ; Probe the cutting tool on toolsetter from park position
        G6512 Z{move.axes[2].min} I{global.nxtToolSetterID}
        
        var currentMeasurement = global.nxtLastProbeResult
        
        ; Calculate relative offset based on previous tool or reference
        var newOffset = 0.0
        
        if { global.nxtPreviousToolOffset != null }
            ; We have a previous tool offset - calculate relative difference
            var currentMeasurement = global.nxtLastProbeResult
            
            ; Find the previous tool's cached measurement for comparison
            var previousMeasurement = null
            var referenceTool = -1
            
            ; Search for a reference tool with non-zero offset
            ; Priority: 1) Probe tool, 2) Any other tool with offset
            if { tools[global.nxtProbeToolID].offsets[2] != 0 }
                ; Use probe tool offset with delta machine compensation
                set referenceTool = global.nxtProbeToolID
                if { global.nxtDeltaMachine != null }
                    ; Convert probe offset from reference surface to toolsetter coordinates
                    set previousMeasurement = { tools[global.nxtProbeToolID].offsets[2] - global.nxtDeltaMachine }
                else
                    abort {"tpost.g: nxtDeltaMachine not calibrated for touch probe system"}
            else
                ; Use any other tool's offset directly
                while { iterations < limits.tools && referenceTool == -1 }
                    if { tools[iterations].offsets[2] != 0 && iterations != state.currentTool }
                        set referenceTool = iterations
                        set previousMeasurement = tools[iterations].offsets[2]
                        
                if { previousMeasurement == null }
                    ; No reference measurement available - this is typically first tool after probe
                    echo "tpost.g: No reference measurement available, setting offset to 0"
                    set newOffset = 0.0
                else
                    ; Calculate the length difference between tools
                    var lengthDiff = { currentMeasurement - previousMeasurement }
                    
                    ; Apply the difference to get absolute offset
                    if { referenceTool == global.nxtProbeToolID }
                        ; Reference is probe tool, length diff is the absolute offset
                        set newOffset = var.lengthDiff
                    else
                        ; Reference is another cutting tool, add to previous offset
                        set newOffset = { global.nxtPreviousToolOffset + lengthDiff }
        else
            ; No previous tool offset - this is likely the first tool
            ; Set offset to 0 and let operator establish WCS
            set newOffset = 0.0
        
        ; Apply the calculated offset
        G10 P{state.currentTool} X0 Y0 Z{var.newOffset}
        
        echo "tpost.g: Tool T" ^ state.currentTool ^ " offset set to Z=" ^ var.newOffset
        
        ; Return to safe position
        G27 Z1
    else
        ; No toolsetter - manual tool length measurement required
        echo {"tpost.g: Manual tool measurement required (no toolsetter configured)"}
        ; Operator will need to manually set Z origin with G37.1 or similar

; Clear tool change state to indicate completion
set global.nxtToolChangeState = null

echo {"tpost.g: Tool change completed for T" ^ state.currentTool}