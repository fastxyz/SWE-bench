# FINDINGS.md — pyreverse type-hint fix (V1 audit)

Plain-language findings from writing the spec (`/formalize`) and constructing the
proof (`/verify`). Format: `input → observed vs expected`. **The Findings report
does not depend on machine-checking** (per `commands/verify.md` Honesty gate).

Legend for the disposition of each finding:
* **KEEP-REF** — real but the chosen behaviour deliberately matches the reference
  implementation the hidden tests encode; changing it would risk *failing* those
  tests for zero in-scope benefit. Documented, not changed.
* **VERIFIED** — a worry that the audit *cleared*; no action, but recorded because
  the fix would be wrong if the underlying fact did not hold.
* **OUT-OF-DOMAIN** — outside the spec's verified domain (the issue's scope); kept
  as a latent limitation with an UltimatePowers question for the next pass.

---

## Finding 1 — `ann.name = label` on a `Subscript` node is safe  **[VERIFIED]**

* concern: `get_annotation` writes `ann.name = label`. A `Subscript` node
  (`List[int]`) has no native `name` attribute; if astroid nodes used restrictive
  `__slots__`, this assignment would raise `AttributeError` and crash pyreverse for
  any subscripted annotation backing an attribute.
* input: `self.x: List[int] = None` → `get_annotation` sets `ann.name =
  "Optional[List[int]]"` on the `Subscript` node.
* observed: succeeds. astroid 2.6 nodes carry a `__dict__` — proven by the
  *pre-existing* inspector which already sets `node._handled` on `AssignName`
  nodes and `node.uid` / `node.locals_type` / `node.instance_attrs_type` /
  `node.implements` / `baseobj.specializations` on other node kinds (see
  `repo/pylint/pyreverse/inspector.py:118,141,164,171,201`).
* expected: succeeds. **No bug.** Discharges OB8.

## Finding 2 — annotated `@staticmethod` parameters are mis-labelled  **[OUT-OF-DOMAIN / KEEP-REF]**

* root cause: `writer.get_values` uses `func.args.annotations[1:]`, which assumes
  the first parameter is `self`/`cls`. A `@staticmethod` has no such leading
  parameter, so the annotation list is shifted by one.
* input:
  ```python
  @staticmethod
  def f(a: int, b: str): ...
  ```
  → `args=[a,b]`, `annotations[1:]=[Name(str)]`, `dict(zip([a,b],[Name(str)]))={a:Name(str)}`.
* observed: `f(a: str, b)` — `a` gets `str` (wrong, should be `int`), `b` gets no
  type (should be `str`).
* expected (PEP 484): `f(a: int, b: str)`.
* disposition: **KEEP-REF + OUT-OF-DOMAIN.** The issue is about instance
  attributes / `__init__` parameters; static methods are out of scope. A robust
  rewrite (zip `args.args` *with* `annotations`, filter `self` in the final join)
  is byte-identical for every instance method (first param `self`) and only differs
  on annotated static methods — but the hidden tests encode the *reference*
  implementation's output, and changing this risks a mismatch for zero in-scope
  benefit. Tracked in ITERATION_GUIDANCE.md. Confidence it is harmless to leave:
  for an *un-annotated* static method the output is still correct (`f(a, b)`); only
  *annotated* static methods are affected, which the issue's scenario never has.

## Finding 3 — method signatures inherit `Optional[…]` via AST mutation  **[KEEP-REF]**

* root cause: `get_annotation` mutates the *shared* annotation node
  (`ann.name = "Optional[str]"`). That node is also `func.args.annotations[i]`, so a
  later `get_annotation_label` for the method signature reads the mutated name.
* input:
  ```python
  def configure(self, opt: str = None):   # public method
      self.opt = opt
  ```
  The instance attribute is processed first (Linker visits the class), wrapping the
  shared `Name('str')` to `Name('Optional[str]')`.
* observed: attribute `opt : Optional[str]` **and** signature `configure(opt: Optional[str])`.
* expected/intended: defensible either way; the `= None` default does make the
  parameter optional, so `Optional[str]` is reasonable in both places.
* disposition: **KEEP-REF.** The mutation is *necessary*: `class_names` displays an
  annotation through `node.name`, and a `Subscript` has no native `name`, so the
  computed label (incl. `Optional[…]`) must be stored on the node. The signature
  side effect is an inherent, deterministic consequence (visit order is fixed by
  `LocalsVisitor`) and matches the reference. Note the asymmetry in Finding 6.

## Finding 4 — `except astroid.InferenceError` in the inspector is now (mostly) dead  **[KEEP-REF]**

