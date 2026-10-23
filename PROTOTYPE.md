# Letterpress prototype: Sonnet 17

This branch adds a self-contained Godot 4 scene, `sonnet_player.tscn`, with code-drawn paper, ink impressions, the full Sonnet 17 text, five-foot metrical marks, rhyme labels, a two-syllable `stretchèd` demonstration, undo, and reset.

## Try it in Godot

1. In GitHub Desktop, switch to `prototype/letterpress-sonnet-17` after fetching it. If Godot is open, let it import the new files.
2. In Godot, double-click `sonnet_player.tscn`.
3. Press **F6** (Run Current Scene). Do not press F5 unless you have configured a main scene.
4. Select lines, expose meter, show rhyme, and select line 12 to stretch the word.

The scene deliberately uses Godot's fallback font and no external image assets, so it can be tested immediately. Later, licensed font files can be added under `fonts/` and loaded in the script.

## Scope and limitations

This is a **visual and interaction spike**, not a solved puzzle. It does not yet model scansion, check metrical alignment, generate semantic readings, or make rhyme edges traversable. The stress display is an abstract iambic expectation, not a claim that every line scans identically. All text annotations and future formal relations should be hand-authored.

The original `main.tscn` and `project.godot` were not visible on remote `main` when this branch was created. This branch therefore does not replace or create those files. Preserve your local project and merge this branch only after checking your local changes.

The poem text here is an initial transcription. Verify punctuation and editorial choices against the edition you want to use before treating it as canonical.
