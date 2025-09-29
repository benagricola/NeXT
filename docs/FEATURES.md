# NeXT Feature Set

This document distills the requirements for the NeXT rewrite, categorizing features into Critical, Nice-to-Have, and To Be Cut. The focus is on simplicity, accuracy, and a streamlined user experience.

---

## 1. Guiding Principles

- [ ] **Simplicity & Accuracy:** The primary goal is to reduce complexity wherever possible. All implementation choices must prioritize accuracy, especially in probing and calculation-heavy operations.
- [ ] **Numerical Stability:** Algorithms used for calculations (e.g., probe compensation, geometric calculations) must be chosen to minimize floating-point error accumulation.
- [ ] **User Input and Warnings:** For actions requiring user confirmation or input, macros will use `M291` dialogs to ask for user input.
---

## 2. Critical Features

These features form the core of the new NeXT system and must be implemented for the system to be considered functional.

#### **Core System & Structure**
- [x] **Simplified Loading Mechanism:** Retain the `nxt.g` entrypoint and `nxt-boot.g` sanity-check structure, but simplify the internal logic.
- [x] **Global Variable System:** Keep the concept of using global variables for state management, loaded from `nxt-vars.g` and `nxt-user-vars.g`.
- [x] **Reorganized Macro Folders:** The `macro/` directory will be restructured by purpose (e.g., `macros/probing`, `macros/tooling`, `macros/spindle`) to improve clarity and maintainability.

#### **Probing Engine & Safety**
- [ ] **Single-Axis Probing Core:** A new, fundamental probing macro that *only* moves along a single specified axis (X, Y, Z, A, etc.) per command. All complex, multi-axis probe moves will be removed. In particular, this applies to Bore and Boss probes that previously would probe at 120 degree angles.
- [ ] **Probe Compensation:** The core probing macro will be responsible for applying compensation for:
    - [ ] **Probe Tip Radius:** Applied for all horizontal (X, Y, etc.) probing moves.
    - [ ] **Probe Deflection:** Applied for all probing moves, including Z. The Z-axis compensation will be handled to avoid applying the radius. We may need to track a separate probe deflection value for Z as opposed to X/Y because the probe behaviour may be different.
- [ ] **Probe Deflection Measurement:** A dedicated mechanism (UI component) to automatically measure probe deflection by probing a known-sized object. This will be part of the new UI-based configuration and not implemented in a macro.
- [ ] **Manual Deflection Input:** The UI will allow operators to manually enter their own pre-calculated deflection values.
- [ ] **Protected Moves:** A critical safety feature. If the touch probe is triggered unexpectedly during any non-probing move (e.g., jogging, travel moves), the movement must halt immediately and the running macro must be aborted.

#### **Probe Results Management**
- [ ] **Decoupled Probing:** Probing cycles will **no longer** directly set a Work Coordinate System (WCS) origin. Their sole purpose is to find a coordinate and record it.
- [ ] **Probe Results Table:** A new global variable (e.g., a vector) will be implemented to store a history of the last ~10 probe results. Each entry will record the axis/axes probed and the final, compensated coordinate(s).
- [ ] **UI for WCS Application & Result Manipulation:** A new UI panel will display the Probe Results Table. From this panel, the user can:
    - [ ] **Push to WCS:** Select a result row and apply its coordinates to a chosen WCS.
    - [ ] **Merge Results:** Select a result row, run a new probe cycle for a different axis, and have the new result populate the selected row.
    - [ ] **Overwrite Results:** If a new probe cycle's axis already exists in a selected row, the new value will overwrite the old one.
    - [ ] **Average Results:** Select one row, then click an "average" button on another row to merge them by averaging their respective axis coordinates.

