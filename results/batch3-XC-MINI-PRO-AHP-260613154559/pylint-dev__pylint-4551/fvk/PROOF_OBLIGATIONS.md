# PROOF_OBLIGATIONS.md — pyreverse type-hint fix (V1)

Each obligation is the precise property a claim in `SPEC.md` reduces to. Status:
**DISCHARGED** (proved by hand against the fragment / Z3-class linear facts),
**ESCALATION** (depends on a library invariant abstracted by an axiom; stated, not
machine-proved), or **REGRESSION-GUARD** (load-bearing for the existing tests).

| ID | Obligation | Unit | Status |
|----|------------|------|--------|
| OB1 | `get_annotation` terminates and returns a `Name`/`Subscript` node or `None`. | F2 | DISCHARGED |
| OB2 | `get_annotation` never raises: every possibly-undefined field read (`parent.value.name`, `scope().args.annotations`, …) is inside `try/except AttributeError`; the `infer` call is inside `try/except InferenceError`. | F2 | DISCHARGED |
| OB3 | `infer_node` always returns a `set` and never raises. | F3 | DISCHARGED |
| OB4 | `class_names` returns a duplicate-free list of `.name`s of kept nodes, in first-occurrence order, with no crash on `Name`/`Subscript`/other kinds. | F4 | DISCHARGED |
| OB5 | For a method with **no** annotations, `get_values` emits exactly the legacy `name(p1,…,pk)\l`. | F5 | DISCHARGED / **REGRESSION-GUARD** |
| OB6 | `get_annotation` is **idempotent**: a second pass does not wrap `Optional[Optional[…]]`. | F2 | DISCHARGED |
| OB7 | `default, *_ = node.infer()` cannot raise `ValueError` ("not enough values"). | F2 | ESCALATION (AXIOM-INFER) |
| OB8 | `ann.name = label` cannot raise `AttributeError` (nodes have `__dict__`). | F2 | DISCHARGED (AXIOM-HEAP-DICT, evidenced) |
| OB-INSP | Substituting `set(node.infer())` → `utils.infer_node(node)` preserves the observable type-map on the **un-annotated** domain. | inspector | DISCHARGED / **REGRESSION-GUARD** |
| OB9 | An annotation `Name`/`Subscript` placed in `instance_attrs_type`/`locals_type` does not create a spurious association edge nor crash `get_associated` / `extract_relationships`. | diagrams, diadefslib | DISCHARGED |

---

## OB1 — `get_annotation` total/typed

By case on the entry branch (Case Analysis on `node.parent.kind` / `node.kind`):
1. `parent isa AnnAssign` ⇒ `ann := parent.annotation` (a `Name`/`Subscript`).
2. `node isa AssignAttr` ⇒ `ann := dict(zip(...)).get(rhs.name)`, a `Name`/`Subscript`
   or `None` (dict miss / `AttributeError`).
3. else ⇒ early `return None`.
Then a straight-line tail: one `infer1`, one `label`, one conditional wrap, one
guarded write, `return ann`. No loop except the bounded `zip` (≤ `len(locals)`
steps). ⇒ terminates; return type ∈ {Name, Subscript, None}. **DISCHARGED.**

## OB2 — `get_annotation` never raises

The only expressions that can raise are:
* `node.parent.scope().args.annotations` and `node.parent.value.name` — both inside
  `try: … except AttributeError: pass`. In the fragment, an undefined field reduces
  to `undef`; the `except` maps the raise to "leave `ann = None`". Symbolic
  execution of the `AssignAttr` branch with any of those fields undefined lands on
  `ann = None`, never on a stuck/raised state.
* `node.infer()` — inside `try: … except astroid.InferenceError: default = ""`.
Every other operation (`isinstance`, `label`, string ops, the map write) is total.
Hence F2 is total on its domain. **DISCHARGED.** (Subsumes the `Assign` vs
`AnnAssign` vs `AugAssign` vs tuple-target vs `For`-target RHS cases: all reduce via
`AttributeError` to `ann = None`.)

## OB3 — `infer_node` total, returns a set

`ann := get_annotation(node)` (total by OB2). If `ann` truthy ⇒ `return {ann}` (a
set). Else `return set(node.infer())` guarded by `except InferenceError: return set()`.
Both arms yield a `Set`; no uncaught raise. **DISCHARGED.**

## OB4 — `class_names` correctness (loop circularity)

Discharge the `(forNodes)` circularity (SPEC §6) by guarded coinduction:
* **genuine step:** consume `head(NS)` — the `for` advances one element (≥1 `=>⁺`
  step ⇒ guardedness satisfied).
* **case split** on `keep(head)` and on `head.name ∈ ACC`:
  - `keep(head) ∧ head.name ∉ ACC` ⇒ append `head.name`; invoke the hypothesis on
    `(tail(NS), ACC ++ [head.name])`.
  - otherwise ⇒ `ACC` unchanged; invoke the hypothesis on `(tail(NS), ACC)`.
