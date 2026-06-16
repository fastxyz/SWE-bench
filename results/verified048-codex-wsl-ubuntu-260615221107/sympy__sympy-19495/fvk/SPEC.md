# FVK Specification

Status: constructed, not machine-checked.

## Scope

This specification audits the V1 fix for `ConditionSet._eval_subs` in
`repo/sympy/sets/conditionset.py`. The changed branch is:

1. `self.sym` is an `Expr`;
2. `old != self.sym`;
3. `self.condition.subs(old, new) is S.true`.

The issue input is in this branch: the condition `Contains(y, Interval(-1, 1))`
does not depend on the bound dummy `x`, and substituting `y = Rational(1, 3)`
makes the condition true.

## Public Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the full ledger.

The critical entries are:

- E1/E2: ordinary `subs` should not produce the malformed `ConditionSet` shown
  in the issue.
- E3: plain `ImageSet.subs` already works, so the surrounding `ConditionSet`
  branch is the root cause.
- E4: a true condition on construction returns the base set.
- E5: dummy-dependent true conditions caused by assumptions have public in-repo
  compatibility evidence for the legacy fallback.

## Intended Contract

Let:

- `sym` be the `ConditionSet` dummy;
- `condition` be the original condition;
- `base` be the original base set;
- `cond1 = condition.subs(old, new)`;
- `base1 = base.subs(old, new)`;
- `depends = bool(sym.free_symbols & condition.free_symbols)`.

For the audited `old != sym` branch:

| Case | Required result |
| --- | --- |
| `cond1 is S.true` and `depends is False` | `base1` |
| `cond1 is S.true` and `depends is True` | `ConditionSet(new, Contains(new, base1), base1)` |
| `cond1 is not S.true` | `ConditionSet(sym, cond1, base1)` through the existing constructor path |

The reported `ImageSet` case is the first row, so the required result is the
substituted `ImageSet`.

## Formal Core

The formal core is intentionally abstract:

- `mini-sympy-substitution.k` models only the symbolic state and branch rules
  needed for the audited `_eval_subs` behavior.
- `conditionset-subs-spec.k` contains the K reachability claims corresponding
  to the three rows of the contract table.

This is not a full SymPy semantics. Full semantics for assumptions, binders,
`Contains`, and `ImageSet` membership are outside the FVK fast path and remain a
proof capability boundary, recorded in `FINDINGS.md`.

## Adequacy

The formal claims are adequate for the V1 decision because the defect's
observable axis is the top-level return shape: substituted base set versus
malformed `ConditionSet(new, Contains(new, base), base)`. The abstract model
distinguishes those two shapes directly.

The claims do not prove all of SymPy substitution. They prove the branch decision
that V1 changed and frame the neighboring branches needed to avoid an
over-correction.

