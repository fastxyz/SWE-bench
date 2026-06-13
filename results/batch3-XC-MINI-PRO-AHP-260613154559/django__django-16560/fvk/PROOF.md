# PROOF.md — constructed correctness proof for the V1 fix (django__django-16560)

**Status: constructed, NOT machine-checked.** The MVP does not run
`kompile`/`kprove`; the run-commands are in §Reproduce. Semantics: `fvk/constraints.k`;
claims: `fvk/constraints-spec.k`; contracts: `fvk/SPEC.md`; obligations:
`fvk/PROOF_OBLIGATIONS.md`.

**Headline:** the changed code is loop-free and recursion-free. Therefore the proof
uses only **Reflexivity / Axiom(+framing) / Transitivity / Case-Analysis /
Consequence** — the **Circularity rule is not used** (no loop invariant exists or is
needed). Every verification condition is propositional or an `#Equals`/`==K` fact;
no arithmetic `[simplification]` lemma is required.

---

## 1. What is proved (plain language)

- For **every** value `C` (including `None`), constructing a constraint with
  `violation_error_code=C` yields an object whose effective code is `C`; serializing
  it with `deconstruct()` and rebuilding it (`clone()`, migrations) yields an object
  that is `==` to the original — the custom code survives the round-trip.
- When a constraint is violated, the raised `ValidationError` carries
  `code == violation_error_code` for `CheckConstraint`, `ExclusionConstraint`, and
  the expression/condition forms of `UniqueConstraint`. The field-only
  `UniqueConstraint` (no condition) deliberately keeps the legacy `"unique"` code.
- `__repr__` and `__eq__` account for the code, and — crucially — when no code is set
  the `__repr__` output is **unchanged** from before the fix, so legacy expectations
  hold.

## 2. Proof of `(INIT-CODE)` → PO1

Goal: `<k> if kwget("vec") isNotNull : self.vec = kwget("vec") ; ~> self.vec => C ...</k>`
with `<self>.Map</self>`, `<kwargs> "vec" |-> C </kwargs>`.

Symbolic execution:
1. **Axiom** `kwget("vec") => C` (key present in `<kwargs>`). Heating of the `if`
   guard (`strict(1)`) drives this.
2. **Axiom** `C isNotNull => (C =/=K null)`. The result is a symbolic Bool `B`.
3. **Case-Analysis** on `B` (`#Or`):
   - **Branch `C ≠ null`** (`B = true`): `if true : St => St`; run
     `self.vec = C ;` → `<self> .Map => (.Map)[vec <- C]`. Then evaluate the trailing
     observation `self.vec`: key present ⇒ `=> C`. Reaches `C`. ✓
   - **Branch `C = null`** (`B = false`): `if false : St => skip ;` → `<self>` stays
     `.Map`. Trailing `self.vec`: key absent ⇒ Axiom `self.vec => null`. Under the
     branch constraint `C = null`, `null = C`. Reaches `C`. ✓
4. **Consequence (Z3):** both branches land on `C`; the disjunction
   `(C ≠ null ⇒ C) ∧ (C = null ⇒ null = C)` is propositionally `C`. **VC discharged.**

∴ effective code `= C` for all `C`. ∎

## 3. Proof of `(DECON-CODE)` → PO3, PO4

Goal: `<k> if self.vec isNotNull : kwput("vec", self.vec) ; ~> kwget("vec") => C ...</k>`
with `<self> vec |-> C </self>`, `<kwargs> .Map </kwargs>`.

1. **Axiom** `self.vec => C` (present). Guard `C isNotNull => (C =/=K null)`.
2. **Case-Analysis:**
   - **`C ≠ null`:** `kwput("vec", C)` ⇒ `<kwargs> .Map => (.Map)["vec" <- C]`.
     Then `kwget("vec")`: key present ⇒ `=> C`. ✓
   - **`C = null`:** guard false ⇒ `skip` ⇒ `<kwargs>` stays `.Map`. Then
     `kwget("vec")`: key **absent** ⇒ Axiom `=> null`; under `C = null`, `= C`. ✓
     → **PO4:** in this branch `<kwargs>` is `.Map`, i.e. *no* `"vec"` key was added,
     so the kwargs equal the pre-fix output. ✓
3. **Consequence (Z3):** lands on `C` in both branches. **VC discharged.** ∎

## 4. Proof of `(ROUNDTRIP-CODE)` → PO5, PO6 (the central obligation)

`clone(c) = type(c)(**c.deconstruct()[2])`. Compose by **Transitivity**:

```
  <self vec|->C>  --(DECON-CODE)-->  <kwargs with get("vec")=C>
                  --(INIT-CODE)  -->  fresh <self> with effective vec = C
```

- Stage A = §3 produces `<kwargs>` s.t. `kwget("vec") = C`.
- Stage B = §2 consumes exactly `kwget("vec")` and produces a fresh `self` whose
  effective `vec = C`.
- The composition closes **iff** the emit key, the consume key, and the `__eq__`
  attribute are the literal same name — they are all `violation_error_code`
  (`"vec"`). → PO5: `clone(c).vec == c.vec`. ✓
- **PO6:** the other constructor fields (`name`, `check`, `fields`, `condition`,
  `expressions`, …, `violation_error_message`) already round-trip in baseline Django
  (unchanged code), and `__eq__` (C5/`(EQ-CODE)`) now also compares the code; since
  every conjunct of `__eq__` is preserved by the round-trip, `clone(c) == c`. ✓

