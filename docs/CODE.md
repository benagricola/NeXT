# NeXT Coding Style Guide

This document outlines the coding conventions and style guidelines to be followed in the NeXT rewrite. Consistent coding style ensures readability, maintainability, and reduces errors in the codebase.

---

## 1. General Principles

- **Readability First:** Code should be written to be easily understood by other developers. Prioritize clarity over brevity.
- **Consistency:** Follow the established patterns in this document. When in doubt, match the style of existing code.
- **Comments:** Use comments to explain complex logic, assumptions, or non-obvious behavior. Comments should be concise but informative.

---

## 2. Variable Naming

- **Global Variables:** All global variables must be prefixed with `nxt` to avoid conflicts with other plugins or user variables (e.g., `nxtDeltaMachine`).
- **Descriptive Names:** Use full, descriptive names instead of abbreviations (e.g., `nxtCoolantFloodID` instead of `nxtCFID`).
- **Case:** Use camelCase for variable names (e.g., `nxtProbeResults`).

---

## 3. Expression Handling 

- **Universal Requirement:** ALL expressions in RepRapFirmware meta G-code must be wrapped in curly braces `{}` to ensure proper parsing and prevent ambiguities.
- **This applies to:**
  - Conditional expressions in `if` statements
  - Variable assignments and operations
  - Command parameters with expressions
  - `echo` and `abort` statement arguments
  - Coordinate calculations

### Examples:

#### ✅ CORRECT - All expressions wrapped in curly braces:
```gcode
echo { "Current position: " ^ var.blah }
abort { "Error in macro: Invalid parameter" }
G0 X{var.x} Y{var.y}
var x = { 0 }
var y = { var.x + 1 }
set var.y = { var.x }
if { exists(param.S) && param.S > 0 }
```

#### ❌ INCORRECT - Missing curly braces:
```gcode
echo "Current position: " ^ var.blah
abort "Error in macro"
G0 X var.x Y var.y  
var x = 0
var y = var.x + 1
if exists(param.S) && param.S > 0
```

- **Dynamic Commands:** It is NOT possible in RRF to build a command string, and then execute it.
### Examples:

#### ✅ CORRECT:
```gcode
var x = {1}
var y = {2}
G0 X{var.x} Y{var.y}
```

#### ❌ INCORRECT - Command built from string:
```gcode
var x = {1}
var y = {2}
var gcode = {"G0 X" ^ var.x ^ " Y" ^ var.y}
{gcode}
```

---

## 4. G-code and M-code Conventions

- **Industry Standards:** Adhere to NIST standards for G-code numbering where possible.
- **Extensions:** For functionality not implemented by RepRapFirmware (RRF), use standard G-codes (e.g., `G37` for tool measurement).
- **Wrapper Macros:** To add safety or features to existing RRF commands (e.g., `M3`, `M5`), create "wrapper" macros with a decimal extension (e.g., `M3.9`, `M5.9`). These wrappers contain custom logic and then call the base RRF command.
- **Legacy Compatibility:** We must try not to implement custom M- or G-codes that use the same numbers as those used by legacy MillenniumOS, unless they implement roughly the same thing. Refer to `docs/DETAILS.md` for the complete list of legacy codes to avoid conflicts.
- **NO Named Macros:** **DO NOT** create named macro files (e.g., `measure-tool-length.g`, `probe-workpiece.g`) that require M98 calls to execute. These are unwieldy, ugly, and inconsistent with CNC conventions. Instead, always create proper G-code or M-code macros that can be called directly.
- **Post-Processor Configuration:** Ensure post-processors are configured to output these extended codes.
- **Parking:** When the machine needs to be in a 'safe' position for a subsequent move, it should be parked. This is important before tool changes, spindle start or stop, probing and tool length measurements. Use `G27 Z1` to park the machine in Z.
---

## 5. Macro Structure

- **File Naming:** Core system files should use the `nxt` prefix where appropriate (e.g., `nxt.g`, `nxt-vars.g`).
- **G-code/M-code Naming:** All user-callable macros must be named as G-codes or M-codes (e.g., `G37.g`, `M3000.g`, `M6515.g`) to be executed directly without M98 calls.
- **Descriptive Named Files:** Only use descriptive names (e.g., `probe-workpiece.g`) for internal system files that are never called directly by users or post-processors. These should only be called from other macros using M98.
- **UI Dialog Integration:** We will be using component injection to override the behaviour of M291 dialogs in the frontend. To our macro code, this will look exactly as M291 dialogs already do, so there is no need to change the way these work.
- **Error Handling:** Use `abort` for fatal errors with descriptive messages.
- **Validation:** Validate parameters early in macros to prevent runtime errors.

