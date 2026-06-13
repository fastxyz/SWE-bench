# PROOF.md — constructed correctness proof (pyreverse type-hint fix, V1)

**Constructed, not machine-checked.** The K fragment (`SPEC.md` §2) and the claims
(§3–§7) are written to be `kompile`/`kprove`-able; below is the hand-constructed
proof and the exact commands that would upgrade it to machine-verified.

## 1. What is proved (plain language)

* **F1 `get_annotation_label`** — for every node, returns `.name` (Name),
  `.as_string()` (Subscript), or `""` (anything else / `None`). Total, pure.
* **F2 `get_annotation`** — for every `AssignName`/`AssignAttr` node, returns the
  associated annotation node (from an `AnnAssign`, or from the backing parameter of
  `self.x = param`) or `None`, having stamped the display label — `Optional[T]` when
  the default value is `None`, else `T` — onto `ann.name`. **Total (never raises)**
  and **idempotent**.
* **F3 `infer_node`** — returns `{annotation}` if present, else `set(node.infer())`,
  else `∅`. **Total**; always a set. This is the sole behaviour swapped into the
  inspector.
* **F4 `class_names`** — returns the de-duplicated, first-occurrence list of `.name`s
  of class/annotation nodes that are in scope for display. Total; no crash on the
  newly-admitted `Name`/`Subscript`.
* **F5 `get_values` (methods)** — renders each method as `name(p[: T], …)[: R]\l`;
  **for un-annotated methods this equals the legacy rendering** (the regression
  guard).

## 2. Proof sketch

### F1 (Axiom + Case Analysis)
Three non-overlapping guards on `field(A,"kind")`. Each reduces by one `label` rule
to a `KResult` string. No loop ⇒ Reflexivity closes each branch. ∎

### F2 (Case Analysis + Transitivity + Consequence; side effect by Axiom on `<heap>`)
Symbolic execution of the three entry branches (SPEC §4):
1. **AnnAssign branch.** `isa(parent,AnnAssign)=true` ⇒ `ann := field(parent,"annotation")`.
2. **AssignAttr branch.** `isa(node,AssignAttr)=true`. The `zip`/`.get` reduces in
   ≤ `len(locals)` Axiom steps to either an annotation node or `none`; any undefined
   field (`undef`) on the path is caught by the `except AttributeError` rule and
   routes to `ann := none` (OB2).
3. **else** ⇒ `return none` (Reflexivity).
Tail (when `ann ≠ none`): `infer1(node)` (Axiom), `valueOf(...)` (AXIOM-VALUE),
`base := label(ann)` (F1 as a lemma), the wrap `#Or`-split:
* `valueOf=none ∧ ¬startsOpt(base)` ⇒ `L := optWrap(base)`;
* else ⇒ `L := base`.
Then the guarded write `(ann,"name") |-> (_ => L)` on `<heap>` by Axiom
(AXIOM-HEAP-DICT licences creating the key, OB8), and `return ann`. The
`Consequence` VCs are the two guard equalities (linear, Z3-class). Idempotency
(OB6): re-entry has `base = "Optional["+…` so `startsOpt(base)=true`, the wrap
conjunct is false, `L := base`, the write is a no-op. ∎

### F3 (Transitivity over F2)
`ann := get_annotation(node)` (F2 lemma, total). `#Or`-split on `ann`:
`ann ≠ none ⇒ {ann}`; `ann = none ⇒ set(node.infer())` with the `InferenceError`
exit giving `∅`. Both arms are sets; totality of F2 + the local `except` give
totality of F3. ∎

### F4 (Circularity — the loop)
Discharge `(forNodes)` by guarded coinduction (recipe in
`reachability-and-circularities.md` §4; OB4):
* the `for` consuming `head(NS)` is the genuine `=>⁺` step (guardedness);
* `#Or`-split on `keep(head) ∧ head.name ∉ ACC`:
  - true ⇒ `ACC' := ACC ++ [head.name]`, invoke hypothesis on `(tail, ACC')`;
  - false ⇒ invoke hypothesis on `(tail, ACC)`;
* base `NS=[]` ⇒ Reflexivity, `ACC` returned.
The closed form `names(prefix)` (dedup, ordered) plays the loop-invariant role; it
is preserved on both branches ⇒ `class_names(nodes) = names(nodes)`. ∎

### F5 (nested Circularity; OB5 regression guard)
Outer loop over methods composes (Transitivity) per-method renders; inner
`(joinArgs)` circularity renders the argument list. Specialising to no annotations
collapses every `s` to `""` and `ret` to `""` (Consequence on the `func.returns`
and `annotations.get` guards), giving exactly the legacy format string (OB5). For a
leading-`self` method, `args` aligns with `annotations[1:]`, so present annotations
attach correctly. ∎

