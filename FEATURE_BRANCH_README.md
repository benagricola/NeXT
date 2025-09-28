# Feature Branch: Probe Compensation Macros

This branch contains commit `8756f3df731a599cd9a51e6f9c7cf82b3c3c49c6` that was extracted from the main branch during the repository history cleanup.

## Original Commit Details
- **Author**: Ben Agricola <ben+git@agrico.la>
- **Date**: Sat Sep 27 17:56:14 2025 +0100
- **Message**: feat: Add probe compensation variables and core single-axis probing macro

## Changes in This Commit
- Added nxtProbeTipRadius and nxtProbeDeflection variables to nxt-vars.g
- Implemented G37.g: Single-axis probing macro with tip radius and deflection compensation
- Macro validates probe configuration and applies numerical compensations
- Stores compensated result in nxtLastProbeResult global variable
- Reimplement single-axis probing system with G6512.g
- Added M5000.g to get current machine position
- Added M6515.g to check machine limits

## Review Notes
This commit needs to be reviewed and adapted to work with the new NeXT directory structure before it can be merged back into main. The directory structure has changed since this commit was created:

- `macros/utilities/` → may need to be moved to appropriate NeXT directories
- File conflicts with current structure need to be resolved
- Variable naming should follow NeXT conventions (nxt* prefix)

## Next Steps
1. Review the functionality provided by this commit
2. Adapt the code to work with the current NeXT structure
3. Resolve any conflicts with existing macros
4. Test the functionality
5. Create a proper PR to merge back into main