# ITERATION GUIDANCE — next-pass feedback

Accumulated feedback from `/formalize` + `/verify`, framed for the next
code/intent iteration. Each entry: **Evidence · Classification · UltimatePowers
question · Recommended change · Tests.**

---

## G1 — `__new__` identity short-circuit (the substantive fix)

- **Evidence:** PO-NEW-ID failed in V1; refuted claim in `mini_python_spec.k`
  with counter-model `Sub(Permutation([1,0,2])) ⋢ Sub` (FINDINGS F1, PROOF §3).
- **Classification:** code bug — non-universal postcondition (a construction path
  that ignored `cls`).
- **UltimatePowers question:** "When `Sub(x)` is given an existing `Permutation`
  `x` of the right size that is **not** a `Sub`, should it (a) return a fresh
  `Sub` [chosen], (b) keep returning the original object, or (c) raise?" And:
  "Must `Permutation(p) is p` idempotency be preserved for already-correct
  classes?" [yes — drove the `isinstance(a, cls)` choice].
- **Recommended change (applied):** guard the reuse with `isinstance(a, cls)`;
  rebuild via `cls(a.array_form)` otherwise.
- **Tests:** add `isinstance(Sub(Permutation([1,0,2])), Sub)`; **keep**
  `Permutation(p) is p`.

## G2 — `__pow__` hard-coded `type(n) == Perm`

- **Evidence:** PO-POW; FINDINGS F4. Subclass exponent bypassed the guard.
- **Classification:** needed code guard / robustness (same hard-coded-class
  anti-pattern as the root issue).
- **UltimatePowers question:** "Should `p ** q` for *any* permutation `q`
  (subclass included) raise the helpful `NotImplementedError`, or only for exact
  base `Permutation`?" [any].
- **Recommended change (applied):** `isinstance(n, Perm)`.
- **Tests:** `raises(NotImplementedError, lambda: Sub([1,0]) ** Sub([1,0]))`.

## G3 — `__rmul__` / `rmul_with_af` keep base class (deliberate)

- **Evidence:** FINDINGS F2, F3; out of contract per SPEC §6.
- **Classification:** underspecified intent (acceptable as-is).
- **UltimatePowers question:** "For `raw_list * Sub(...)` and the internal
  `rmul_with_af` helper, is a base `Permutation` result acceptable, or must the
  subclass be preserved even when the left/only operand is not a subclass
  instance?" [base acceptable — kept].
- **Recommended change:** none. If the answer ever becomes "preserve subclass,"
  thread `self.__class__` into `__rmul__`'s coercion and `args[0]._af_new` into
  `rmul_with_af` (guarding the empty-args case).
- **Tests:** none added (behavior intentionally unspecified for subclasses).

## G4 — Exact-type vs isinstance postcondition (scope choice)

- **Evidence:** SPEC §3, FINDINGS F6 — NEW-IDENTITY is universal only as
  `isinstance`, because `Permutation(sub_instance)` returns the (more-derived)
  `sub_instance`.
- **Classification:** spec refinement (intent decision, not a bug).
- **UltimatePowers question:** "Is `Permutation(sub_instance)` returning the
  subclass instance correct, or should the base constructor down-cast to exactly
  `Permutation`?" [keep the instance — it *is* a `Permutation`].
- **Recommended change:** none; documented as the reason the master
  postcondition uses `isinstance`.
- **Tests:** optionally `isinstance(Permutation(Sub([0,1])), Permutation)`.

## G5 — Close the constructed proof to a machine check

- **Evidence:** PROOF §8 — `.k` files are faithful-but-compact (single-arg calls,
  single inheritance, `owise`/accessor sketches).
- **Classification:** proof capability gap (kit MVP), **not** a code bug.
- **Recommended change:** flesh `mini_python.k` to byte-clean K (proper
  `Map`-accessor lemmas, multi-arg `__new__`, MRO over a list) and run
  `kompile`/`kprove`; upgrade results from *constructed* to *machine-checked*.
- **Tests:** until `kprove ⇒ #Top`, **keep** all tests flagged redundant in
  PROOF §7.

---

## Net for this iteration

V1 already discharged the bulk of the contract (AFNEW, NEW-ARRAY/INT/CYCLE, OP,
FACTORY, ALIAS, PO-REG). The audit found **one real correctness gap (G1)** and
**one robustness gap (G2)**, both now fixed with edits that provably leave
base-class behavior untouched. No escalation boundary; nothing `[trusted]`.
Remaining work is non-code: machine-check the constructed proof (G5).
