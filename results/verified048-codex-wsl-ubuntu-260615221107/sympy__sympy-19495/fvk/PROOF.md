# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
command was executed.

## Claims Proved in the Abstract Model

Claim 1: External true guard. If `old` is not the `ConditionSet` dummy, the
substituted condition is true, and the original condition is independent of the
dummy, then `_eval_subs` returns the substituted base set.

Claim 2: Dummy-dependent true guard. If the substituted condition is true but
the original condition depends on the dummy, `_eval_subs` returns the legacy
membership fallback.

Claim 3: Non-true guard frame. If the substituted condition is not true,
`_eval_subs` returns the existing constructor-mediated
`ConditionSet(sym, substituted_condition, substituted_base)`.

## Symbolic Proof Sketch

The mini semantics has one command:
`EvalSubs(SYM, COND, BASE, OLD, NEW)`.

Symbolic execution case-splits on the same branch predicates used by V1:

1. `oldIsSym(OLD, SYM) == false`
2. `subCond(COND, OLD, NEW) == TrueCond`
3. `dependsOn(SYM, COND) == false` or `true`

For Claim 1, the first semantic rule applies. Its right-hand side is exactly
`subSet(BASE, OLD, NEW)`. This matches PO1. If `subSet(BASE, OLD, NEW)` is an
`ImageSetObj`, the top-level constructor remains `ImageSetObj`; the malformed
`ConditionSetValueObj(NEW, ...)` shape is unreachable in this branch, satisfying
PO2.

For Claim 2, the second semantic rule applies after the same true-condition
test, but with `dependsOn(SYM, COND) == true`. Its right-hand side is
`ConditionSetValueObj(NEW, ContainsCond(NEW, subSet(BASE, OLD, NEW)),
subSet(BASE, OLD, NEW))`, matching the legacy fallback required by PO3.

For Claim 3, the third semantic rule applies when the substituted condition is
not true. Its right-hand side preserves the existing constructor-mediated
`ConditionSetObj(SYM, subCond(...), subSet(...))`, matching PO4.

The V1 source implements the same case split:

```python
if cond is S.true:
    if not (sym.free_symbols & self.condition.free_symbols):
        return base
    return ConditionSet(new, Contains(new, base), base)
return self.func(self.sym, cond, base)
```

The pre-V1 implementation lacked the inner dependency check. In the Claim 1
state, it would have taken the Claim 2 return shape, which is exactly the
reported bug.

## Adequacy Gate

`INTENT_SPEC.md` requires external true guards independent of the dummy to return
the substituted base. `FORMAL_SPEC_ENGLISH.md` claim C1 states the same
obligation. `SPEC_AUDIT.md` marks C1 and the `ImageSet` corollary C2 as pass.

The model is adequate for the audited defect because it preserves the observable
axis under test: substituted base set versus malformed condition set. It is not
adequate for proving all of SymPy substitution, and the proof does not claim
that.

## Machine Check Commands

These commands are recorded for a future environment with K installed. They were
not run here.

```sh
kompile fvk/mini-sympy-substitution.k --backend haskell
kast --backend haskell fvk/conditionset-subs-spec.k
kprove fvk/conditionset-subs-spec.k
```

Expected machine-check result, if the abstract K files parse and the claims
discharge: `#Top`.

## Test Recommendation

Do not delete or modify tests. Any redundancy recommendation is conditioned on a
future successful `kprove` run, and the user explicitly prohibited test-file
edits.

