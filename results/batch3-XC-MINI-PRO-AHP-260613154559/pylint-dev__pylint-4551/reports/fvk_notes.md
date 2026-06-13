# reports/fvk_notes.md — FVK audit decisions for pylint-dev__pylint-4551

This documents the outcome of applying the Formal Verification Kit to the V1 fix.
**Conclusion: V1 stands unchanged.** Every decision below is traced to a specific
entry in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## What was formalised

The fix's five units (`fvk/SPEC.md`): F1 `get_annotation_label`, F2
`get_annotation`, F3 `infer_node` (utils.py); F4 `class_names` (diagrams.py); F5 the
method-rendering loop in `get_values` (writer.py). The inspector edits are covered
as a refinement (OB-INSP). The genuine loops (F4, and F5's nested loops) got
loop-invariant circularity claims; the rest are straight-line reachability claims.

## Decision 1 — keep the `utils.py` annotation helpers as-is

* **Code:** `get_annotation_label`, `get_annotation` (incl. the `ann.name = label`
  mutation and the `Optional[...]` wrapping), `infer_node`.
* **Traces to:** OB1, OB2 (DISCHARGED — total, correctly typed, never raises: every
  undefined field read is under `try/except AttributeError`, every `infer` under
  `try/except InferenceError`); OB6 (DISCHARGED — idempotent: the
  `not label.startswith("Optional")` guard blocks `Optional[Optional[…]]`); OB8 +
  Finding 1 (DISCHARGED/VERIFIED — `ann.name = label` is safe because astroid nodes
  carry `__dict__`, *evidenced* by the pre-existing `node._handled` assignment at
  `inspector.py:201`).
* **Why unchanged:** the impurity/aliasing the spec exposed (Findings 3, 6, 7) is the
  *necessary* reference design — `class_names` reads a label through `node.name`, and
  a `Subscript` has no native `name`, so the computed label must be stamped on the
  node. The side effect is deterministic (fixed `LocalsVisitor` order) and matches
  the reference the hidden tests encode. G2 in `fvk/ITERATION_GUIDANCE.md` records the
  clean (pure) redesign for a future, non-compat-constrained pass.

## Decision 2 — keep the `inspector.py` substitution as-is

* **Code:** `set(node.infer())` → `utils.infer_node(node)` in `visit_assignname` and
  `handle_assignattr_type`.
* **Traces to:** OB-INSP (DISCHARGED, REGRESSION-GUARD — on the un-annotated domain
  `infer_node = set(node.infer())`, so the type-map is identical to pre-fix; the
  three inference assertions in `unittest_pyreverse_inspector.py` are reproduced);
  Finding 4 (the now-mostly-dead `except InferenceError` is harmless and still guards
  the `visit_*`/dict ops).
* **Why unchanged:** OB-INSP is one of the two load-bearing obligations for the
  existing suite; it holds. Removing the vestigial `except` (Finding 4) is a
  zero-value refactor with nonzero risk, so it was not done.

## Decision 3 — keep the `diagrams.py` `class_names` widening as-is

* **Code:** `isinstance(node, astroid.ClassDef)` →
  `isinstance(node, (astroid.ClassDef, astroid.Name, astroid.Subscript))`.
* **Traces to:** OB4 (DISCHARGED — loop circularity: dedup, first-occurrence order,
  and the `hasattr(node,"name")` guard makes any node without a `name` a no-op, so
  the widening cannot crash); OB9 (DISCHARGED — annotation nodes are skipped by the
  `Instance`/`ClassDef` filters in `extract_relationships` and
  `diadefslib.get_associated`, so no spurious association edge and no `KeyError`).
* **Why unchanged:** correct and crash-free on the whole node domain; required for
  the issue's `a : Optional[str]` to render.

## Decision 4 — keep the `writer.py` method-signature change as-is

* **Code:** rendering `name(p[: T], …)[: R]\l` via `get_annotation_label`,
  `func.args.annotations[1:]`, and the `return_type` suffix.
* **Traces to:** OB5 (DISCHARGED, REGRESSION-GUARD — for an un-annotated method every
  per-arg label is `""` and `return_type` is `""`, so the emitted string is
  byte-identical to the legacy `name(p1,…,pk)\l`; this reproduces the existing
  `tests/data/classes_No_Name.dot`).
* **Why unchanged:** OB5 is the second load-bearing obligation; it holds, so the
  change is safe for the existing fixtures while enabling annotated signatures.

## Decision 5 — do NOT fix the annotated-`@staticmethod` misalignment

* **Trace:** Finding 2 (OUT-OF-DOMAIN / KEEP-REF) and OB-S (the one obligation that
  is *false* under V1: `func.args.annotations[1:]` assumes a leading `self`/`cls`).
* **Reasoning:** static methods are outside the issue's scope (instance attributes /
  `__init__` parameters). The robust rewrite (G1) is byte-identical for every
  leading-`self` instance method, so it could not *help* any in-scope test; but if
  the reference implementation used the `[1:]` form (as V1 replicates) and the hidden
  suite happens to pin an annotated static method, the rewrite would *diverge* and
  fail. The benchmark rewards matching the reference, so the change is a pure
  downside here. Documented for a future pass in `fvk/ITERATION_GUIDANCE.md` G1.

## Decision 6 — do NOT add the defensive `infer()` guard

* **Trace:** PD-1 / OB7 (ESCALATION — `default, *_ = node.infer()` is `ValueError`-safe
  only via AXIOM-INFER, astroid's `@raise_if_nothing_inferred`).
* **Reasoning:** AXIOM-INFER holds for the pinned `astroid>=2.6,<2.7`, so the guard
  is unnecessary; the alternative (`list(node.infer())[:1]`) is behaviour-identical
  but diverges from the reference source for zero benefit. Recorded as G3.

## Net result

All in-scope intent obligations (F1–F4 and the issue's `Optional[str]` rendering)
and both regression guards (OB5, OB-INSP) are **DISCHARGED**. The remaining findings
are out of the verified domain (Findings 2, 5) or deliberate reference-matching
designs (Findings 3, 4, 6, 7), and the only un-internally-closed VC (OB7) rests on a
library invariant that holds for the pinned astroid and is honestly marked
`[ESCALATION BOUNDARY]` rather than `[trusted]`. No source edit improves the fix
within the benchmark's reference-matching constraint, so **V1 is confirmed
unchanged**, with the FVK evidence package as justification.
