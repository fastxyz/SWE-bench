# SPEC.md — FVK specification for sympy__sympy-16597

**Target code.** `sympy/core/assumptions.py :: _assume_rules` (the rule graph) as
deduced by `sympy/core/facts.py` (the `FactRules`/`FactKB` forward-chaining
closure). The "function" under audit is the **deductive closure** of a symbol's
assumption knowledge base: given some input facts (e.g. `even=True`), compute all
derivable `is_*` values, or raise `InconsistentAssumptions`.

**V1 change under audit.** One rule edited:
`'rational -> real'` → `'rational -> real & finite'`.

Formal core: [`mini-assume.k`](mini-assume.k) (semantics fragment),
[`assume-spec.k`](assume-spec.k) (claims). Proof: [`PROOF.md`](PROOF.md).

---

## 1. INTENT_SPEC (intent-only; written before trusting any candidate/legacy value)

Required behaviors, derived only from the public issue text, the public hint
thread, and the module's own glossary docstring — **not** from what the code
currently returns.

- **I1 — even ⟹ finite.** A symbol declared `even=True` must have `is_finite is
  True`. Source: issue title "a.is_even does not imply a.is_finite" + body "I
  would expect that a number should be finite before it can be even."
- **I2 — integer ⟹ finite.** A symbol declared `integer=True` must have
  `is_finite is True`. Source: issue follow-up `i = Symbol('i', integer=True);
  print(i.is_finite) -> None`, reported as the same bug.
- **I3 — rational ⟹ finite (and the whole integer tower).** Source: hint
  "Perhaps the second rule `'rational -> real'` should be extended to `'rational
  -> real & finite'`" and "it should be safe to add `finite` to `rational`."
  Implies the fix lives at `rational`, so `even, odd, integer, rational, prime,
  composite, zero` all become finite.
- **I4 — `real` keeps its extended meaning.** `finite` must **not** be added to
  `real`. Source: hint "`real` should already imply `finite` but currently its
  meaning is `extended_real`, and adding `finite` to `real` would probably break
  a lot of code." Default-domain corollary: `S.Infinity`/`S.NegativeInfinity`
  keep `is_real is True`.
- **I5 — consistency preserved.** The change must not make any existing object
  raise `InconsistentAssumptions`; in particular the singletons `oo`, `-oo`,
  `zoo`, `nan` must still construct. Source: default-domain convention (a fact
  engine must stay consistent) + public tests `test_infinity`, `test_zoo`,
  `test_nan` exercising those singletons.
- **I6 — definitions stay faithful.** No assumption should be given an
  implication that contradicts its glossary definition in the module docstring
  (`real`, `irrational`, `finite`, ... ). Source: the docstring glossary +
  hint-thread request for "an explanation defining the meanings of the different
  is_* attributes."

Observed (legacy) behavior recorded only to check later, never as expected:
pre-fix `Symbol('m', even=True).is_finite` is `None`; pre-fix `oo.is_rational`,
`oo.is_irrational`, `oo.is_integer`, `oo.is_even` are all `None`.

---

## 2. PUBLIC_EVIDENCE_LEDGER

| # | Source | Quoted evidence | Semantic obligation | Status |
|---|--------|-----------------|---------------------|--------|
| E1 | prompt | "a.is_even does not imply a.is_finite" / "a number should be finite before it can be even" | even ⟹ finite | encoded (EVEN-FINITE) |
| E2 | prompt | "i = Symbol('i', integer=True) ... print(i.is_finite) -> None" | integer ⟹ finite | encoded (INTEGER-FINITE) |
| E3 | prompt (hint) | "the second rule 'rational -> real' should be extended to 'rational -> real & finite'" | attach finite at `rational` | encoded (RATIONAL-FINITE); is the literal V1 edit |
| E4 | prompt (hint) | "I think that it should be safe to add finite to rational" | rational ⟹ finite is the intended, scoped fix | encoded; bounds scope |
| E5 | prompt (hint) | "adding finite to real would probably break a lot of code" | do NOT add finite to real | encoded as rejected alt; (CLASH-DETECTED) |
| E6 | code | `numbers.py`: Infinity `is_positive=True,is_infinite=True`; NegativeInfinity `is_negative,is_infinite`; ComplexInfinity `is_complex=True,is_infinite=True` | these objects are infinite ⟹ they must not be forced finite | (OO-CONSISTENT), (CLASH-DETECTED) |
| E7 | code/docstring | `irrational == real & !rational`; glossary "irrational: object value cannot be represented exactly by Rational" + Wikipedia "irrational number" (real, not rational) | irrational is, by definition, `real & !rational`; given `oo.is_real=True`, `oo.is_rational=False` ⟹ `oo.is_irrational=True` follows | (OO-CONSISTENT); see F1 |
| E8 | public-test | `test_assumptions.py:108` `assert oo.is_irrational is None`; `:101,102,114,115` oo integer/rational/even/odd `is None` | **SUSPECT (legacy)** — these encode the *pre-fix* state of `oo`; any correct finite-fix makes `oo.is_rational=False`, which the unchanged `irrational == real & !rational` rule turns into deductions. Cannot veto I1–I3. | SUSPECT; see F1/F2 |

§ The SUSPECT marking on E8 follows `intent-evidence.md` §1: the issue reports the
pre-fix `is_finite -> None` as the bug, so the pre-fix display *is* the
contradiction; tests pinning the pre-fix `oo` row are evidence, not an oracle.

---

## 3. Human-readable specification

The deductive closure of `_assume_rules`, after the V1 edit, must satisfy:

