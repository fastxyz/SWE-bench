# PROOF — pytest-dev__pytest-10356 (constructed, NOT machine-checked)

This constructs the correctness proof of the claims in [`SPEC.md`](SPEC.md) against the
`mini-python-marks.k` fragment, discharges the verification conditions, composes the
function contract, and then lifts the result to the four source-level contracts and the
proof obligations in [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

**Honesty gate.** No K toolchain was run (no execution environment). Every result below
is **constructed, not machine-checked**. A `#Top` from the emitted `kprove` command
(SPEC §7) is what would upgrade this to machine-verified. The *Findings* in
[`FINDINGS.md`](FINDINGS.md) do **not** depend on machine-checking and stand today.

---

## 1. What is proved, in one sentence

For every class `obj` whose MRO lists each ancestor once,
`get_unpacked_marks(obj, consider_mro=True)` returns
`flatten([own(c) for c in reversed(obj.__mro__)])` — the marks of *every* class in the
MRO, each once, base-class-first — and `store_mark` preserves the "own-marks only"
invariant that keeps this duplication-free.

---

## 2. Proof of the loop circularity `(LOOP)`

Claim (SPEC §5): from a store with `mark_list |-> ACC`, executing
`#forLoop(item, REST, BODY)` reaches `.K` with `mark_list |-> ACC flatten(REST)`,
generalized over `ACC : List` and `REST : List`. `BODY` is
`if isinstance(item,list): { mark_list.extend(item) } else: { mark_list.append(item) }`.

K treats every claim in the module as a coinduction hypothesis; `(LOOP)` may assume
itself after **≥ 1 genuine step** (guardedness). Proceed by the structure of `REST`.

**Case `REST = .List` (exit branch).**
`#forLoop(item, .List, BODY) => .K` by the empty-`forLoop` rule — one genuine step.
Store unchanged: `mark_list |-> ACC`. Postcondition requires `mark_list |-> ACC
flatten(.List)`. Since `flatten(.List) => .List` and `ACC .List = ACC` (List unit),
the goal is `ACC = ACC`. **Discharged** (VC-UNIT). ✔

**Case `REST = ListItem(V) REST'` (body-taken branch).**
The rule
`#forLoop(X, ListItem(V) REST', B) => X = V ~> B ~> #forLoop(X, REST', B)` fires — the
genuine `=>⁺` step that earns the coinduction hypothesis. Then:
1. `item = V` sets `item |-> V`.
2. `B` runs `if isinstance(item, list): … else: …`. Sub-case split (Case Analysis, `#Or`):
   - **`V : List`** ⇒ `isinstance(V, list) => true` ⇒ take `mark_list.extend(item)` ⇒
     `mark_list |-> ACC V` (List concat). Set `ACC₁ := ACC V`.
   - **`V : MarkV`** ⇒ `isinstance(V, list) => false` ⇒ take `mark_list.append(item)` ⇒
     `mark_list |-> ACC ListItem(V)`. Set `ACC₁ := ACC ListItem(V)`.
3. Now the continuation is `#forLoop(item, REST', B)` with `mark_list |-> ACC₁`.
   **Invoke the `(LOOP)` circularity** on the shifted state `{ACC := ACC₁, REST := REST'}`
   (legal: a genuine step was taken). It yields `mark_list |-> ACC₁ flatten(REST')`.

   - List sub-case: end state `ACC V flatten(REST')`. Target
     `ACC flatten(ListItem(V) REST') = ACC (V flatten(REST'))`. VC:
     `(ACC V) flatten(REST') = ACC (V flatten(REST'))` — **associativity of `_List_`**
     (VC-ASSOC). ✔
   - Mark sub-case: end state `ACC ListItem(V) flatten(REST')`. Target
     `ACC (ListItem(V) flatten(REST'))`. Same associativity VC. ✔

Both branches land on `mark_list |-> ACC flatten(REST)`. `(LOOP)` holds. ∎

### Verification conditions for `(LOOP)`
- **VC-UNIT:** `L .List = L`. K `LIST` unit law — structural, discharged directly.
- **VC-ASSOC:** `(L1 L2) L3 = L1 (L2 L3)`. K `LIST` concatenation (`_List_`) is
  associative **by construction**, so this is discharged by the builtin theory; no
  custom `[simplification]` is even strictly required (one may be added as
  `rule (L1 L2) L3 => L1 (L2 L3) [simplification]` to guide the prover).

> **Contrast with the sum example.** The sum loop needed a truncating-division evenness
> lemma (VC-EXACT) because it divided a *symbolic product*. Here the postcondition is a
> **concatenation**, and concatenation is associative-with-unit in K's `List` natively.
> So the VC tier needed is strictly *weaker* than the bundled sum example — no nonlinear
> arithmetic, no `/Int`. This is a positive signal: the spec is clean.

---

## 3. Composition: the function contract `(GUC)`

Compose by Transitivity over the semantics:

1. `def guc(mark_lists): BODY₀` files the function: `<funcs> guc |-> def …`. (rule `def`)
2. `guc(MLS)` — the **call** step binds the parameter in a fresh scope:
   `<store> mark_lists |-> MLS`, current continuation pushed on `<stack>`. (rule call)
   This is the genuine step for the function-level argument.
3. `mark_list = []` ⇒ `<store> … mark_list |-> .List`. (empty-list + assignment rules)
4. `for item in mark_lists : BODY` ⇒ `mark_list` is read as `MLS`, rewrites to
   `#forLoop(item, MLS, BODY)`. (for rule + name lookup)
5. **Apply `(LOOP)` as a lemma** at `{ACC := .List, REST := MLS}` (its precondition is
   vacuous). Result: `<store> mark_list |-> .List flatten(MLS) = flatten(MLS)`.
6. `return mark_list` reads `flatten(MLS)`, pops the frame, delivers it to the caller's
   continuation. (return rule)

Net: `def guc … ~> guc(MLS) => flatten(MLS)`. Contract `(GUC)` holds. ∎

---

## 4. Lift to the source-level contracts (SPEC §6)

- **C-CLASS-MRO / PO1, PO2, PO3.** Instantiate `MLS := [own(c) for c in
  reversed(mro(obj))]`. `(GUC)` gives `result = flatten(MLS)`.
  - *PO1 completeness*: `flatten` concatenates every element of `MLS`; `MLS` covers the
    whole MRO ⇒ every `own(c)` is in `result`.
  - *PO2 no-dup*: MRO-DISTINCT ⇒ each `c` appears once in `MLS`; `own(c)` reads only
    `c.__dict__` ⇒ concatenated once.
  - *PO3 order*: `reversed(mro)` is base-first; single-inheritance trace matches baseline
    `[a, b]` (PROOF_OBLIGATIONS PO3). The multiple-inheritance order for `C(A,B)` is
    `[b, a, c]` — the **unique** base-first order compatible with single inheritance.
- **C-CLASS-OWN.** `consider_mro=False` ⇒ `MLS = [own(obj)]`; one `extend` iteration of
  `(LOOP)` ⇒ `result = own(obj)`.
- **C-NONCLASS / PO5.** Case `¬isinstance(obj,type)`: the `else` branch equals the
  baseline algorithm verbatim (inverted `isinstance` test, same effect); behavior
  preserved by inspection.
- **C-STORE / PO4.** `store_mark` uses C-CLASS-OWN, so `own(obj)_after =
  own(obj)_before ++ [m]`, no inherited mark copied. This invariant is *necessary* for
  PO2 to keep holding across repeated collection (PROOF_OBLIGATIONS PO4 forcing
  argument).
- **PO6 type safety, PO7 termination, PO8 call-site compat**: PROOF_OBLIGATIONS.

All eight obligations are **discharged (constructed)**. The audit finds **no defect** in
V1; it instead *pins* two design choices (PO3 forces `reversed`, PO4 forces
`consider_mro=False`) and confirms V1 made both.

---

## 5. Residual risk

- **Partial vs total.** PO7 actually gives *total* termination (finite MRO, no
  recursion), stronger than the kit's default partial correctness — there is no
  unbounded loop to worry about.
- **Trusted base.** MRO-DISTINCT (Python C3 guarantee); adequacy of the mini-Python
  fragment vs CPython; the reachability metatheory and `kprove` (not run);
  `normalize_mark_list`/`Mark` unchanged.
- **Constructed, not machine-checked.** Run SPEC §7's `kompile`/`kprove` to confirm
  `#Top`.
- **Intentional behavior changes** (not bugs, but intent-dependent) are catalogued as
  FINDINGS F5 (subclass body `pytestmark=[...]` now *merges* rather than *overrides*)
  and F6 (a metaclass `pytestmark` *property* is bypassed by the `__dict__` read). These
  are consequences of the maintainer-confirmed "marks transfer with the MRO" intent and
  of the dedup design; they are surfaced for the next intent pass, not silently
  accepted.

---

## 6. Test-redundancy recommendation (benefit 1)

**Conditioned on machine-checking** (run `kprove` first; until then, keep all tests).
The project's own test suite is **fixed and hidden and must not be modified** for this
task, so this is advisory only and **nothing is removed**.

*If* `(GUC)` machine-checks, these *kinds* of assertions become subsumed by the proved
contract (each a single in-domain point of `flatten([own(c) for c in reversed(mro)])`):
- "`C(A,B)` with `@a`,`@b`,`@c` ⇒ marks include a, b, c" — entailed by PO1.
- "diamond `Base◅Foo,Bar◅T` ⇒ `Base`'s mark appears once" — entailed by PO2.
- "single inheritance `B(A)` ⇒ `[a, b]` in order" — entailed by PO3.

**Always keep** (outside the verified contract):
- the **metaclass-property** scenario from the issue (F6 — out of the verified domain),
- any test pinning **subclass-body `pytestmark` override** semantics (F5 — behavior
  changed),
- module-level and function-level marker tests (different code path, C-NONCLASS),
- integration/collection-ordering and termination/performance tests.

---

## 7. The two plain-language payoffs

- **Benefit 2 (bugs/corner cases), available now:** writing the spec made the
  *coupling* explicit — walking the MRO at read time is sound **only because** writes
  are own-only. It also flushed out two intent-dependent behavior changes (F5, F6) and
  confirmed the order question has a forced answer (F2/PO3). See FINDINGS.
- **Benefit 1 (fewer tests):** once `(GUC)` is machine-checked, point-wise
  marks-inheritance tests within the verified domain are subsumed; the recommendation
  above lists what would then be redundant vs. what to keep — recommendation-only,
  nothing deleted.