* **base case:** `NS = []` ⇒ return `ACC` (Reflexivity; `names'([],ACC)=[]`).
The accumulator invariant `names(prefix)` (dedup, first-occurrence) is preserved by
each branch, so on exit `result = names(nodes)`. The widened `isinstance` only
changes `keep`, which is read through the total `hasField(n,"name")` guard, so no
node without a `name` is ever dereferenced. Finite `nodes` ⇒ terminates.
**DISCHARGED.**

## OB5 — backward compatibility of the writer (the load-bearing VC)

Specialise F5 to a method with `func.returns = None` and
`∀i. func.args.annotations[i] = None`:
* `ret = ""` (guard `func.returns` false).
* `amap = dict(zip(args, [None,…,None]))`; the inner loop sets every value to `""`
  (since `annotations.get(arg)` is `None` ⇒ `annotation_label = ""`).
* `argstr = ", ".join(arg.name for arg in args)` because every `s = ""` selects the
  `f"{arg.name}"` arm — **in `args` order** (dict preserves insertion order; the
  inner loop only overwrites existing keys).
* emitted = `func.name + "(" + argstr + ")" + "" + r"\l"` = legacy
  `r"{}{}({})\l".format(label, func.name, ", ".join(names))`.
Byte-identical to the pre-fix writer ⇒ the existing `tests/data/classes_No_Name.dot`
(`get_value()`, `set_value(value)`) is reproduced. **DISCHARGED / REGRESSION-GUARD.**

Corollary (alignment): when the first parameter is `self`, `args = args.args[1:]`
aligns positionally with `annotations[1:]`, so any present annotation attaches to the
correct parameter. (Fails only for first-param-not-`self`; see Finding 2 / OB-S.)

## OB6 — idempotency of the `Optional` wrap

Second pass: `base' = label(ann) = ann.name = "Optional[" + base + "]"` (mutated in
pass 1). The wrap predicate is `valueOf(infer1(node)) == none ∧ ¬startsOpt(base')`.
`startsOpt("Optional[…]") = true` ⇒ the conjunct is false ⇒ `L = base'` unchanged ⇒
the write `ann.name := base'` is a no-op. No `Optional[Optional[…]]`. **DISCHARGED.**
(This is *why* the guard `not label.startswith("Optional")` exists — it makes repeated
Linker passes over one project sound.)

## OB7 — `default, *_ = node.infer()` cannot `ValueError`

`a, *_ = G` raises `ValueError` only if generator `G` yields **zero** items.
**AXIOM-INFER:** astroid `NodeNG.infer()` is decorated `@raise_if_nothing_inferred`,
so it yields ≥ 1 element (often `Uninferable`) or raises `InferenceError` (caught).
Hence the unpack always binds `default`. **ESCALATION** — depends on the astroid
library invariant, abstracted by AXIOM-INFER (not machine-proved here); holds for the
pinned `astroid>=2.6,<2.7`. Route: astroid `astroid/decorators.py`
`raise_if_nothing_inferred`.

## OB8 — `ann.name = label` cannot `AttributeError`

**AXIOM-HEAP-DICT:** astroid nodes carry a writable `__dict__`. *Evidence (not
assumption):* the pre-existing inspector already assigns custom attributes to nodes of
several kinds, including `node._handled` on `AssignName`
(`inspector.py:201`) and `node.uid`/`node.locals_type`/`node.instance_attrs_type`/
`node.implements` (`:118,141,164,171`). Since `AssignName` (a node leaf) accepts a new
attribute, the shared `NodeNG.__dict__` mechanism accepts `.name` on `Name`/`Subscript`
too. **DISCHARGED.**

## OB-INSP — inspector substitution preserves semantics (un-annotated)

On the un-annotated domain `getAnnotation(node) = None`, so
`infer_node(node) = set(node.infer())` on success and `∅` on `InferenceError`.
* success: `frame.locals_type[name] = list(set(current) | set(node.infer()))` — the
  pre-fix expression verbatim.
* `InferenceError`: new = `list(set(current) | ∅) = list(set(current))`; pre-fix =
  `current` (assignment skipped). Same multiset of nodes; the existing tests assert
  single-element entries (`type_dict["TYPE"][0].value == "final class"`,
  `type_dict["_id"][0] is Uninferable`, `type_dict["relation"][0].name == "DoNothing"`),
  all reproduced. **DISCHARGED / REGRESSION-GUARD.**

## OB9 — annotation nodes do not create spurious edges / crashes

In `extract_relationships` and `diadefslib.get_associated`, each value `v` from the
type-maps is filtered by `isinstance(v, astroid.Instance)` then
`isinstance(v, astroid.ClassDef)`. A `Name`/`Subscript` annotation node matches
neither ⇒ it is skipped (`continue`), so no association edge is added and
`object_from_node` is never called on it (no `KeyError`/crash). **DISCHARGED.**

---

## Open / residual obligations

* **OB7** is the one obligation not internally closed: it rests on the astroid
  `infer()` non-emptiness invariant (AXIOM-INFER). Marked **ESCALATION BOUNDARY**;
  honestly *not* admitted as `[trusted]`.
* **OB-S (Finding 2):** correct arg/annotation alignment for methods whose first
  parameter is not `self`/`cls` is **NOT** discharged — it is *false* under V1 (the
  `[1:]` slice). Left out-of-domain to match the reference; see ITERATION_GUIDANCE.md.
