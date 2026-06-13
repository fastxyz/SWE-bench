# Control notes — django__django-15268 (V2 audit)

## Summary of the audit outcome

I conducted a systematic, skeptical review of the V1 fix and recorded 13 numbered
findings in `review/FINDINGS.md`. The review found **no defects** — no correctness gap,
edge-case failure, regression, contract violation, or convention mismatch. Therefore the
V1 source change **stands unchanged**. No files under `repo/` were edited in this pass.

The single V1 production change is the new `reduce` method on
`AlterTogetherOptionOperation` (`django/db/migrations/operations/models.py:531`).

## Decision: keep V1 unchanged

Each component of this decision traces to specific findings:

* **The fix solves the issue as described.** F1 traces the optimizer through the exact
  example in `PROBLEM.md` and shows it produces the expected two-operation result. No
  change needed for correctness.

* **The `reduce()==True` ("optimize across") assertion is genuinely valid**, which is the
  crux of safety for a change that lets the optimizer reorder operations:
  * F2 confirms state-level independence — `alter_model_options` with `option_keys=None`
    writes only the single option key, so `unique_together` and `index_together` updates
    are orthogonal.
  * F3 confirms database-level independence — unique constraints and `index_together`
    indexes are distinct, distinctly-named objects on every backend, so the two ops
    commute against a live DB.
  Because the independence is real, every reordering the optimizer may now perform is
  semantics-preserving. Nothing to harden.

* **No regression to pre-existing optimizations.** F4 (same-subtype collapse and
  `AlterFooTogether`→`DeleteModel` still go through `super()`'s list result via
  short-circuit), F5 (cross-model behavior unchanged), and F8 (the change only turns one
  `False` into `True`, never removing a reduction) collectively show existing behavior is
  intact. No corrective edit required.

* **The #31503 remove/add split is preserved.** F6 is the key safety check: when a real
  field operation that references the affected field sits between the pair,
  `AddField.reduce(...)`/`FieldOperation.reduce` returns `False` and `right` flips to
  `False`, so the optimizer still refuses to collapse. V1 only collapses when the sole
  in-between operation is the independent other-type `AlterFooTogether`. This is precisely
  the desired narrow behavior, so no scope tightening is needed.

* **Scope is correctly conservative.** F7 shows the new clause fires only for
  `AlterTogetherOptionOperation` subclasses, leaving `AlterOrderWithRespectTo`,
  `AlterModelTable`, and `AlterModelOptions` untouched. Broadening would assert
  commutativity I have not proven; narrowing would fail the issue. The current scope is the
  right one — no change.

* **Optimizer invariants hold.** F9 shows termination/stability is preserved (true-returns
  do not reorder by themselves; every list reduction strictly shortens the list, so no
  oscillation). No defensive change needed.

* **Contract and conventions are satisfied.** F10 (returns list-or-bool, no empty-list
  pitfall, `elidable` handled), F11 (idiom matches `ModelOperation.reduce`; `reduce`
  placed last; in-method class reference already used by `CreateModel.reduce`), and F12
  (no exception paths) show the code is well-formed and idiomatic. There is nothing to
  refactor.

## Why I did *not* make a "minimal refactor"

The task permits a minimal refactor, but F11 documents that the surrounding `reduce`
methods (`ModelOperation`, `RenameModel`, `ModelOptionOperation`, `CreateModel`) are
deliberately terse and carry no explanatory inline comments. Adding a comment or
restructuring the boolean expression would diverge from that established convention for no
functional gain. The detailed rationale (independence proof, #31503 preservation) belongs
in these review/report documents, not as noise in the operation class. Hence the code is
left exactly as in V1.

## F13 acknowledgement (no action)

F13 notes a forward-looking property: the base-class placement assumes every
`AlterTogetherOptionOperation` subclass manages one independent option. This is true for
the only two subclasses that exist and is a sound abstraction, not a current bug, so it
warrants no code change now.

## Files changed in this pass

None. `review/FINDINGS.md` and `reports/control_notes.md` were added; no `repo/` source
was modified. `reports/baseline_notes.md` (V1 explanation) remains accurate.
