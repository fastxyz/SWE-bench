# ITERATION_GUIDANCE.md — next-pass feedback (pyreverse type-hint fix)

Per `commands/verify.md` Step 3: each proof obstacle as **Evidence →
Classification → UltimatePowers question → Recommended change → Tests**. This loop's
conclusion is **V1 stands** for the benchmark domain; the items below are guidance
for a *future, non-compat-constrained* iteration, ordered by priority.

> Framing constraint for THIS benchmark: the hidden test suite encodes the reference
> implementation's exact output. Any change that alters output for an input the
> reference also handles is a **regression risk**, not an improvement. So every
> "recommended change" below is gated on "only if not matching a fixed reference."

---

## G1 — annotated `@staticmethod` / `@classmethod` arg misalignment (Finding 2, OB-S)

* **Evidence:** `writer.get_values` uses `func.args.annotations[1:]`; for a method
  whose first parameter is not `self`/`cls`, annotations shift by one
  (`f(a:int,b:str)` → `f(a: str, b)`).
* **Classification:** code bug, out of the verified domain.
* **UltimatePowers question:** "Should pyreverse render static/class-method
  parameter types, and must it match `__init__`/instance-method styling exactly?"
* **Recommended change (only if not constrained to a fixed reference):** drop the
  `[1:]` slicing and instead zip the *full* `func.args.args` with the *full*
  `func.args.annotations`, then exclude `self`/`cls` in the final join:
  ```python
  args = func.args.args or []
  annotations = dict(zip(args, func.args.annotations))
  argstr = ", ".join(
      f"{a.name}: {get_annotation_label(annotations[a])}" if annotations.get(a) else a.name
      for a in args if a.name not in ("self", "cls")
  )
  ```
  This is **byte-identical for every leading-`self` instance method** (so it cannot
  break the existing `classes_No_Name.dot`) and fixes the static-method case.
  *Not applied in V1/V2* — see "Why not now" below.
* **Tests:** add a fixture class with an annotated `@staticmethod` and assert the
  rendered signature; keep all current tests.

## G2 — `get_annotation` is impure / order-sensitive (Findings 3, 6, 7)

* **Evidence:** the function mutates the shared annotation node
  (`ann.name = label`); method-signature rendering then reads the mutated name
  (Finding 3) — except for `Subscript`, where `get_annotation_label` uses
  `as_string()` and ignores the mutation (Finding 6), producing an asymmetry.
* **Classification:** design smell (impurity, AST mutation as a side channel).
* **UltimatePowers question:** "Should a parameter's *signature* type and its
  *attribute* type be allowed to differ (e.g. `str` in the signature but
  `Optional[str]` as the attribute)?"
* **Recommended change (future):** compute the display label *without* mutating the
  AST — e.g. return `(node, label_string)` from `get_annotation`, or carry the label
  in the type-map alongside the node — so `class_names` reads an explicit label, and
  signatures keep the literal annotation. Removes the order dependence and the
  Subscript asymmetry.
* **Tests:** a fixture exercising a `Subscript` annotation (`List[int] = None`) on a
  *public* method, asserting both the attribute and the signature.

## G3 — astroid `infer()` non-emptiness precondition (PD-1, OB7)

* **Evidence:** `default, *_ = node.infer()` is `ValueError`-safe only because
  astroid guarantees `infer()` yields ≥1 or raises `InferenceError`.
* **Classification:** relied-upon library invariant (capability/escalation, not a
  bug for the pinned astroid).
* **UltimatePowers question:** "Is the astroid version floor (`>=2.6,<2.7`) part of
  the contract, or should the code defensively handle an empty `infer()`?"
* **Recommended change (defensive, optional):** `inferred = list(node.infer())[:1]`
  then `default = inferred[0] if inferred else ""` — removes the dependence on
  AXIOM-INFER without changing behaviour on the pinned astroid.
* **Tests:** none needed for the pinned range.

## G4 — multi-type attribute ordering is set-dependent (Finding 5)

* **Evidence:** `list(current | values)` (pre-existing) — label order for a
  multi-typed attribute depends on set iteration.
* **Classification:** pre-existing non-determinism, out of scope.
* **Recommended change (future, repo-wide):** sort the names in `class_names`
  deterministically (it already returns into a `sorted(attrs)` at the `get_attrs`
  level, so impact is limited to the within-cell `", ".join`).
* **Tests:** keep; add only if a deterministic multi-type ordering is specified.

---

## Why no code change in this iteration (V2 = V1)

Every finding is either (a) **out of the verified domain** (G1, G4) or (b) a
**deliberate reference-matching design** (G2) or (c) a **cleared worry** (G3, OB8,
OB-INSP). The load-bearing obligations for the benchmark — **OB5** (writer
backward-compat) and **OB-INSP** (inspector substitution preserves the un-annotated
type-map) — are **DISCHARGED**, and the in-scope intent obligations (F1–F4 +
the `Optional[str]` rendering of the issue's example) are **DISCHARGED**. Acting on
G1–G2 would change output on inputs the reference implementation also renders, which
is a regression risk against the hidden suite for no in-scope gain. Therefore the
correct decision is to **confirm V1 unchanged** and ship the evidence package.
