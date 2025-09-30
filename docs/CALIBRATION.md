# NeXT Machine Calibration Guide

This document describes the resilient steps-per-mm calibration system for NeXT, designed to eliminate the circular dependency between steps-per-mm accuracy, backlash compensation, and touch probe deflection measurement.

---

## 1. The Calibration Challenge

When setting up a CNC machine, three measurement errors can affect machine accuracy:

1. **Steps-per-mm** - The fundamental relationship between motor steps and actual distance traveled
2. **Backlash** - Mechanical slack that causes position error when changing direction
3. **Touch Probe Deflection** - The distance the probe tip moves before triggering

These three error sources create a circular dependency problem:

- **Touch probe deflection** cannot be accurately measured unless steps-per-mm are correct and backlash is compensated
- **Backlash** cannot be accurately measured unless steps-per-mm and probe deflection are correct
- **Steps-per-mm** can be calibrated manually, but doing it with automated touch probe measurements requires accurate backlash compensation and probe deflection

This creates a "chicken and egg" problem where each measurement depends on the others being accurate.

---

## 2. Theoretical Foundation

### 2.1 Understanding Each Error Source

#### Steps-per-mm Error
- **Cause**: Incorrect firmware configuration, mechanical tolerances in drive components
- **Effect**: Machine moves wrong distance when commanded (e.g., commanded 100mm, actually moves 99.8mm or 100.2mm)
- **Characteristics**: Proportional error - larger moves have larger absolute errors

#### Backlash Error
- **Cause**: Mechanical slack in couplings, lead screws, ball screws, or linear guides
- **Effect**: Position error when changing direction, until slack is "taken up"
- **Characteristics**: Fixed magnitude per axis, independent of move distance

#### Probe Deflection Error
- **Cause**: Physical deflection of probe tip and stylus before electrical trigger
- **Effect**: Probe appears to trigger before/after actual contact point
- **Characteristics**: 
  - Generally consistent magnitude for similar approach speeds
  - May vary slightly based on probe angle and surface material
  - Opposite when probing from opposite directions (deflects away from surface)

### 2.2 Key Insight: Symmetry Cancellation

The solution lies in exploiting the **symmetrical nature** of probe deflection and the **directional consistency** of backlash-compensated moves:

1. **Probe deflection is symmetrical**: When probing opposite sides of an object:
   - From negative direction (e.g., X-): probe deflects in +X before triggering
   - From positive direction (e.g., X+): probe deflects in -X before triggering
   - The measured distance includes deflection on BOTH sides
   - For a known-size object, the measured size = actual size + 2 × deflection

2. **Backlash can be eliminated directionally**: By always approaching from the same direction:
   - Move far enough past the probe point to take up all slack
   - Return from that direction to the measurement position
   - All measurements are now in a "slack-taken-up" state

3. **Steps-per-mm error is proportional**: The error scales with distance:
   - If steps-per-mm is 1% high, a 100mm move travels 101mm
   - A 50mm object will measure as 50.5mm (assuming perfect probe and no backlash)
   - The ratio (measured/actual) reveals the steps-per-mm error

---

## 3. Calibration Procedure

### 3.1 Prerequisites