**Counterfactual (benefit #2).** If `deconstruct()` did *not* emit the code while
`__eq__` *did* compare it, Stage A would yield `kwget("vec") = null` for a
custom-code object, Stage B would build `vec = null ≠ C`, and the round-trip goal
would **fail to close** — exactly the bug signal. V1 closes it. (FINDINGS F3/PV2.)

## 5. Proof of `(VALIDATE-CODE)` → PO9

Goal: `<k> raiseErr(M, self.vec) ; => .K </k>`, `<self> vec |-> C </self>`,
`<error> null => errpair(M, C) </error>`.

1. `seqstrict` evaluates the args: `M => M` (value), `self.vec => C` (Axiom, present).
2. **Axiom** `raiseErr(M, C) ; ~> _ => .K` with `<error> null => errpair(M, C)`.
   The recorded code is `C`. ✓

This is the local code-propagation fact for the four in-domain raise sites. The
message argument `M = get_violation_error_message()` is unchanged by the fix.
**Boundary (PV3):** Python exception propagation / `try-except FieldError` / the DB
query are *not* modeled — see §Residual risk. ∎

## 6. Proof of `(EQ-CODE)` → PO7

Goal: `<k> (self.vec) === C2 => false ...</k>`, `<self> vec |-> C1 </self>`,
`requires C1 =/=K C2`.

1. **Axiom** `self.vec => C1`. 2. **Axiom** `C1 === C2 => (C1 ==K C2)`.
3. **Consequence:** under `C1 =/=K C2`, `C1 ==K C2` reduces to `false`. ✓

So the `violation_error_code` conjunct in each subclass `__eq__` is `false` when the
codes differ ⇒ the whole `and`-chain is `false` ⇒ the constraints are unequal. ∎

## 7. Read-off obligations (PO2, PO8, PO10–PO14)

These are structural arguments over the literal (unchanged-or-additive) source — no
symbolic execution needed:

- **PO2:** the new `if violation_error_code is not None: self.violation_error_code =
  ...` is inserted *before* the unchanged message block and writes a *different*
  attribute → message handling identical.
- **PO11/PO12:** the repr format strings gained one slot that is `""` exactly when
  `violation_error_code is None`; thus `None` ⇒ identical legacy output, non-`None`
  ⇒ `" violation_error_code=%r"` before the message slot. (Verified by inspection of
  all three `__repr__`s.)
- **PO10/F5:** `UniqueConstraint.validate` fields-without-condition branch still calls
  `instance.unique_error_message(...)` (unchanged) → legacy `"unique"` code, by
  design.
- **PO13:** `CheckConstraint.deconstruct`, `UniqueConstraint.deconstruct`,
  `ExclusionConstraint.deconstruct` each call `super().deconstruct()` then only add
  keys → they inherit the code emission proved in §3.
- **PO14:** enumeration in `PROOF_OBLIGATIONS.md` — 3/3 subclasses, 5/5 in-domain
  raise sites updated, 1 deliberate exclusion.

## 8. Residual risk / trusted base

- **Partial correctness only** (kit default). Immaterial here: the changed code is
  straight-line with no loops/recursion, so it terminates trivially.
- **Mini-X fidelity.** `constraints.k` models a *fragment*. In particular `raiseErr`
  abstracts Python exceptions (PV3): the proof establishes the raised error's `code`
  binding, not exception propagation through `full_clean()`/the DB layer. Those are
  unchanged by the fix.
- **Constructed, not machine-checked.** A `#Top` from `kprove` would upgrade this
  from *constructed* to *machine-verified*.
- **Oracle trust:** Z3 for the propositional/`==K` VCs; the K reachability metatheory.

## 9. Test-redundancy recommendation (benefit #1) — conditioned on machine-checking

Mapping the verified contracts onto unit tests (recommendation only; **never
auto-delete**; run the §Reproduce commands first):

- **Subsumed once machine-checked** (single in-domain input/output points entailed by
  a universal contract):
  - a test asserting `BaseConstraint(name=..., violation_error_code="c").
    get_violation_error_message()`-style code round-trips via `deconstruct`/`clone`
    for one literal code — subsumed by PO5/PO6 (holds for all `C`).
  - a `repr` test for one custom-code value — subsumed by PO12.
- **Keep (NOT subsumed):**
  - the field-only `UniqueConstraint`/`unique_error_message` code test — **out of
    C4's domain** (PO10/F5); pins the deliberate legacy behavior.
  - any test that a custom code does **not** leak into the field-only unique path.
  - existing `test_repr*` with **no** code set — pins PO11 (backward-compat), cheap,
    keep.
  - integration tests exercising `Model.full_clean()` end-to-end — proof covers the
    unit, not the wiring (PV3 boundary).

Estimated CI saving is negligible (a handful of micro-assertions) and the honest
recommendation is to **keep all current tests** until `kprove` returns `#Top`.

## Reproduce the machine check

```sh
kompile fvk/constraints.k --backend haskell          # compile the fragment semantics
kast    --backend haskell fvk/constraints-spec.k     # (optional) confirm claims parse
kprove  fvk/constraints-spec.k                        # expected: #Top (all 5 claims proved)
```
Expected outcome (reasoned, not executed): each claim reduces by the steps in
§2–§6 to `#Top`. If `kprove` instead returned a residual on `(ROUNDTRIP-CODE)`, that
would signal an emit/consume key mismatch — the precise bug F3 guards against.
