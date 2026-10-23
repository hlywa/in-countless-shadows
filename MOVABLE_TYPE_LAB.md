# Movable Type Lab

This is a separate Godot scene, `res://scenes/movable_type_lab.tscn`, so the existing Sonnet 17 scene and title screen remain unchanged.

## Try it
1. Fetch and check out branch `prototype/draggable-type` in GitHub Desktop.
2. Open `scenes/movable_type_lab.tscn` in Godot.
3. Use **Scene > Run Current Scene** (F6 or Fn+F6).
4. Drag the seven words from the tray into the printing forme. Drag a placed word to rearrange it, or drag it back outside the frame to remove it.
5. The forme has ten syllabic positions grouped into five abstract feet. A two-syllable word is a single tile occupying two positions.
6. Fill all positions and click **PRINT** to preserve an impression of the assembled line. **RESET TYPE** clears the arrangement. **HIDE GUIDE** toggles the abstract metrical guide.

## Scope and interpretive honesty
This is a **mechanical prototype**: dragging, insertion, occupancy, rearrangement, and printing. It is not yet a validated scansion puzzle. Ten occupied positions are necessary to print in this experiment, but this does not prove the arrangement is syntactically, metrically, or semantically defensible. The abstract weak/strong guide is a reference, not a stress assignment to each word. An original-order line is not enforced, so other arrangements can be explored. Next steps: manually authored contextual stress and syntactic constraints, more nuanced variation states, custom font loading, and a formal relationship that unlocks further actions.

All presentation is drawn in GDScript with no external art assets. The scene currently uses Godot's fallback font to ensure it runs even when the user's local font files have not been committed to GitHub.

**Testing:** This code was committed remotely and has not yet been run in a Godot editor. If the editor reports a parse error, preserve the error text and line number before making further changes.
