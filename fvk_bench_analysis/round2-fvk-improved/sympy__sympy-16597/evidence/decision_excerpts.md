# KEY ARTIFACT + TRANSCRIPT EXCERPTS — round-2 fvk, sympy__sympy-16597

Shows the wrong/partial decision under the HARDENED materials (submodule @ 275cd44).

---

## A. The agent FOLLOWED the new "promote a named fix" guidance for Axis A (irrational) — but then re-rejected it on a CONSTRUCTED (and false) ground

`reports/fvk_notes.md` Decision 2 (`:34-57`):
> "My V1 notes called this a 'debatable/accepted consequence.' `formalize.md` §7 flags exactly
> that kind of phrase as a smell to investigate, so I promoted the fix-it alternative (**B**:
> `irrational == real & !rational & finite`) to a falsifiable hypothesis and ran it side-by-side:
>  - Both V1 and B satisfy I1–I3 and I5 ⇒ the `oo.is_irrational` value is **under-determined** ...
>  - B is nonetheless **rejected on positive grounds**: it contradicts the glossary definition
>    `irrational == real & !rational` (I6/E7) by inserting `finite`, and is only coherent if
>    `real ⟹ finite` — the very change I4/E5 forbid. ... B is a local hack papering over the real
>    root cause (extended-real `real`)."

`fvk/PROOF.md` §4 two-column table (`:134-149`) — the load-bearing logical error:
> | coherent without also changing `real` (I4) | A (V1) ✔ | B ✗ (only sensible if `real ⟹ finite`, which I4 forbids) |
>
> "B additionally **fails I6 and presupposes the forbidden I4 change** ... Therefore A (V1, no
> `irrational` edit) is selected and B rejected on positive grounds. ∎"

**This is FALSE and is contradicted by the gold patch.** B = `irrational == real & !rational & finite`
does NOT require `real ⟹ finite`. With `& finite` added, the rule simply does not fire for `oo`
(because `oo.is_finite=False`), so `oo.is_irrational` becomes False — no clash, no `real` change.
The gold patch makes exactly this edit and is consistent. The agent's own `.k` semantics would have
shown this had it added the `finite` premise to the rule (see C).

---

## B. The agent NEVER considered Axis B (algebraic / transcendental -> finite) — the axis that actually fails all 3 tests

Transcript grep (results/.../transcripts/fvk.jsonl.gz):
- assistant text proposing `algebraic -> finite` / `transcendental -> finite`:  **ZERO matches.**
- Files Read: `core/assumptions.py`, `core/facts.py`, `core/numbers.py`, `tests/test_assumptions.py`,
  `elementary/integers.py`, + the FVK materials.
- `ask.py` opened: **False**.  `ask_generated.py` opened: **False**.  (Dual engine never inspected.)

`fvk/mini-assume.k` models only `{even,odd,integer,rational,real,finite,infinite,irrational,
noninteger,positive,nonnegative}` — **no `algebraic`, no `transcendental`, no `complex` atoms.**
`fvk/FINDINGS.md` F1/F2/F5 discuss only `irrational`/`noninteger`. Axis B is entirely unrepresented
in spec, claims, proof, and findings.

---

## C. The buggy biconditional is still blessed as a PROVED postcondition (tell #9 persists)

`fvk/mini-assume.k:92-96` — the UNFIXED rule (no `finite` premise), so it fires for `oo`:
```
// irrational == real & !rational   (backward direction: real & !rational -> irrational)
rule <k> close </k>
     <facts> real |-> true rational |-> false REST
          => real |-> true rational |-> false irrational |-> true REST </facts>
  requires notBool(irrational in_keys(REST))
```

`fvk/assume-spec.k:80` (OO-CONSISTENT claim) asserts the buggy value as the proved fixpoint:
```
        irrational  |-> true        // <- gold test demands oo.is_irrational is False
```
`fvk/PROOF.md` §2 step 8 + §4 "discharge" this. (All other oo conjuncts match gold; only this one is wrong.)

---

## D. THE SMOKING GUN — the agent read the test file at the BASE commit (pre-test-patch), so it saw the LEGACY assertions

Transcript msg 38 (a `Read` tool_result of `sympy/core/tests/test_assumptions.py`, lines 98+):
```
103    assert oo.is_algebraic is None          <- PRE-FIX value the agent SAW
       assert oo.is_transcendental is None
       assert oo.is_irrational is None
       assert oo.is_finite is False
```
The gold **test_patch** flips line 103 to `assert oo.is_algebraic is False` — but that patch is applied
only at EVAL time, AFTER the agent finishes. The agent therefore reasoned "the tests say oo.is_algebraic
/is_irrational is None; my fix must stay consistent with that (or I mark it SUSPECT and accept the
definitional consequence)" — and never learned the hidden tests demand `False`. This is the
no-execution + hidden-test blind spot; the hardening (mark SUSPECT, promote named fix) mitigated it
for Axis A's `irrational` row but did NOT cause the agent to invent the Axis-B `algebraic`/
`transcendental` flips, which have no corresponding "smell" in V1's output and no named alternative.

---

## E. The agent correctly NAMED the true root cause — then put the whole fix family out of scope

`fvk/ITERATION_GUIDANCE.md:27-32` (UltimatePowers question #1):
> "**Extended reals (the real root cause).** Should `S.Infinity.is_real` remain `True`, or should
> SymPy introduce a separate `extended_real` so that `real ⟹ finite`? Resolving this *upstream* would
> ... make `oo.is_irrational` `False` honestly. This is the principled long-term fix ... and is
> **outside this issue**."

The agent built a FALSE DICHOTOMY: (a) the 1-line V1 edit, or (b) a large `extended_real` redesign.
It never saw option (c) = the gold patch = add `& finite` conjuncts to the four rational/algebraic/
transcendental/irrational rules, which needs NO `extended_real` redesign and NO change to `real`.

---

## F. Final assistant summary (transcript msg 211) — the verdict it shipped

> "The FVK audit **confirms V1 unchanged** ... the 'fix it' alternative (`irrational == real &
> !rational & finite`) is rejected on positive grounds because it contradicts the documented definition
> (I6) and presupposes the very `real ⟹ finite` change the issue forbids (I4). ... no source change
> beyond V1 is justified."