---

## 6. Comments and Documentation

- **Header Comments:** Each macro file should start with a comment describing its purpose, usage, and parameters.
- **Inline Comments:** Use inline comments for complex calculations or non-standard logic.
- **Variable Comments:** Comment global variable declarations with their purpose.

---

## 7. Best Practices

- **Avoid Magic Numbers:** Use named constants or variables instead of hard-coded numbers.
- **Modular Code:** Break down complex logic into smaller, reusable functions or macros.
- **Testing:** Write code with testing in mind; ensure macros can be tested independently.
- **Line Length:** Keep all lines under 250 characters. Do not split expressions across multiple lines.
- **Loop Iterations:** Use RRF's built-in `iterations` variable instead of creating custom counters.
- **Required Parameters:** Parameters that depend on workpiece dimensions (width, height, depth) must be required, not defaulted.
- **Variable Consistency:** Use consistent variable names for the same concepts across macros (e.g., `feedRate`, `retries`, `overtravel`).

---

## 8. Macro Naming Examples

### ✅ CORRECT - G-code/M-code Macros
- `G37.g` - Tool length measurement (called as `G37`)
- `M3000.g` - Operator dialog prompt (called as `M3000`)  
- `M6515.g` - Coordinate limit checking (called as `M6515`)
- `G6500.g` - Bore probing cycle (called as `G6500`)

### ❌ INCORRECT - Named Macros Requiring M98
- `measure-tool-length.g` - Requires `M98 P"measure-tool-length.g"`
- `probe-workpiece.g` - Requires `M98 P"probe-workpiece.g"`
- `check-limits.g` - Requires `M98 P"check-limits.g"`

### 🔧 Internal System Files (Acceptable Named Files)
- `nxt-boot.g` - System initialization, called once from config
- `nxt-vars.g` - Variable definitions, called from system files
- `display-startup-messages.g` - Internal helper, called only by other macros

---

## 9. Parameter Naming

- **Avoid Axis Letters:** Do not use common axis letters (e.g., `X`, `Y`, `Z`, `A`, `B`, `C`, `U`, `V`, `W`) for parameters that do not represent a coordinate in that axis.
- **Avoid Reserved Letters:** Do not use letters that correspond to G-code or M-code commands (e.g., `G`, `M`, `T`). The `P` parameter is also frequently used by RRF for various purposes and should be used with caution.
- **Clarity:** Choose parameter letters that are descriptive or conventional for their purpose (e.g., `I` for ID, `F` for speed (feed), `R` for retries, `J` for axis index). Document the purpose of each parameter in the macro's header comment.

### Parameter Validation and Iteration

- **No Direct Parameter Iteration:** You CANNOT iterate over the `param` object directly as it is not a vector. Instead, create a local vector with the relevant parameters first.
- **Parameter Checking Pattern:** Use the following pattern for checking multiple similar parameters:

```gcode
var axisParams = { param.X, param.Y, param.Z, param.A }
var selectedAxis = -1

while { iterations < #var.axisParams }
    if { var.axisParams[iterations] != null }
        if { var.selectedAxis != -1 }
            abort { "Only one axis parameter allowed" }
        set var.selectedAxis = { iterations }
```

---

## 10. Object Model Best Practices

- **Multi-Axis Checks:** When checking attributes on multiple axes via the object model (for example, to check if all axes are homed), use a loop rather than checking individual indexes. This ensures the code works correctly regardless of the number of configured axes.
- **Sparse Arrays:** Some object model areas can be 'sparse' - that is, some entries might be `null` with subsequent entries containing an object. A great example of this is the tool list, which might have tool 1 and 49 allocated but all of the other tools `null`. This must be taken into account with any loops that check an attribute of an object that might or might not be there.

### Examples:

#### ✅ CORRECT - Using loops for multi-axis checks:
```gcode
; Check if all axes are homed
while { iterations < #move.axes }
    if { !move.axes[iterations].homed }
        abort { "Axis " ^ move.axes[iterations].letter ^ " is not homed. Please home all axes before continuing." }
```

#### ✅ CORRECT - Handling sparse arrays (checking for null):
```gcode
; Check all tools for a specific condition
while { iterations < #tools }
    if { tools[iterations] != null && tools[iterations].offsets[0] > 10 }
        echo "Tool " ^ iterations ^ " has X offset > 10mm"
```

