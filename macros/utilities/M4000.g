; M4000.g: CREATE TOOL WITH NAME AND RADIUS
;
; Creates or updates a tool with specified name and radius.
; This provides operator-friendly tool identification during tool changes.
;
; USAGE: M4000 T<tool> S"<name>" R<radius>
;
; Parameters:
;   T<tool>:   Tool number to create/update
;   S<name>:   Tool name/description (quoted string)
;   R<radius>: Tool radius in mm
;
; Example: M4000 T1 S"6mm End Mill" R3.0

; Validate tool number parameter
if { !exists(param.T) || param.T < 0 || param.T >= limits.tools }
    abort {"M4000: Invalid tool number T" ^ param.T ^ " (valid range: 0-" ^ (limits.tools-1) ^ ")"}

; Validate name parameter
if { !exists(param.S) || param.S == null || param.S == "" }
    abort "M4000: Tool name S parameter required (quoted string)"

; Validate radius parameter
if { !exists(param.R) || param.R == null || param.R < 0 }
    abort "M4000: Tool radius R parameter required (positive value in mm)"

; Create the tool using RRF's M563 command
; This ensures the tool exists in the system
M563 P{param.T} S{"Tool " ^ param.T} ; Create tool if it doesn't exist

; Set tool name (description)
; Note: RRF doesn't directly support tool names in object model
; We'll store this in a global array for our system to use
if { !exists(global.nxtToolNames) }
    global nxtToolNames = vector(limits.tools, "")
if { !exists(global.nxtToolRadii) }
    global nxtToolRadii = vector(limits.tools, 0.0)

set global.nxtToolNames[param.T] = param.S
set global.nxtToolRadii[param.T] = param.R

echo {"M4000: Created tool T" ^ param.T ^ " - " ^ param.S ^ " (R" ^ param.R ^ "mm)"}