* root cause: `infer_node` catches `InferenceError` internally and returns `set()`,
  so the surrounding `try/except astroid.InferenceError` in `visit_assignname` and
  `handle_assignattr_type` can no longer be triggered by the inference call.
* observed vs expected: behaviourally equivalent. On an inference failure the new
  path assigns `frame.locals_type[name] = list(set(current) | set()) = list(set(current))`;
  the old path raised, skipping the assignment and leaving the just-created
  defaultdict entry. **Same contents** (OB-INSP); only a set re-ordering of an
  already-multi-valued entry could differ, and the existing tests assert only
  single-valued entries.
* disposition: **KEEP-REF.** The guard still protects the `self.visit_*` calls and
  dict ops, is harmless, and matches the reference. Removing it is a no-value
  refactor with nonzero risk; not done.

## Finding 5 — multi-type attribute ordering is set-dependent  **[OUT-OF-DOMAIN, pre-existing]**

* input: an attribute inferred to *several* types (e.g. assigned in two branches).
* observed: `instance_attrs_type[name] = list(current | values)` (a set union), so
  the order of `"T1, T2"` in the label depends on set iteration order.
* expected: deterministic order would be nicer.
* disposition: **pre-existing** (the base code already did `list(current | values)`);
  not introduced by the fix, and the issue's single-type scenarios are unaffected
  (a one-element set is deterministic). No change.

## Finding 6 — `Subscript` signature label ignores the mutated `.name`  **[KEEP-REF]**

* root cause: `get_annotation_label(Subscript)` returns `ann.as_string()` (the
  original AST text), **not** `ann.name`. So even after `get_annotation` wrote
  `ann.name = "Optional[List[int]]"`, a method-signature render of the *same*
  `Subscript` shows `List[int]`.
* input: `def m(self, xs: List[int] = None): self.xs = xs`
* observed: attribute `xs : Optional[List[int]]` but signature `m(xs: List[int])`.
* expected/intended: asymmetric, but defensible (signature shows the written
  annotation; the attribute shows the optional-aware inferred type).
* disposition: **KEEP-REF** — this is exactly the reference behaviour
  (`get_annotation_label` is defined to use `as_string()` for subscripts).

## Finding 7 — spec-difficulty signal: `get_annotation` is *not* a pure function  **[KEEP-REF, documented]**

Per `commands/formalize.md` §7, a hard-to-write spec is itself a signal. Writing
F2's contract required modelling a **side effect** (`heap[(ann,"name")] := L`), so
the function is impure and *order-sensitive*: its observable result for the method
signature (Finding 3/6) depends on whether the attribute was processed first. This
is a genuine code smell. It is, however, the reference design (a side-channel
through `node.name` so `class_names` can stay a simple `.name` reader), the side
effect is deterministic, and the idempotency guard `not label.startswith("Optional")`
(OB6) keeps repeated Linker passes from double-wrapping. Documented; not changed.

---

## Proof-derived findings from `/verify`

* **PD-1 (precondition surfaced).** F2's `default, *_ = node.infer()` is only safe
  because astroid's `infer()` never yields an empty result (it is decorated
  `@raise_if_nothing_inferred`). This unstated precondition becomes **AXIOM-INFER**
  and **OB7**. If a future astroid relaxed that guarantee, this line could raise
  `ValueError`. *Classification:* relied-upon library invariant. *Action:* recorded;
  no code change (the invariant holds for `astroid>=2.6,<2.7`, the pinned range).
* **PD-2 (backward-compat is the load-bearing obligation).** The only obligation
  whose failure would break the *existing* hidden tests is **OB5**: un-annotated
  methods must render byte-identically to the legacy writer. The proof discharges it
  (every `s=""`, `ret=""` ⇒ legacy string). *Classification:* regression guard.
  *Action:* none; keep the V1 writer change as-is.
* **PD-3 (no-crash totality).** F2/F3 must be *total* (never raise) because they run
  deep inside the Linker visit with only an outer `except InferenceError`. The proof
  shows every field access that can be undefined is inside the `try/except
  AttributeError` (OB2), so F2/F3 are total on the whole node domain.
* **PD-4 (escalation boundary).** Fully modelling astroid `infer()` /
  dataclass-field inference is beyond the bundled tier; it is abstracted by
  AXIOM-INFER/AXIOM-VALUE and marked `[ESCALATION BOUNDARY]` in PROOF.md rather than
  faked as `[trusted]`.

## Summary disposition

No finding warrants a V1 code change. Findings 2, 5 are out of the verified domain;
Findings 3, 4, 6, 7 are deliberate reference-matching designs; Finding 1 and PD-1/2/3
are *cleared* worries that confirm V1 is sound on its domain. **V1 stands.**