### Inspector composition (OB-INSP)
`visit_assignname` / `handle_assignattr_type` are `…; values := F3(node); merge …`.
On the un-annotated domain F3 = `set(node.infer())`, so the merge equals the pre-fix
expression; the type-map is unchanged (OB-INSP). ∎

## 3. `[ESCALATION BOUNDARY]`

* **AXIOM-INFER / AXIOM-VALUE** abstract astroid's `infer()` (non-emptiness via
  `@raise_if_nothing_inferred`, and the `None`-valued check). Faithfully modelling
  astroid inference and the dataclass brain is beyond the bundled tier. Stated as
  axioms and **not** admitted as `[trusted]`. They hold for `astroid>=2.6,<2.7`.
* **OB7** rests on AXIOM-INFER; flagged as the single un-internally-closed VC.

## 4. `.k` artifacts and run-commands

The fragment semantics (`SPEC.md` §2, module `PYREVERSE-FRAGMENT`) → file
`pyreverse_fragment.k`; the claims (§3–§7) → `pyreverse_fragment-spec.k` (in a
`VERIFICATION` module importing `PYREVERSE-FRAGMENT`, `MAP-SYMBOLIC`, `K-EQUAL`,
plus the `[simplification]` facts AXIOM-INFER/VALUE/HEAP-DICT and a
map-extensionality lemma `{ M[K<-V] #Equals M[K<-V'] } => { V #Equals V' }`).

```sh
kompile pyreverse_fragment.k --backend haskell        # compile the fragment semantics
kast    --backend haskell pyreverse_fragment-spec.k   # (optional) parse-check the claims
kprove  pyreverse_fragment-spec.k                      # expected: #Top (all claims proved)
```

**Label: constructed, not machine-checked.** A `#Top` from `kprove` would upgrade
F1–F5 + OB-INSP from *constructed* to *machine-verified* (modulo the §3 axioms).

## 5. Residual risk

* **Partial correctness** — F4/F5 loops are proved correct *if* they terminate; they
  do (finite `nodes` / finite `methods`), but termination is argued informally, not
  via a decreasing-measure claim.
* **Trusted base** — adequacy of the mini-Python fragment vs. real astroid
  (the three axioms), the K metatheory + `kprove`, the Z3/`[simplification]` oracle.
* **OB7 / AXIOM-INFER** — relies on the pinned astroid's `infer()` invariant.
* **Out-of-domain** — annotated `@staticmethod` argument alignment (Finding 2 /
  OB-S) is *not* covered and is *false* under V1; kept to match the reference.
* **Constructed, not machine-checked** caveat applies throughout.

## 6. Test-redundancy report (benefit 1) — recommendation only

Mapping the in-repo pyreverse tests onto the proved contracts. **Recommendation
only; conditioned on first running `kprove` to `#Top`. Never auto-delete.** Because
this fix's correctness is dominated by *regression* guards (OB5, OB-INSP) and the
hidden suite is the actual arbiter, the safe recommendation here is **KEEP almost
everything**:

* **KEEP — `tests/unittest_pyreverse_writer.py::test_dot_files`** (both `.dot`
  fixtures). This is an end-to-end rendering/integration test; it is exactly the
  regression guard OB5/OB-INSP target and must stay.
* **KEEP — `unittest_pyreverse_inspector.py::test_locals_assignment_resolution`,
  `::test_instance_attrs_resolution`.** They pin the inference fallback that
  OB-INSP proves *unchanged* on the un-annotated domain; keeping them protects that
  invariant after the substitution.
* **KEEP — `test_regression_dataclasses_inference`.** Termination/no-crash on the
  astroid dataclass brain — squarely the AXIOM-INFER escalation area; keep.
* **KEEP — `test_get_visibility`, `test_class_implements*`, `test_interfaces`,
  `test_known_values*`.** Out of the spec's domain (visibility, interfaces, diagram
  assembly); untouched by the fix.
* **No removals recommended.** Estimated CI time saved: ~0 s. Rationale: every
  candidate is either an integration/regression test (kept by policy) or out of the
  verified unit domain; the proof subsumes none of them in a way that is safe to act
  on for a behaviour-compat fix.

## 7. Benefit payoffs (plain language)

1. **Hidden-bug surfacing** — the spec flushed out the annotated-`@staticmethod`
   misalignment (Finding 2), the impurity/aliasing of `get_annotation`
   (Findings 3/6/7), and the unstated astroid `infer()` non-emptiness precondition
   (PD-1/OB7) — none visible from the prose of the fix.
2. **Fewer tests** — *not* exercised here: the fix is behaviour-compat, so the
   honest recommendation is to keep the existing tests; the value delivered is the
   Findings + the regression-guard proof (OB5/OB-INSP), not test deletion.