1. **(EVEN-FINITE)** From `{even: True}`, the closure contains `finite: True`
   (via `even→integer→rational→finite`). Precondition: none. [I1/E1]
2. **(INTEGER-FINITE)** From `{integer: True}`, closure contains `finite: True`.
   [I2/E2]
3. **(RATIONAL-FINITE)** From `{rational: True}`, closure contains `real: True`
   and `finite: True`. [I3/E3]
4. **(OO-CONSISTENT)** From `{positive: True, infinite: True}` (the base facts of
   `S.Infinity`), the closure **terminates without inconsistency** and yields
   `finite: False, rational: False, integer: False, even: False, odd: False`
   (all correct: ∞ is not finite/rational/integer/even/odd), plus the
   definitional consequences `irrational: True, noninteger: True`. [I5/E6/E7]
5. **(CLASH-DETECTED)** Any KB with `infinite: True` and `finite: True` is
   `InconsistentAssumptions`. This is the invariant that rules out the rejected
   alternatives "add finite to `real`" and "add finite to `complex`": both would
   force an infinite singleton (`oo`/`-oo` are real; `zoo` is complex) to
   `finite: True`, hitting this clash. [I4/E5/E6]

Side conditions / scope: **partial-correctness analogue** — termination of the
closure is argued separately (monotone growth over a finite atom set), not
assumed. The fragment models only the atoms the claims mention.

---

## 4. FORMAL_SPEC_ENGLISH (paraphrase of every `assume-spec.k` claim)

- **(EVEN-FINITE)** "Closing a KB whose only fact is `even=true` reaches the
  fixpoint `{even, integer, rational, real, finite}` all true — in particular
  `finite=true`." Expected `kprove`: `#Top`.
- **(INTEGER-FINITE)** "Closing `{integer=true}` reaches `{integer, rational,
  real, finite}` all true." Expected: `#Top`.
- **(RATIONAL-FINITE)** "Closing `{rational=true}` reaches `{rational, real,
  finite}` all true." Expected: `#Top`.
- **(OO-CONSISTENT)** "Closing `{positive=true, infinite=true}` reaches a
  concrete fixpoint (not `#inconsistent`) in which `finite=false`,
  `rational=false`, `integer=false`, `even=false`, `odd=false`,
  `irrational=true`, `noninteger=true`." Expected: `#Top`. Landing on a facts map
  rather than `#inconsistent` is the consistency certificate.
- **(CLASH-DETECTED)** "Closing a KB containing both `infinite=true` and
  `finite=true` rewrites the driver to `#inconsistent`." Expected: `#Top`.

---

## 5. SPEC_AUDIT (FORMAL_SPEC_ENGLISH vs INTENT_SPEC)

| Claim | Compared to intent | Verdict |
|-------|--------------------|---------|
| EVEN-FINITE | exactly I1/E1 | **pass** |
| INTEGER-FINITE | exactly I2/E2 | **pass** |
| RATIONAL-FINITE | exactly I3/E3/E4 | **pass** |
| OO-CONSISTENT — consistency + finite/rational/integer/even/odd values | I5/E6 (consistency) and correct ∞ semantics | **pass** |
| OO-CONSISTENT — `irrational=true`, `noninteger=true` | I6/E7: entailed by the *unchanged* definition `irrational == real & !rational` together with the pre-existing, out-of-scope choice `oo.is_real=True` (I4). Not candidate-invented. | **pass (with recorded consequence F1)** |
| CLASH-DETECTED | I4/E5 (justifies rejecting real/complex placement) | **pass** |

No claim is candidate-derived or legacy-derived. The only non-issue-mentioned
deductions (`oo.is_irrational/noninteger`) are entailed by I6's faithfulness
requirement applied to a definition the issue explicitly leaves unchanged, and
are logged as Finding **F1** rather than silently blessed.

---

## 6. PUBLIC_COMPATIBILITY_AUDIT

The V1 edit changes **no public API, signature, or return type** — it only
enriches the value of existing `is_*` properties (`None → True/False`). Audit of
affected callers:

| Surface | Effect of V1 | Status |
|---|---|---|
| `Symbol(..., even/integer/rational/prime=True).is_finite` | `None → True` | **intended** (the fix) |
| `oo/-oo .is_rational/.is_integer/.is_even/.is_odd` | `None → False` | **correct**; ∞ is none of these |
| `oo/-oo .is_noninteger` | `None → True` | **correct**; ∞ is a non-integer real |
| `oo/-oo .is_irrational` | `None → True` | consequence F1 (definitional; under-determined by intent) |
| `zoo.is_*`, `nan.is_*` | unchanged (zoo already `real=False`; nan all `None`) | **safe** |
| classes with explicit `is_integer/is_rational=True` (`Integer`,`Rational`,`Idx`,`KroneckerDelta`,`LeviCivita`) | all genuinely finite; newly-deduced `finite=True` agrees with `Number._eval_is_finite`→`True` | **safe** (no `InconsistentAssumptions` at import) |
| only classes with `is_infinite=True` are the 3 infinity singletons; none claims integer/rational | no construction-time clash | **safe** |
| `is_irrational` callsites (`numbers.py` `__eq__` guarded by `is_NumberSymbol`/`is_Number`; `polytools` guarded by `is_algebraic`; `Mul/Add/Pow._eval_is_irrational` on forms that evaluate away when ∞ present) | `oo` excluded or form non-persistent | **safe**; residual esoteric case in F3 |

No unhandled public callsite or override. See `FINDINGS.md` for the two residual,
out-of-scope items (F3 `ask(Q.irrational(oo))`, F4 `floor(Symbol(real,infinite))`).