#### **Probing Cycles**
- [ ] These will be re-implemented to log their results to the new Probe Results Table.
    - [ ] Bore (`G6500`) - Probe both sides of the bore in X and Y and find the centre point (4 probe points total)
    - [ ] Boss (`G6501`) - Probe both sides of the boss in X and Y and find the centre point (4 probe points total)
    - [ ] Rectangle Pocket (`G6502`) - Probe all 4 edges of the pocket in X and Y, and find the centre point (4 probe points total)
    - [ ] Rectangle Block (`G6503`) - Probe all 4 edges of the block in X and Y, and find the centre point (4 probe points total)
    - [ ] Web (X/Y) (`G6504`) - Probe a block (web) in either X OR Y, and find the centre point on that axis (2 probe points total)
    - [ ] Pocket (X/Y) (`G6505`) - Probe a pocket in either X OR Y, and find the centre point on that axis (2 probe points total)
    - [ ] Rotation (`G6506`) - Probe 2 points along a single surface in X or Y to find the rotation of that surface against the relevant axis (2 probe points total)
    - [ ] Outside Corner (`G6508`) - Probe each surface forming an assumed-90-degree outside corner, finding the intersection point of the two surfaces (2 probe points total)
    - [ ] **New:** Inside Corner (`G6509`) - Probe each surface forming an assumed-90-degree inside corner, finding the intersection point of the two surfaces (2 probe points total)
    - [ ] Single Surface (`G6510`) - Probe one surface in X, Y or Y, finding the location of the surface on the selected axis (1 probe point total)
    - [ ] Vise Corner (`G6520`) - Run a single surface Z probe to find the top of a vise corner, then run an outside corner probe to find the corner point in X and Y (3 probe points total)

#### **Tool Change Logic**
- [ ] **Probe-on-Removal:** Standard cutting tools will have their length measured by the toolsetter during the `tfree.g` (tool removal) phase.
- [ ] **Relative Offset Calculation:** Tool offsets will be calculated relative to the previously used tool during the tool change process, eliminating reliance on a persistent, absolute datum between machine runs.
- [ ] **Touch Probe Handling:** The touch probe is the exception. It will be measured against a reference surface upon installation (`tpost.g`) to establish its length relative to the toolsetter, ensuring accurate offsets for all subsequent tools.

#### **UI-Driven Workflow**
- [ ] **Persistent UI Screen:** A new primary screen/view in DWC dedicated to NeXT, containing always-visible widgets for core status and actions.
    - [ ] **Status Widget:** A persistent widget displaying: selected tool name, tool offset, machine state, selected WCS, and spindle state (direction, RPM).
    - [ ] **Action Confirmation Widget:** A persistent widget that replaces blocking `M291` dialogs. It will pause the job queue and display a confirmation request (e.g., "Start Spindle?") that the operator must interact with to resume the job.
- [ ] **UI-Based Configuration:** A new settings panel within the UI plugin will completely replace the `G8000` configuration wizard, allowing for non-serial, direct editing of all settings.
- [ ] **UI-Driven Probing:** All probing cycles will be initiated and configured through the DWC UI.

#### **Machine Control**
- [x] **Spindle Control:** Core macros for safe spindle start/stop with acceleration waits (`M3.9`, `M4.9`, `M5.9`).
- [x] **Coolant Control:** Core macros for coolant control (`M7`, `M8`, `M9`, and `M7.1`).
- [x] **Parking (`G27`):** A critical macro for moving the machine to a safe, known position.
- [x] **Safety Net (ATX Power Control):** The `M80.9`/`M81.9` system for safe, operator-confirmed ATX power control.

---

## 2. Nice-to-Have Features

These features add value but are not part of the initial core rewrite. They can be implemented in a later phase after the critical systems are stable.

- [ ] **Drilling Canned Cycles (`G73`, `G81`, `G83`):** Useful for manual operations, but not essential to the core OS. Can be re-implemented after the main rewrite.
- [ ] **Variable Spindle Speed Control (VSSC):** A valuable feature for improving surface finish, but its complexity is self-contained. It can be re-added as a modular component.
- [ ] **Spindle Feedback:** Use sensor input to detect when the spindle has reached target speed or stopped.

---

## 3. Features to Be Cut

These features and concepts from the old implementation will be explicitly removed to align with the goal of simplicity and to reduce complexity and potential sources of error.

- [ ] **Dialog-Driven Probing System:** The entire system of using `M291` dialogs to guide users through probing parameter selection will be removed in favor of the DWC UI.
- [ ] **Manual Probing (Jogging Dialogs):** The system of using repeated dialogs to manually jog the machine closer to a surface is obsolete. This will be replaced by standard jogging and a "Set Origin" button in the UI.
- [ ] **Multi-Axis Probing Moves:** The core probing logic will no longer support simultaneous movement in multiple axes during a single probe command. All probing will be strictly single-axis, so only a single target co-ordinate can be given to the underlying `G6512` macro.
- [ ] **G8000 Configuration Wizard:** The G-code based, serial configuration wizard will be entirely replaced by a more flexible and user-friendly UI-based settings panel.
- [ ] **Backwards Compatibility:** No code will be retained for the purpose of supporting RRF versions prior to 3.6.1 or for compatibility with the previous MillenniumOS implementation.