**Required Equipment:**
- Touch probe (configured in NeXT)
- Precision reference object with known dimensions:
  - **Recommended**: 1-2-3 block (1" × 2" × 3" = 25.4mm × 50.8mm × 76.2mm)
  - **Alternative**: Any precision ground rectangular block with known dimensions
  - **Minimum requirement**: Known dimensions accurate to ±0.01mm or better

**Initial State:**
- Machine must be mechanically assembled and motion system functional
- RRF firmware installed and basic axis configuration completed
- Approximate steps-per-mm values entered in firmware (even if incorrect)
- NeXT system loaded
- Touch probe configured (ID, tip radius estimated, deflection can be zero initially)

### 3.2 Procedure Overview

The calibration follows a specific sequence to break the circular dependency:

```
Phase 1: Rough Steps-per-mm Calibration (Manual)
         ↓
Phase 2: Backlash Measurement & Compensation
         ↓
Phase 3: Precise Steps-per-mm Calibration (Automated)
         ↓
Phase 4: Probe Deflection Measurement
         ↓
Phase 5: Verification & Refinement
```

### 3.3 Phase 1: Rough Steps-per-mm Calibration (Manual)

**Goal**: Get steps-per-mm accurate to within ~1-2% using manual measurement.

**Procedure**:
1. Home the machine
2. Jog to a known position and zero the work coordinate system (WCS)
3. Command a large move (e.g., 100mm) in X axis: `G0 X100`
4. Using calipers or dial indicator, measure the *actual* distance traveled
5. Calculate corrected steps-per-mm:
   ```
   new_steps = current_steps × (commanded_distance / actual_distance)
   ```
6. Update firmware configuration (M92 command in config.g)
7. Restart firmware or reload configuration
8. Repeat for Y, Z, and any other axes
9. Verify: commanding 100mm should now result in 99-101mm actual movement

**Why This Works**:
- Manual measurement doesn't depend on probe deflection or backlash
- Gets steps-per-mm "close enough" for automated methods to work
- 1-2% accuracy is sufficient for the next phases

### 3.4 Phase 2: Backlash Measurement & Compensation

**Goal**: Measure and compensate for mechanical backlash on each axis.

**Concept**:
With approximately correct steps-per-mm, we can now measure backlash using the touch probe. The key is to probe the same surface from opposite directions and measure the position difference.

**Procedure for Each Axis (Example: X-axis)**:

1. **Setup**:
   - Install touch probe (T{nxtProbeToolID})
   - Secure reference block on machine table
   - Jog probe to approximately 10-20mm from one surface of the block

2. **First Probe (Approach from Negative)**:
   - Move to starting position well beyond the surface (ensure backlash is taken up)
   - Command: `G6512 X{surface_position} I{nxtTouchProbeID}`
   - Record result: `pos1 = nxtLastProbeResult`

3. **Second Probe (Approach from Positive)**:
   - Move well past the surface in the positive direction (at least 10mm beyond pos1)
   - Command: `G6512 X{surface_position} I{nxtTouchProbeID}` (same target)
   - Record result: `pos2 = nxtLastProbeResult`

4. **Calculate Backlash**:
   ```
   backlash = abs(pos2 - pos1)
   ```
   
5. **Apply Compensation**:
   - In RRF firmware, use M425 to configure backlash compensation
   - Example: `M425 X{backlash} Y{backlash_y} Z{backlash_z}`
   - Add this to config.g for persistence

6. **Verify**:
   - Repeat the probe from opposite directions
   - Results should now be within 0.01mm of each other

**Note**: This measurement includes the effect of probe deflection (2× deflection magnitude), but for backlash compensation we only care about the total positional difference, which is the backlash amount.

### 3.5 Phase 3: Precise Steps-per-mm Calibration (Automated)

**Goal**: Achieve high-precision steps-per-mm calibration using automated touch probe measurements.

**Concept**:
With backlash now compensated, we can probe opposite sides of a known-dimension object. The measured distance will include probe deflection on both sides, but the *ratio* of measured to actual dimension reveals the steps-per-mm error, independent of deflection.

**Mathematical Proof**:
Let:
- `d_actual` = actual dimension of reference object
- `d_measured` = measured dimension from probe
- `δ` = probe deflection (same magnitude on both sides)
- `s_current` = current steps-per-mm setting
- `s_actual` = actual steps-per-mm (what we need to find)

When steps-per-mm is incorrect:
```
d_measured = (s_current / s_actual) × d_actual + 2δ
```

But we can eliminate δ by comparing two different dimensions:
```
d1_measured = (s_current / s_actual) × d1_actual + 2δ
d2_measured = (s_current / s_actual) × d2_actual + 2δ

Subtracting:
d2_measured - d1_measured = (s_current / s_actual) × (d2_actual - d1_actual)

Therefore:
s_actual = s_current × (d2_actual - d1_actual) / (d2_measured - d1_measured)
```

The deflection term cancels out!

**Procedure for Each Axis (Example: X-axis with 1-2-3 block)**:

1. **Setup**:
   - Install touch probe
   - Secure 1-2-3 block on machine table with known dimension oriented along X-axis
   - For X-axis: use the 1" (25.4mm) and 2" (50.8mm) dimensions

2. **Measure First Dimension (25.4mm side)**:
   - Position probe above the center of the narrow side
   - Probe left surface: `G6512 X{left_target} I{nxtTouchProbeID}`
   - Record: `left1 = nxtLastProbeResult`
   - Move probe across the block
   - Probe right surface: `G6512 X{right_target} I{nxtTouchProbeID}`
   - Record: `right1 = nxtLastProbeResult`
   - Calculate: `measured1 = abs(right1 - left1)`

3. **Measure Second Dimension (50.8mm side)**:
   - Rotate block or reposition to measure the 50.8mm dimension
   - Probe left surface: `G6512 X{left_target} I{nxtTouchProbeID}`
   - Record: `left2 = nxtLastProbeResult`
   - Probe right surface: `G6512 X{right_target} I{nxtTouchProbeID}`
   - Record: `right2 = nxtLastProbeResult`
   - Calculate: `measured2 = abs(right2 - left2)`

4. **Calculate Corrected Steps-per-mm**:
   ```
   actual1 = 25.4  ; mm
   actual2 = 50.8  ; mm
   s_new = s_current × (actual2 - actual1) / (measured2 - measured1)
   ```
   
5. **Apply Correction**:
   - Update firmware: `M92 X{s_new}`
   - Add to config.g for persistence
   - Restart or reload configuration

6. **Verify**:
   - Re-measure both dimensions
   - Both should now read within ±0.02mm of actual dimensions

**Repeat for Y and Z axes** using the appropriate dimensions of the reference block.

**Alternative Single-Dimension Method**:
If probe deflection has already been measured accurately, a single dimension can be used:
```
s_new = s_current × d_actual / (d_measured - 2δ)
```
However, the two-dimension method is more robust as it doesn't require knowing deflection.

### 3.6 Phase 4: Probe Deflection Measurement

**Goal**: Accurately measure touch probe deflection now that steps-per-mm and backlash are correct.

**Procedure for Each Axis (Example: X-axis)**:

1. **Setup**:
   - Install touch probe
   - Secure reference block with known dimension along X-axis (e.g., 25.4mm)

2. **Measure Dimension**:
   - Probe left surface: `G6512 X{left_target} I{nxtTouchProbeID}`
   - Record: `left = nxtLastProbeResult`
   - Probe right surface: `G6512 X{right_target} I{nxtTouchProbeID}`
   - Record: `right = nxtLastProbeResult`
   - Calculate: `measured = abs(right - left)`

3. **Calculate Deflection**:
   ```
   total_error = measured - actual_dimension
   deflection = total_error / 2
   ```
   
   Example:
   ```
   measured = 25.45mm
   actual = 25.40mm
   deflection = (25.45 - 25.40) / 2 = 0.025mm
   ```

4. **Update NeXT Configuration**:
   - Set `global.nxtProbeDeflection = {calculated_deflection}`
   - Add to nxt-user-vars.g for persistence

5. **Verify**:
   - Re-measure the reference dimension
   - The probing macro (G6512) will now apply deflection compensation
   - Result should be within ±0.01mm of actual dimension

**Repeat for Y and Z axes**. Note that deflection may differ between axes due to probe geometry and mounting.

### 3.7 Phase 5: Verification & Refinement

**Goal**: Verify all calibrations are working together correctly.

**Procedure**:

1. **Dimensional Verification**:
   - Measure multiple features on the reference block using probing cycles
   - All measurements should be within ±0.02mm of actual dimensions
   - Test different feature sizes to verify proportional accuracy

2. **Backlash Verification**:
   - Probe the same surface from opposite directions multiple times
   - Position difference should be < 0.01mm
   - If larger, backlash compensation may need adjustment

3. **Repeatability Test**:
   - Probe the same feature 10 times without moving the part
   - Calculate standard deviation of measurements
   - Should be < 0.005mm for a good setup

4. **Directional Test**:
   - Probe surfaces from both positive and negative approach directions
   - Measurements should be consistent within ±0.01mm
   - Verifies both backlash compensation and deflection compensation

5. **Real-World Verification**:
   - Create a simple test part with known dimensions (e.g., rectangular pocket)
   - Machine the part and measure with calibrated touch probe
   - Measurement should match CAD dimensions within machine capability

**Refinement**:
If verification reveals errors:
- **Proportional errors**: Revisit steps-per-mm calibration
- **Directional inconsistency**: Check backlash compensation
- **Fixed offset on all measurements**: Verify probe deflection value
- **Large scatter in repeated measurements**: Check mechanical issues (loose probe, spindle runout, etc.)

---

## 4. Implementation in NeXT

### 4.1 Implementation Approach

Two implementation approaches are possible:

#### Option A: UI-Based Calibration Wizard (Recommended)
- **Advantages**:
  - User-friendly step-by-step workflow
  - Visual feedback and progress indication
  - Can show real-time measurements and calculations
  - Easier to guide user through complex procedure
  - Can validate measurements and provide warnings

- **Implementation**:
  - Add calibration wizard to Settings panel in UI
  - UI guides user through each phase with instructions
  - UI sends probe commands and receives results
  - Calculations performed in UI JavaScript
  - Final values written to nxt-user-vars.g via M-code

#### Option B: G-code Macro Based (Alternative)
- **Advantages**:
  - Works without UI
  - Self-contained in macro system
  - Can be triggered from any G-code sender

- **Implementation**:
  - Create G-code macro (e.g., G6599 or M9000)
  - Uses M291 dialogs for user interaction
  - Prompts for reference block dimensions
  - Executes probe commands and calculations
  - Updates nxt-user-vars.g with results

### 4.2 Recommended Workflow Integration

**In Configuration/Settings UI:**

1. **Calibration Section**:
   - Button: "Run Machine Calibration"
   - Displays current calibration status (steps-per-mm, backlash, deflection values)
   - Shows last calibration date

2. **Calibration Wizard Flow**:
   ```
   Step 1: Welcome & Prerequisites Check
            - Verify machine is homed
            - Verify touch probe is configured
            - Prompt for reference block dimensions
            
   Step 2: Rough Steps-per-mm (Manual)
            - Instructions for manual measurement
            - Input fields for measured distances
            - Calculate and apply corrections
            
   Step 3: Backlash Measurement
            - For each axis:
              * Auto-probe from both directions
              * Calculate backlash
              * Apply M425 compensation
              
   Step 4: Precise Steps-per-mm (Automated)
            - For each axis:
              * Probe two different dimensions
              * Calculate correction
              * Apply M92 adjustment
              
   Step 5: Probe Deflection
            - For each axis:
              * Probe known dimension
              * Calculate deflection
              * Update nxtProbeDeflection
              
   Step 6: Verification & Report
            - Run verification tests
            - Display results and accuracy metrics
            - Save calibration data
   ```

3. **Calibration Results Storage**:
   - Store in nxt-user-vars.g:
     ```gcode
     ; Machine Calibration Data
     ; Last calibrated: 2024-01-15 14:32:00
     
     ; Steps per mm
     M92 X100.234 Y99.876 Z400.123
     
     ; Backlash compensation
     M425 X0.05 Y0.08 Z0.02
     
     ; Probe deflection (mm)
     global nxtProbeDeflection = 0.025
     ```

### 4.3 API Requirements

**Backend Macros Needed**:
- Existing `G6512` (single-axis probe) - already implemented ✓
- Existing `M5000` (machine position query) - already implemented ✓
- New: `M9001` - Query current steps-per-mm values
- New: `M9002` - Query current backlash compensation values
- New: `M9003` - Update steps-per-mm values temporarily (for testing before persistence)
- New: `M9004` - Update backlash compensation temporarily

**UI Integration Points**:
- Read current calibration values from object model
- Execute probe commands via G-code
- Update firmware parameters via M-codes
- Write results to nxt-user-vars.g file

### 4.4 Error Handling

**Common Issues & Solutions**:

1. **Probe Fails to Trigger**:
   - Check probe mounting and electrical connection
   - Verify probe ID is correct in configuration
   - Ensure target position is beyond the expected surface

2. **Measurements Inconsistent**:
   - Check mechanical rigidity (loose parts, worn bearings)
   - Verify reference block is properly secured
   - Ensure work surface is clean and free of debris
   - Check for spindle/probe holder runout

3. **Calculated Values Unreasonable**:
   - Verify reference block dimensions entered correctly
   - Check that probe is approaching from correct directions
   - Ensure machine is homed properly before starting

4. **Compensation Makes Things Worse**:
   - May indicate mechanical problems (binding, friction)
   - Steps-per-mm may be drastically wrong (>5% error)
   - Recommend manual verification before accepting values

**Safety Checks**:
- Limit maximum adjustment per iteration (e.g., ±5% steps-per-mm change)
- Require operator confirmation before applying changes
- Store backup of previous values
- Provide rollback option if results are poor

---

## 5. Expected Accuracy

With proper calibration following this procedure, the machine should achieve:

- **Steps-per-mm accuracy**: < 0.1% (±0.1mm per 100mm of travel)
- **Backlash compensation**: < 0.01mm residual error
- **Probe deflection compensation**: < 0.01mm residual error
- **Overall probing accuracy**: ±0.02mm for features > 10mm
- **Repeatability**: < 0.005mm standard deviation

These accuracies assume:
- Reasonable mechanical quality (hobby CNC or better)
- Proper machine assembly and tramming
- Quality touch probe (±0.01mm repeatability)
- Precision reference block (±0.01mm tolerance)

---

## 6. Roadmap Integration

This calibration system should be implemented in **Phase 4** of the NeXT development roadmap.

**Justification**:
- Requires stable probing engine (Phase 1) ✓
- Requires UI framework for wizard (Phase 2)
- Benefits from probe results management (Phase 3)
- Enhances overall system accuracy for advanced features

**Phase 4 Addition**:
```markdown
## Phase 4: Tool Change & Advanced Features

...existing items...

4. **Machine Calibration System:**
   * Implement UI-based calibration wizard in Settings panel
   * Create M-code macros for querying and updating calibration parameters
   * Implement automated steps-per-mm calibration using dual-dimension method
   * Implement automated backlash measurement and compensation
   * Implement automated probe deflection measurement
   * Add calibration verification and reporting
   * Document calibration procedure and best practices
```

---

## 7. References

### Related Documentation
- `docs/CODE.md` - NeXT coding standards and conventions
- `docs/FEATURES.md` - Feature requirements and implementation status
- `docs/ROADMAP.md` - Development phases and timeline
- `GCODE.md` - Custom G-code and M-code reference

### RRF Firmware Commands
- `M92` - Set steps per mm
- `M425` - Backlash compensation
- `G38.2` - Probe toward workpiece (used by G6512)
- Object Model: `move.axes[].stepsPerMm` - Query current settings

### External Resources
- RepRapFirmware Object Model Documentation
- Touch Probe Selection and Setup Guide
- CNC Machine Tramming and Alignment Procedures

---

## Appendix A: Quick Reference

### Calibration Sequence Summary
```
1. Manual rough steps-per-mm → Get within 1-2%
2. Probe backlash → Measure & compensate
3. Automated precise steps-per-mm → Use dual-dimension method
4. Probe deflection → Measure with known object
5. Verify → Test accuracy and repeatability
```

### Key Formulas

**Steps-per-mm Correction (Manual)**:
```
new_steps = current_steps × (commanded / actual_measured)
```

**Steps-per-mm Correction (Automated)**:
```
new_steps = current_steps × (d2_actual - d1_actual) / (d2_measured - d1_measured)
```

**Probe Deflection**:
```
deflection = (measured_dimension - actual_dimension) / 2
```

**Backlash**:
```
backlash = abs(probe_result_positive - probe_result_negative)
```

### Reference Block Dimensions (1-2-3 Block)
- Side 1: 1 inch = 25.4 mm
- Side 2: 2 inches = 50.8 mm  
- Side 3: 3 inches = 76.2 mm
- Typical tolerance: ±0.0002 inches (±0.005 mm) or better

---

*Last Updated: 2024-01-15*
*Document Version: 1.0*
