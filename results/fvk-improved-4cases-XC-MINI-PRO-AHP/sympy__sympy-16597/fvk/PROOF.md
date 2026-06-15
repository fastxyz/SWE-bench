# PROOF.md — sympy__sympy-16597

**Constructed, NOT machine-checked.** Symbolic execution of the claims in
[`assume-spec.k`](assume-spec.k) against [`mini-assume.k`](mini-assume.k). Each
step names the firing rule (by its comment tag in `mini-assume.k`). The closure
is monotone, so every step only *adds* a binding; ordering is immaterial
(confluence, §3).

Notation: a state is the `<facts>` map; `+X:b` means "add binding `X ↦ b`".

---

## §1 — Positive obligations PO1–PO3

### (EVEN-FINITE) — PO1
Start `{even:T}`, driver `close`:

| step | rule | result |
|------|------|--------|
| 1 | `even -> integer`  | `{even:T, integer:T}` |
| 2 | `integer -> rational` | `+rational:T` |
| 3 | `rational -> real` | `+real:T` |
| 4 | **`rational -> finite`** (the FIX) | `+finite:T` |

No further rule matches (every consequent is present; no `*=false` binding exists
to trigger a contrapositive or backward rule). **Fixpoint** =
`{even:T, integer:T, rational:T, real:T, finite:T}`, which **contains `finite:T`**.
∎ matches the (EVEN-FINITE) RHS.

### (INTEGER-FINITE) — PO2
Start `{integer:T}`: step 2→3→4 above give
`{integer:T, rational:T, real:T, finite:T}`. Contains `finite:T`. ∎

### (RATIONAL-FINITE) — PO3
Start `{rational:T}`: steps 3,4 give `{rational:T, real:T, finite:T}`. ∎

These three are the **direct realization of I1–I3**. Pre-fix, rule 4 does not
exist, so from `{even:T}` the closure halts at
`{even:T, integer:T, rational:T, real:T}` with **no `finite` binding** → matches
the reported bug `is_finite -> None`. The fix adds exactly the missing edge.

---

## §2 — Consistency of S.Infinity (PO4, PO6, PO8)

Start from oo's declared base `{positive:T, infinite:T}` (numbers.py:2658-2659):

| step | rule | result (additions) |
|------|------|--------------------|
| 1 | `positive -> nonnegative` | `+nonnegative:T` |
| 2 | `nonnegative -> real` | `+real:T` |
| 3 | `infinite -> finite=false` | `+finite:F` |
| 4 | **contrapositive `finite=F -> rational=F`** (from FIX) | `+rational:F` |
| 5 | `rational=F -> integer=F` | `+integer:F` |
| 6 | `integer=F -> even=F` | `+even:F` |
| 7 | `integer=F -> odd=F` | `+odd:F` |
| 8 | `real=T & rational=F -> irrational=T` | `+irrational:T` |
| 9 | `real=T & integer=F -> noninteger=T` | `+noninteger:T` |

**Fixpoint** =
`{positive:T, infinite:T, nonnegative:T, real:T, finite:F, rational:F,
integer:F, even:F, odd:F, irrational:T, noninteger:T}`.

**Clash check (consistency).** The five clash rules of `mini-assume.k`:
- `rational:T & finite:F` — needs `rational:T`; have `rational:F` → no.
- `rational:T & real:F` — `rational:F` → no.
- `integer:T & rational:F` — `integer:F` → no.
- `even:T & integer:F` — `even:F` → no.
- `infinite:T & finite:T` — `finite:F` → no.

No clash rule matches ⇒ the driver stays `close`, not `#inconsistent`. **oo
closes consistently.** ∎ matches (OO-CONSISTENT).

The same trace with `negative` in place of `positive` discharges `-oo`. `zoo`
(`{complex:T, infinite:T, real:F}`): `finite:F` then `finite=F→rational=F`;
`irrational == real & !rational` needs `real:T` but `real:F` ⇒ `irrational`
stays/`F`; no clash. `nan` (`{real:None, rational:None, finite:None}`): no
antecedent is `True/False`, closure is empty, trivially consistent. (PO6.)

**On `irrational:T` (step 8) — PO8/F1.** This is *not* candidate-invented: it is
the unchanged biconditional `irrational == real & !rational` applied to the
unchanged `oo.is_real=T`. It is entailed by the glossary definition (E7), hence
definition-faithful. See the side-by-side in §4.

---

## §3 — Termination of the closure (PO5)

Every rule in `mini-assume.k` either (a) adds a binding for a key not already
present (positive/contrapositive/backward rules — guarded by `notBool(K
in_keys REST)`), or (b) rewrites `close → #inconsistent` and stops. The atom set
{even, odd, integer, rational, real, finite, infinite, irrational, noninteger,
positive, nonnegative} is finite (size 11 in the fragment; ~30 in the full
engine). Case (a) strictly increases `size(facts)`, bounded by the atom count;
case (b) is terminal. Hence the closure halts after ≤ |atoms| steps. This mirrors
`FactKB.deduce_all_facts`, whose precomputed `full_implications` make the real
closure a single bounded pass. **Confluence:** the rules are a monotone Horn-style
system; the fixpoint (set of derivable bindings) is independent of firing order,
so the `[all-path]` claims hold for every schedule. ∎

---