#### ❌ INCORRECT - Checking individual indexes:
```gcode
; Don't do this - assumes specific number of axes
if { !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed }
    abort { "Not all axes are homed" }
```

---

## 11. Documentation and File Organization

- **Documentation Location Requirement:** All documentation MUST be placed in the `docs/` folder. Do not create documentation files (README.md, etc.) outside of the documentation folder.
- **No README Files in NeXT Structure:** Do not create README files within the NeXT structure itself (e.g., in `ui/`, `macros/`, etc.). Component documentation is fine, but it needs to go in the `docs/` folder.
- **Preserve Legacy Documentation:** Be careful not to overwrite or delete any documentation that explains how the legacy MillenniumOS system worked.

---

## 12. Variable Usage Best Practices

- **Avoid Redundant Assignments:** Do not create local variables that simply reference other data sources without transformation. Use the original source directly instead of creating unnecessary local assignments.

Examples:
```gcode
; INCORRECT - Unnecessary local variable assignments
var spacing = { var.probeSpacing }
var resultIndex = { param.P }
var currentTool = { global.nxtCurrentTool }

; CORRECT - Use original sources directly
set var.firstPos = { var.currentPos + var.probeSpacing }
set global.nxtProbeResults[param.P][0] = { var.centerX }
echo { "Current tool: " ^ global.nxtCurrentTool }
while { iterations < #move.axes }

; ACCEPTABLE - Preserving value at specific execution point
var axisCount = { #move.axes }  ; Store count before operations that might change it
; ... operations that might affect move.axes ...
while { iterations < var.axisCount }  ; Use preserved count
```

**Exception:** Create local variables only when:
- The source value needs modification (e.g., incrementing, calculations)
- The object model path is very long and helps stay under the 250 character line limit
- You need to preserve a value at a specific point in execution for later use when the source value may change

---

## 13. Probing System Standards

### Required Parameters
- **Workpiece Dimensions:** All probing cycles require explicit workpiece dimensions (W, H, L, D parameters)
- **Result Index:** All probing cycles require P parameter specifying exact result table index (0-based)
- **No Default Dimensions:** Never provide defaults for workpiece-dependent parameters

### Standard Defaults
- **Overtravel (O):** 2.0mm - safe touch probe contact distance
- **Clearance (C):** 10.0mm - sufficient starting distance for accuracy  
- **Feed Rate (F):** null - uses probe-specific speeds

### Result Management
- UI controls result table indexing via mandatory P parameter
- Probing cycles write to specified index, overwriting existing data
- Enables multi-stage probing: X/Y → Z → rotation on same result row

Example:
```gcode
; UI specifies result index 0
G6500 P0 D25.4 L10.2  ; Bore probe writes to index 0
G6510 P0 Z-15.0       ; Z probe adds Z data to same index 0
G6506 P0 N0 D1 S20.0  ; Rotation adds angle to same index 0
```

---

## 14. Common Pitfalls

This section documents bugs that have occurred in the NeXT codebase and the rules to prevent them. Every item here reflects a real mistake that was found during code audit.

### 14.1 Global Variable Lifecycle

A global variable must be **declared once** with `global` and **updated** with `set global.`:

```gcode
; In nxt-vars.g (declaration - runs once at boot):
global nxtMyVar = { null }

; In any other macro (assignment):
set global.nxtMyVar = { 42 }
```

#### ❌ Common mistake: Re-declaring a global that already exists
```gcode
; This will ERROR with "variable already exists" if nxtMyVar was declared in nxt-vars.g
global nxtMyVar = 42
```

#### ❌ Common mistake: Using `set` on a global that was never declared
```gcode
; This will ERROR with "unknown variable" if nxtMyVar was never created with `global`
set global.nxtMyVar = { 42 }
```

**Rule:** Every global variable used anywhere in the codebase MUST have a `global` declaration in `nxt-vars.g`. Any macro that changes its value MUST use `set global.<name> = { value }`.

### 14.2 CNC Mode and Parentheses

NeXT runs in CNC mode (`M453`). In CNC mode, **parentheses `()` outside of `{}` are treated as comments**, not subexpressions. This affects meta commands (`if`, `while`, `echo`, `var`, `set`, `abort`) when they contain function calls or grouped subexpressions.

