# Prototype validation checklist

The web deployment workflow now runs all headless test scripts before export and reports exported file sizes. A green CI run verifies parsing, scene instantiation, and deterministic data checks, not actual browser rendering or iPad behavior.

## Run locally with Godot 4

From the project directory:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_poem_data.gd
godot --headless --path . --script res://tests/test_composition.gd
godot --headless --path . --script res://tests/test_puzzle_levels.gd
godot --headless --path . --script res://tests/test_scene_smoke.gd
godot --headless --path . --script res://tests/test_navigation.gd
```

If your executable is called `godot4`, substitute that name. The project currently declares Godot 4.7 features. An older Godot 4 release may not import it.

## Manual visual and interaction pass

- [ ] Turn introduction: Main menu button is visible and works without beginning.
- [ ] Every experiment: Main menu button works, including the whole-sonnet editor.
- [ ] iPad Safari: tap controls and menu navigation, test refresh and rotation.
- [ ] Inspect Actions build logs for exported .wasm/.pck file sizes and test results.

- [ ] Title: Begin opens The Turn, not the fourteen-line editor.
- [ ] Turn: select two passage cards to swap. Confirm feedback changes with arrangement.
- [ ] Turn: the order doubt, condition, answer unlocks Continue to rhyme.
- [ ] Turn: rearrange again after discovery. Continue stays available.
- [ ] Echo: choose two different line endings. Confirm `time/rhyme`, `eyes/lies`, and `age/rage` are recognized.
- [ ] Echo: an unsupported pair says the lexicon cannot establish the rhyme, not that the poem is bad.
- [ ] Echo: reverse a valid pair; the rhyme remains recognized but it is not called the original ordering.
- [ ] Echo: Continue opens The Measure.
- [ ] Measure: both reading choices display ten estimated syllable positions.
- [ ] Measure: tapping a bar changes its emphasis and departure count.
- [ ] Measure: visual pulse advances and stops. Switching readings resets the pattern.
- [ ] Measure: Continue opens the whole Sonnet 17 editor.
- [ ] Editor: confirm tile dragging, page navigation, reading view, save/load, undo/redo.
- [ ] Check typography at 1280 x 720 and at smaller window sizes; inspect clipped text and overlapping controls.

## Known limits

The headless scene test checks load/instantiation, not visual layout or successful clicking. Touch is currently translated into mouse events by Godot; this is not yet a complete gesture system. The three teaching scenes still use fixed 1280 x 720 drawing coordinates, and there is no cross-level session persistence. The full-sonnet editor retains its separate input and composition persistence behavior. The editor still uses fixed screen coordinates, and meter/rhyme data are provisional. Do not present its interpretations as scholarly validation.