## §4 — Side-by-side: why `finite` attaches to `rational`, not `real`/`complex` (PO7, F1)

`verify.md` requires "forced" design choices to be proved by falsifying the named
alternative, not asserted. Two alternatives, each run from oo's base:

**Alternative A = V1: `rational -> real & finite`.** §2 trace ⇒ consistent
fixpoint; `oo.is_finite=F` (correct). ✔

**Alternative R: `real -> finite` (the hint's warned-against option, E5).**

| step | rule | result |
|------|------|--------|
| 1-2 | positive→nonnegative→real | `+real:T` |
| 3 | **`real -> finite`** (alt) | `+finite:T` |
| 4 | `infinite -> finite` wants `finite:F`, but `finite:T` present | clash rule `infinite:T & finite:T` → **`#inconsistent`** |

⇒ oo (and -oo) **fail to construct**. Matches (CLASH-DETECTED). Alternative R is
**unsound** — it violates I5. ✗

**Alternative C: `complex -> finite`.** `zoo` declares `complex:T, infinite:T`
(numbers.py:3239,3242). `complex→finite` ⇒ `finite:T`; `infinite→finite` wants
`finite:F` ⇒ clash `infinite:T & finite:T` → `#inconsistent`. `zoo` fails to
construct. ✗

**Conclusion (PO7).** `finite` can only be safely attached at a node that **no
infinite object satisfies**. `oo`/`-oo` are `real` and `zoo` is `complex`, so
`real`/`complex` are excluded. None of `oo`/`-oo`/`zoo` is `rational` (indeed V1
*derives* `rational:F` for them), so `rational` is the correct, and the lowest-in-
the-hierarchy, safe attachment point. V1's placement is **forced** among
single-edge fixes. ✔

**Alternative B for `irrational` (F1).** Add `irrational == real & !rational &
finite` to keep `oo.is_irrational=F`. Two-column on oo:

| obligation | A (V1) | B |
|---|---|---|
| even/integer/rational ⟹ finite (I1–I3) | ✔ | ✔ |
| consistency (I5) | ✔ | ✔ |
| `oo.is_irrational` | `True` | `False` (also a change from pre-fix `None`) |
| matches glossary `irrational = real ∧ ¬rational` (I6/E7) | ✔ | ✗ (adds `finite` not in the definition) |
| coherent without also changing `real` (I4) | ✔ | ✗ (only sensible if `real ⟹ finite`, which I4 forbids) |
| public-intent evidence requesting it | n/a (no change) | **none** |

Both satisfy I1–I3 and I5 ⇒ `oo.is_irrational` is **under-determined**, never
"forced." B additionally **fails I6 and presupposes the forbidden I4 change**, and
has zero supporting evidence. Therefore A (V1, no `irrational` edit) is selected
and B rejected on positive grounds. ∎

---

## §5 — Import-time consistency of concrete classes (PO6)

Classes with explicit positive integer/rational facts — `Integer`, `Rational`,
`Idx`, `KroneckerDelta`, `LeviCivita` — are all genuinely finite; the newly
deduced `finite:T` agrees with the inherited `Number._eval_is_finite → True`
(numbers.py:610), so `default_assumptions` for each closes without clash. The
only classes with `is_infinite=True` are the three infinity singletons (grep:
`is_infinite = True` ⇒ numbers.py:2659/2883/3239), none of which declares
integer/rational; §2/§4 show they close consistently. Hence no
`InconsistentAssumptions` at import. ∎

---

## §6 — Benefits & test impact

### Benefit 2 (bugs found) — does not depend on machine-checking
- **B0** (root bug) confirmed and fixed.
- **F1–F5** surfaced and classified (see `FINDINGS.md`): F1/F2 correct
  consequences; F3/F4/F5 pre-existing, out-of-scope.

### Benefit 1 (test redundancy) — CONDITIONED ON MACHINE-CHECKING
Once `kprove` returns `#Top`:
- **Subsumed by the proof** (in-domain points of PO1–PO3): any unit test of the
  form `Symbol(..., even/integer/rational=True).is_finite is True` is entailed by
  (EVEN/INTEGER/RATIONAL-FINITE). *Recommendation only* — keep until checked.
- **Must keep:** `test_infinity`/`test_neg_infinity`/`test_zoo`/`test_nan` — they
  pin the *consistency boundary* (PO4/PO6) the proof relies on; the rows that
  encode the pre-fix `oo` values (E8) are SUSPECT and will need updating to the
  §2 fixpoint, **not** deletion. Termination/integration tests: keep.
- **Do NOT auto-delete anything** (Honesty gate). I also did **not** modify any
  test file (task constraint).

---

## §7 — Reproduce the machine check

```sh
kompile mini-assume.k --backend haskell          # compile the fragment semantics
kast    --backend haskell assume-spec.k          # (optional) confirm claims parse
kprove  assume-spec.k                            # expected: #Top  (all 5 claims)
```

**Residual trusted base:** adequacy of the mini-assume fragment vs the full
`facts.py` engine (the fragment models the rule-closure logic, not the
alpha/beta-network *implementation*); the K reachability metatheory and `kprove`;
the Bool/Map oracle. Result is **constructed, not machine-checked** until `kprove`
returns `#Top`.

## Verdict

PO1–PO8 discharged; adequacy gate AG1–AG3 pass. **V1 stands unchanged.**