#### ❌ WRONG - parentheses treated as comment in CNC mode:
```gcode
while (iterations < #spindles) && !var.doWait
; RRF sees: while   && !var.doWait  → syntax error

if exists(param.S) && param.S > 0
; RRF sees: if exists  → incomplete expression
```

#### ✅ CORRECT - wrap in `{}` so parentheses work as subexpressions:
```gcode
while { iterations < #spindles && !var.doWait }
if { exists(param.S) && param.S > 0 }
```

**Rule:** Always wrap meta command expressions in `{}`. This is also required for consistency (Section 3), but in CNC mode it is functionally required whenever `()` appear.

### 14.3 The `^` Operator is String Concatenation, Not Exponentiation

RRF's `^` operator concatenates strings. It does NOT raise to a power. Use `square()` for squaring, or `pow()` for arbitrary exponents, or simply multiply `var.x * var.x`.

#### ❌ WRONG:
```gcode
var magnitude = { sqrt(var.deltaX^2 + var.deltaY^2) }
; This concatenates var.deltaX with the string "2", then tries to add strings
```

#### ✅ CORRECT:
```gcode
var magnitude = { sqrt(square(var.deltaX) + square(var.deltaY)) }
; Or: { sqrt(var.deltaX * var.deltaX + var.deltaY * var.deltaY) }
```

### 14.4 Probing Macros Must Pass Probe ID to G6512

`G6512` (single-axis probing) requires the `I` parameter specifying which probe sensor to use. It will abort without it. Every call to `G6512` from a probing macro must include `I{global.nxtTouchProbeID}` (or `I{global.nxtToolSetterID}` for tool measurement).

#### ❌ WRONG:
```gcode
G6512 X{var.target} Y{var.centerY} Z{var.probeZ} F{var.feedRate} R{var.retries}
```

#### ✅ CORRECT:
```gcode
G6512 X{var.target} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
```

### 14.5 Variable Scope — No Duplicate `var` Declarations

In RRF, `var` creates a new variable and errors if the name already exists in the current scope. You cannot re-declare a variable to change its value — use `set` instead.

#### ❌ WRONG - redeclares in the same if-block:
```gcode
if { var.axis == 0 }
    var firstY = { var.centerY - var.halfSpacing }
    ; ... probing happens ...
    var firstY = { global.nxtLastProbeResult }   ; ERROR: "variable already exists"
```

#### ✅ CORRECT - use `set` to update:
```gcode
if { var.axis == 0 }
    var firstY = { var.centerY - var.halfSpacing }
    ; ... probing happens ...
    set var.firstY = { global.nxtLastProbeResult }
```

### 14.6 Deflection and Tip Radius Compensation Must Account for Direction

When compensating probe results for deflection or tip radius, the sign depends on the probe direction. Probing in the positive direction overshoots positive (subtract to compensate); probing in the negative direction overshoots negative (add to compensate).

#### ❌ WRONG - always subtracts:
```gcode
var compensated = { var.triggeredPos * 1000 - var.probeDeflectionUm }
```

#### ✅ CORRECT - scales by direction:
```gcode
var direction = { var.target > var.start ? 1 : -1 }
var compensated = { var.triggeredPos * 1000 - (var.probeDeflectionUm * var.direction) }
```

### 14.7 Comparing Vectors vs Scalars

When you copy a vector (array) into a variable, comparing that variable against a scalar will fail. Always index into the vector to get a single axis value.

#### ❌ WRONG - compares array to float:
```gcode
var startPos = { global.nxtAbsPos }
var direction = { var.target > var.startPos ? 1 : -1 }
```

#### ✅ CORRECT - index into the array:
```gcode
var startPos = { global.nxtAbsPos }
var direction = { var.target > var.startPos[var.axisIndex] ? 1 : -1 }
```

### 14.8 Named Constants and Common Functions

RRF provides these named constants — use them, do not redefine them:
- `true`, `false`, `null`, `pi`, `iterations`, `result`, `line`, `input`

Useful math functions (check RRF version for availability):
- `abs()`, `min()`, `max()`, `sqrt()`, `square()` (3.6+), `pow()` (3.5+), `round()` (3.6+)
- `sin()`, `cos()`, `tan()`, `asin()`, `acos()`, `atan()`, `atan2()`
- `degrees()`, `radians()` — prefer these over manual `* 180 / pi` conversion
- `ceil()`, `floor()`, `mod()`
- `vector(count, value)` — create arrays
- `exists(name)` — returns true if name is defined **and not null**