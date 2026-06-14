# SPEC.md — formal specification for the sympy-16597 fix

*Target:* `sympy/core/assumptions.py :: _assume_rules` (the declarative rule base)
together with the deduction engine in `sympy/core/facts.py`
(`FactRules` compilation + `FactKB.deduce_all_facts`).
*Artifacts:* [`mini_assumptions.k`](mini_assumptions.k) (semantics fragment),
[`mini_assumptions-spec.k`](mini_assumptions-spec.k) (claims).
*Mode:* intent-spec (align NL intent ↔ code ↔ formal spec). Constructed, not
machine-checked.

---

## 1. What is being formalized

The "function under verification" is **logical closure**: given a set of
assumption facts about a symbol, `FactKB.deduce_all_facts` computes the least
fixpoint of the implication relation defined by `_assume_rules`, and
`FactKB._tell` rejects (raises `InconsistentAssumptions`) any state that would
assign a fact both `True` and `False`. The V1 fix added one production to the
rule base:

```python
'rational       ->  finite',     # assumptions.py:175  (the V1 change)
```

There are no `for`/`while` loops in the *fix* itself, but the *engine* it feeds
has exactly one fixpoint loop — `deduce_all_facts`'s `while facts:` worklist
(`facts.py:517-537`). That loop is the "loop" the circularity in §5 covers; the
rule base is the data it closes over.

Because the engine is data-driven, the meaningful spec is a set of
**reachability claims over the closure operator**, parameterized by the input
fact set:

> `Closure_R(S)` = the deductive closure of input facts `S` under rule base `R`,
> or `⊥` (inconsistent) if `_tell` ever detects a conflict.

`R` = the V1 rule base. We write `R₀` for the pre-fix rule base
(`R = R₀ ∪ {rational→finite}`).

## 2. Public intent ledger

| # | Source | Evidence (quoted) | Semantic obligation | Status |
|---|--------|-------------------|---------------------|--------|
| L1 | prompt (issue title/body) | "a.is_even does not imply a.is_finite … a number should be finite before it can be even" | `is_even=True ⟹ is_finite=True` for any object | **must hold** → PO1 |
| L2 | prompt (hint block) | "i = Symbol('i', integer=True); print(i.is_finite) → None" | `is_integer=True ⟹ is_finite=True` | **must hold** → PO2 |
| L3 | docs/hint | "the second rule `rational -> real` should be extended to `rational -> real & finite`" / "it should be safe to add finite to rational" | add `rational→finite`; ⟹ `is_rational=True ⟹ is_finite=True` | **chosen fix** → PO3 |
| L4 | hint (caveat) | "real should already imply finite but currently its meaning is extended_real, and adding finite to real would probably break a lot of code" | do **NOT** add `real→finite` (oo/-oo are real **and** infinite) | **constraint** → PO5, F6 |
| L5 | code (`facts.py:126-131`) | `deduce_alpha_implications` raises `ValueError` when `Not(a) ∈ impl[a]` | augmented rule base must stay globally consistent (else import fails) | **must hold** → PO4 |
| L6 | code (`facts.py:484-496`) | `_tell` raises `InconsistentAssumptions` on a conflicting value | no constructible object's facts may close to `⊥` | **must hold** → PO5 |
| L7 | code (`assumptions.py:194`) | `irrational == real & !rational` (unchanged biconditional) | irrational is *defined* as real-and-not-rational in this codebase | context for F2 |
| L8 | tests (`test_assumptions.py:203`) | `Rational(3,4).is_finite is True` (pre-existing) | finite numbers must stay finite (no regression) | **frame** → PO6 |

No external prompt beyond the issue text is available; the spec is inferred from
the issue, the in-repo glossary (`assumptions.py` docstring), the rule base, and
the deduction engine.

## 3. Mini-X semantics (fragment)

[`mini_assumptions.k`](mini_assumptions.k) is a faithful slice of the engine:

- **State** = `<kb>` (a `Fact ⇀ Bool` map; **absent key = `None`/unknown**) plus
  a `<status>` flag (`ok` → `inconsistent` models the two exceptions L5/L6).
- **`tell(F,V)`** has the three `_tell` cases: *new* (record + propagate),
  *redundant* (no-op), *conflict* (→ `inconsistent`).
- **`activate(F,V)`** enqueues the direct implications of `(F,V)` — each alpha
  edge **with its contrapositive** (mirroring `facts.py:116`).
- **`checkBeta`** fires the joined (beta) rules from the biconditionals
  (`irrational == real & !rational`, `noninteger == real & !integer`).
- Closing (`close`) drains `<k>` to the least fixpoint — the model of
  `deduce_all_facts`.

Only the fact slice the claims exercise is encoded
(`even/odd/integer/rational/real/finite/infinite/irrational/noninteger/positive/complex`);
the omitted facts are inert for these obligations. This is the deliberate
"cover only what the code touches" mini-X stopgap.

## 4. Function contract (closure)

For input fact set `S` (a partial `Fact ⇀ Bool` map) the contract of
`deduce_all_facts` / `Closure_R` is:

- **Precondition:** `S` is itself conflict-free.
- **Postcondition:** the result `K = Closure_R(S)` satisfies
  1. `S ⊆ K` (monotone — every input fact survives);
  2. `K` is **closed**: for every alpha edge `(a→b) ∈ R`, `a∈K ⟹ b∈K`, and for
     every beta rule, premises-in-`K ⟹ conclusion-in-`K`;
  3. `K` is conflict-free **iff** `R` is consistent and `S` is consistent
     (otherwise `status = inconsistent`, modeling the raised exception).

The issue-specific instances (PO1–PO3, PO5, PO7) are the claims in
[`mini_assumptions-spec.k`](mini_assumptions-spec.k).

## 5. Loop / fixpoint circularity

`deduce_all_facts` is the only loop. Its **invariant** (the circularity that
replaces a hand-written loop invariant):

> At the top of every `while facts:` iteration, `<kb> ⊆ Closure_R(S)`, `<kb>` is
> conflict-free (given `R`,`S` consistent), and the worklist holds only facts
> already entailed by `<kb>`.

**Guardedness / termination:** each genuine step *adds* a key to the finite map
`Fact ⇀ Bool` or sets `status:=inconsistent`; the fact lattice is finite, so the
worklist strictly shrinks in potential and the closure terminates. (Termination
is therefore *provable* here — unusually, total correctness is in reach because
the domain is finite — but per FVK default we prove **partial correctness** and
record termination as a discharged side note in PROOF.md.)

## 6. The safety constraint that shapes the fix (L4)

`real` in this version denotes the **extended reals**: `oo` and `-oo` satisfy
`is_real=True` *and* `is_infinite=True` simultaneously (`positive→real`,
`negative→real`; `numbers.py:2657-2660, 2881-2883`). Therefore `real→finite`
is **inconsistent** (it would force `oo` to be both finite and infinite → L5/L6
failure → SymPy fails to import). The fix must attach `finite` to a predicate
that **excludes** the infinities. `rational` is the most general such predicate
(no infinity is rational), so `rational→finite` is the maximal safe choice — and
it reaches `integer`/`even`/`odd` through the pre-existing chain. This is exactly
the reasoning recorded in L3/L4.

See [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md) for the enumerated obligations
and [`PROOF.md`](PROOF.md) for the constructed proof.
