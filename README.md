# In Countless Shadows

*A playable-poetry research prototype based on Shakespeare's Sonnet 17.*

**Current status:** Experimental Godot desktop prototype. Mobile portrait layout, touch input, and iPhone/iPad distribution are planned, not yet implemented or verified.

## Project
The game explores poetic form as an interactive system: meter, rhyme, syntax, and rhetorical turns can be modeled as constraints, but a formally valid arrangement does not settle what a poem means.

**Working research question:** What happens to literary interpretation when poetic constraints are translated into computationally enforceable rules, and how do players negotiate the difference between formal solvability and interpretive ambiguity?

The research is not dependent on the game's commercial success. The prototype is intended both as an independent artwork and as an instrument for investigating what computational interaction reveals, excludes, or changes about literary reasoning.

## Current build
The Godot project currently has a title screen, level select, separate experiments in volta, rhyme, and meter, and a fourteen-line composition interface. These are exploratory scenes, not a settled mobile game design.

To run locally: open `project.godot` in a compatible Godot 4 editor and run the project. The current configuration targets a 1280 × 720 desktop viewport. Runtime and mobile exports have not been verified in this documentation update.

## Current priority
Prototype one satisfying, portrait-first touch puzzle with interacting formal constraints, clear undo/reset, and meaningful interpretive consequences. Observe how people play before extending the level sequence.

## Documentation
- [Design notes](design/notes.md): design principles, advisor feedback, experiments, and unresolved questions.
- [Working paper and abstract](research/paper.md): research question, provisional abstract, methodological direction, and writing status.
- [Annotated bibliography](research/bibliography.md): scholarly and design references with verification status.

## Mobile distribution plan
1. Confirm the existing Godot project runs without errors.
2. Convert one playable scene to portrait layout and touch-first controls.
3. Export a Godot web build and host it over HTTPS for testing in Safari on iPhone and iPad.
4. If needed later, use Godot's iOS export workflow with macOS, Xcode, signing, and device provisioning for a native build.

The web build is a planned workflow, not a currently available play link.
