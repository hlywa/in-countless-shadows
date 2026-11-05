# Formal traversal experiment

This branch extends the existing letterpress Sonnet 17 spike without replacing the title screen or scene layout.

## What changed
- `scripts/poem_data.gd` contains hand-authored rhyme pairs, an abstract iambic template, and a syllable-aware annotation for `stretchèd`.
- `scripts/sonnet_player.gd` retains the existing hand-drawn interface and exposes an F-rhyme traversal **only after** the player stretches `stretchèd` on line 12.
- Traversing moves between line 12 (`song`) and line 10 (`tongue`), recording a visible textual shadow trace. Undo and reset restore the trace too.

## Try it
1. In Godot, open `scenes/sonnet_player.tscn`.
2. Run the current scene with F6.
3. Select line 12, then click **STRETCH TYPE**.
4. Click **TRAVERSE TO TONGUE / LINE 10**.
5. Observe the selected line and shadow trace. Traverse back, undo, or reset.

## Research and implementation limits
This is an intentionally small **interaction spike**, not a finished thinky puzzle. The stretch control is still a toggle, not direct manipulation; the metrical positions are an abstract expectation, not validated scansion; the route is one authored rhyme pair, not a complete traversal graph. The shadow is a textual trace, not a generated interpretation. No semantic correctness is scored.

The existing sonnet text should be checked against the chosen editorial edition before publication. Test the branch in Godot before merging. Local unsynced edits are not visible to GitHub and must be preserved separately.
