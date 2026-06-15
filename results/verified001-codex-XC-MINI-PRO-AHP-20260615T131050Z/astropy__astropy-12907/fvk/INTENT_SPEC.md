# Intent Spec

This file records public intent before accepting candidate implementation
behavior as expected behavior.

1. `separability_matrix` returns a boolean matrix describing which model outputs
   depend on which model inputs.
2. For independent 1D models combined with `&`, the dependency matrix is
   diagonal.
3. For a nonseparable left 2D projection combined with independent 1D models,
   the left projection may remain internally coupled, but the later independent
   models remain independent of each other and of the projection inputs.
4. Nesting an already constructed `&` compound model on the right must not
   change its separability relative to the equivalent non-nested expression.
5. The issue's all-True bottom-right nested output is the bug symptom and is not
   expected behavior.
