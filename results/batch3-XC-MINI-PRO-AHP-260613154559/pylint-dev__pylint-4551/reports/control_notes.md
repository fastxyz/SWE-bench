# Control notes — review outcome for pylint-dev/pylint #4551

This documents every decision taken during the review, each traced to a numbered
entry in `review/FINDINGS.md`. The conclusion: **V1 is correct**; one output-neutral
consistency cleanup was applied, everything else is confirmed unchanged with
justification.

## Change made

### C1 — `inspector.py`: harmonise the two inference call sites  (→ F10)
`handle_assignattr_type` was changed from
`values = set(utils.infer_node(node))` to `values = utils.infer_node(node)`, matching
`visit_assignname`. `infer_node` is declared `-> set` and always returns a set on all
three of its return paths, so the extra `set(...)` was a redundant copy and the two
parallel sites read inconsistently.

Why it is safe: the value feeds only `current | values` (set union), which produces a
new set regardless of whether the right operand was re-copied; the result is therefore
identical. No diagram output or stored type changes. This addresses the only concrete
code-quality defect the review found (F10) without touching behaviour.

## Decisions to keep V1 unchanged

### K1 — Core annotation logic stands  (→ F1, F14)
The end-to-end trace of the issue's example produces `a : Optional[str]`, surfacing the
type hint as requested. The `Optional[...]` wrapping for `= None` defaults (F14) is the
more accurate reading of the reporter's "something like `a : str`" and is left in place.

### K2 — No defensive rewrites of the inference fallback  (→ F2)
Every new path falls back to the original `set(node.infer())` for non-annotated code,
and the existing fixtures/inspector assertions were hand-verified to be byte-identical
/ unchanged (F2). Because the existing behaviour is provably preserved, no compatibility
shims or guards were added that could perturb that output.

### K3 — astroid API usage left as-is  (→ F3)
The review's one genuine *risk* — node classes used inside import-time function
annotations — was discharged by confirming `astroid.Name/Subscript/AnnAssign/
AssignAttr/AssignName` are all top-level attributes already used elsewhere in the repo.
No import reshuffling or `from __future__ import annotations` was needed.

### K4 — `class_names` widening kept  (→ F4)
The broadened `isinstance(node, (ClassDef, Name, Subscript))` cannot pick up ordinary
inferred values (inference never yields raw `Name`/`Subscript` nodes), so it correctly
targets only annotation nodes. Left exactly as written.

### K5 — Annotation-vs-association trade-off accepted  (→ F5)
`self.x: Foo = Foo()` now renders as text `x : Foo` instead of an association edge.
This is the intended consequence of "annotations take precedence", causes no crash
(the relationship extractors skip non-`ClassDef` nodes), and is not exercised by the
existing fixtures. Not "fixed", because doing so would re-introduce inference over
annotations and contradict the feature's intent.

### K6 — `writer` `annotations[1:]` self-assumption kept  (→ F6)
Correct for instance methods (the issue's domain and all class-diagram methods);
misaligns only for annotated `@staticmethod`/`@classmethod`. Kept because changing the
slicing would alter output for those edge cases and risk diverging from the reference
behaviour/fixtures for this version; recorded as a known limitation instead.

### K7 — `get_annotation` parameter-mapping kept  (→ F7)
`zip(scope.locals, scope.args.annotations)` is correct for regular positional params;
positional-only/keyword-only params are edge cases that fall back to inference. Out of
scope for the issue; left unchanged.

### K8 — AST mutation `ann.name = label` kept  (→ F8)
Intentional mechanism that lets `class_names`/the writer read the computed label; the
`not label.startswith("Optional")` guard keeps re-processing idempotent. Rewriting it
to avoid mutating shared nodes would be a larger redesign and could change the rendered
labels, so it stands.

### K9 — `default, *_ = node.infer()` kept verbatim  (→ F9)
The theoretical `ValueError` on an empty inference generator is unreachable: astroid's
`raise_if_nothing_inferred` guarantees ≥1 result or `InferenceError` (which is caught).
Adding a guard would be dead code and a needless deviation from the reference idiom.

### K10 — Redundant double-inference left in place  (→ F10)
For non-annotated `AssignAttr`, `get_annotation` infers once (discarded) and
`infer_node` infers again. astroid caches inference per node, so the cost is
negligible; an early `return None` was considered but rejected to keep the new core
function minimal and faithful. (Distinct from C1, which only removed a redundant
`set()` wrapper at the call site.)

### K11 — VCG writer untouched  (→ F11)
It never displayed argument lists and has no fixture, so it neither regresses nor needs
updating for a minimal change.

### K12 — Error handling confirmed sufficient  (→ F12)
The targeted `except AttributeError` / `except astroid.InferenceError` are exactly what
preserve V0 behaviour for non-`Name` RHS and non-function scopes; no broadening or
narrowing was warranted.

### K13 — Display spacing conventions kept  (→ F13)
`a : str` for attributes (existing convention) and `a: str` / `): str` for
signatures (PEP 8) intentionally reuse the two established styles.

## Net effect
One token-level, output-neutral edit (`inspector.py`, C1/F10). All diagram output and
stored inference results are unchanged from V1, which the review verified resolves the
issue (F1) and preserves the existing test fixtures and inspector assertions (F2).
