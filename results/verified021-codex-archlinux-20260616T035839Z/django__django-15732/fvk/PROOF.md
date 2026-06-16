# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were run.

## What Is Proved

For the modeled candidate-selection step in `_delete_composed_index()`:

- a unique deletion with multiple candidates deletes the deterministic generated
  `_uniq` name when it is present;
- candidate order does not matter for that generated-name selection;
- a unique deletion with exactly one candidate preserves the existing delete
  behavior;
- a unique deletion with no candidates, or with multiple candidates not
  containing the generated name, preserves the existing raise behavior;
- non-unique deletion does not receive the `_uniq` preference.

Source-level obligations outside the K abstraction:

- `alter_unique_together()` passes `primary_key=False`, so primary keys are not
  candidates for unique-together deletion.
- explicit `Meta.constraints` and `Meta.indexes` remain excluded by the
  unchanged `exclude` argument.
- V2 preserves the original `_delete_composed_index()` signature.

## Proof Sketch

The mini semantics has one statement, `chooseUnique(isUnique, candidates,
defaultName)`, and one observable cell, `<decision>`.

1. If `isUnique == true` and `len(candidates) > 1`, the semantics rewrites to
   `finishChoice(preferDefault(candidates, defaultName))`.
2. `preferDefault()` scans the finite candidate list. If it finds
   `defaultName`, it returns the singleton list `defaultName, .Names`; otherwise
   it returns `.Names`.
3. `finishChoice(singleton)` rewrites the decision to `delete(name)`.
4. `finishChoice(.Names)` and `finishChoice(two_or_more)` rewrite the decision
   to `raise`.
5. If `isUnique == false`, the semantics skips `preferDefault()` and finishes
   the original candidate list, preserving non-unique ambiguity behavior.

The claims in `schema-editor-spec.k` instantiate these cases:

- K-UT-DEFAULT-FIRST and K-UT-DEFAULT-SECOND discharge generated-name membership
  independent of candidate order.
- K-UT-SINGLE discharges the single-candidate delete path.
- K-UT-AMBIGUOUS discharges the raise path when the generated name is absent.
- K-NONUNIQUE-AMBIGUOUS discharges the non-unique frame condition.
- K-NONE discharges the no-candidate raise path.

No loop circularity is needed because the model uses recursive spec functions
over finite lists (`len`, `preferDefault`) rather than a program loop.

## Adequacy

The abstraction preserves the property under test: the observable distinction
between deleting the generated `unique_together` constraint, deleting another
constraint, and raising. A passing instance maps to `delete(defaultName)`; a
failing pre-fix duplicate instance maps to `raise`; an unsafe arbitrary-first
implementation would map some orders to `delete(otherName)`, which is distinct.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They were
not executed in this session.

```sh
cd fvk
kompile mini-schema-editor.k --backend haskell
kast --backend haskell schema-editor-spec.k
kprove schema-editor-spec.k
```

Expected machine-check result: `#Top` for all claims.

## Residual Risk

- The proof is partial-correctness only and constructed by inspection, not
  machine-checked.
- The creation path for adding redundant single-field `unique_together` remains
  outside this proof; see F-003.
- Manually renamed constraints remain a documented residual risk; see F-004.

## Test Recommendations

No tests were modified. If machine-checking later succeeds, point tests that
only assert generated-name selection for duplicate candidates may be considered
subsumed by the proof. Integration tests that exercise real database
introspection, migration operation wiring, backend-specific naming, creation
paths, or manual renames should be kept.
