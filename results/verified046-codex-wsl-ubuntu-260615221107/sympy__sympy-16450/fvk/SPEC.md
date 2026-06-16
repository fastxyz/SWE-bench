# FVK Specification: `posify` Assumption Preservation

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target function: `sympy.simplify.simplify.posify`.

Audited behavior: construction of replacement dummy symbols for symbols whose
`is_positive` value is `None`, including expression and iterable inputs that use
the same per-symbol replacement behavior.

This target has no loops. The FVK model is a small Mini-SymPy fragment over a
symbol name and an assumptions map. It deliberately keeps the assumption map
observable because the reported defect is loss of an assumption fact.

## Intent Specification

The intended contract is derived from public issue text, the public hint, the
existing `posify` docstring, and public in-repository tests. Current code
behavior is treated as candidate behavior, not as the source of expected output.

1. A symbol with `finite=True` and unknown positivity must produce a replacement
   whose finiteness is still known.
2. The preservation obligation is a family: assumptions other than positivity
   should be retained, including facts such as `integer`, `rational`, `prime`,
   `even`, and `odd` when they are present and consistent with positive
   narrowing.
3. `posify` should only add `positive=True` for a symbol whose positivity is not
   already defined.
4. Symbols whose positivity is already known should not be replaced.
5. Replacement dummies should have the same display name as the original symbol.
6. The returned replacement dictionary should restore the transformed expression
   to its original symbols via substitution.
7. The public API shape remains `posify(eq) -> (new_eq, replacements)`.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`posify` removes a finite assumption from a symbol" | `finite=True` on an original unknown-positive symbol must be preserved on the replacement. | Encoded by PO2 and the first K claim. |
| E2 | prompt | "I think that posify should preserve the finiteness assumption." | The expected output for the reported case is `xp.is_finite is True`. | Encoded by PO2. |
| E3 | prompt | "Possibly other assumptions should be preserved as well (integer, rational, prime, even, odd...)." | Preservation is not special-cased to `finite`; it is a family over known assumptions. | Encoded by PO2. |
| E4 | public hint | "`posify` is to only add a new assumption `positive=True` when `positive` is not defined, the other assumptions should be retained." | The formal operation is an assumption-map frame update: add/overwrite `positive=True`, preserve other entries. | Encoded by PO1, PO2, PO3. |
| E5 | docstring | "Any symbol that has positive=None will be replaced with a positive dummy symbol having the same name." | Replacement trigger is unknown positivity; replacement has same name and positive truth. | Encoded by PO1, PO3. |
| E6 | docstring | "A dictionary that can be sent to subs to restore eq to its original symbols is also returned." | Returned mapping is replacement dummy to original symbol. | Encoded by PO4. |
| E7 | public tests | Existing tests leave positive and negative symbols unchanged and restore modified expressions with `subs(reps)`. | Preserve public return shape and restoration behavior. | Encoded by PO4, PO5, PO7. |
| E8 | public tests | Noncommutative `posify(A)` remains noncommutative. | Known non-positive or non-replaceable symbols must not be forced through the unknown-positive branch. | Encoded by PO1 and PO6. |
| E9 | implementation | `Symbol.assumptions0` returns a dict of non-`None` assumption facts. | This is the source map that can implement the frame update over existing known facts. | Used as implementation evidence for V1, not as intent by itself. |

## Formal Contract

For each free symbol `s` in the input expression, let `A = s.assumptions0`.

If `s.is_positive is None`, then `posify` must create a dummy `d` such that:

1. `d.name == s.name`.
2. `d.assumptions0['positive'] is True`.
3. For every assumption key `k != 'positive'`, if `A[k] = v`, then
   `d.assumptions0[k] = v`.
4. The transformed expression substitutes `s` with `d`.
5. The returned replacement map contains `d: s`.

If `s.is_positive is not None`, then `s` is not replaced by the positive-dummy
step.

For iterable inputs, `posify` applies the same per-symbol contract to the union
of symbols in the iterable and uses a consistent replacement for each symbol
throughout the returned iterable.

Preconditions:

1. The input is in the existing `posify` domain: it can be sympified, and for
   iterable inputs each element can be processed by `posify`.
2. Original symbol assumptions are internally consistent under SymPy's old
   assumptions rules.
3. For the unknown-positive branch, adding `positive=True` is a valid narrowing.
   This is operationally represented by the existing guard
   `s.is_positive is None`; if positivity is known false or true, the branch is
   not taken.

## Formal Core

The K artifacts are:

1. `fvk/mini-posify.k`: a Mini-SymPy fragment with `posifySymbol`.
2. `fvk/posify-spec.k`: two reachability claims.

Formal claim paraphrases:

1. Unknown-positive claim: from `posifySymbol(sym(N, A))`, if
   `positiveUnknown(A)` and `consistentPositiveNarrowing(A)`, execution reaches
   `result(dummy(N, setPositive(A)), dummy(N, setPositive(A)) |-> sym(N, A))`;
   `setPositive(A)` preserves all non-`positive` facts and has positive true.
2. Known-positive claim: from `posifySymbol(sym(N, A))`, if `positiveKnown(A)`,
   execution reaches `result(sym(N, A), .Map)`.

Adequacy check:

1. The unknown-positive claim matches E1-E6 because it models exactly "add
   `positive=True` and retain other assumptions" with the same-name dummy and
   reverse restoration map.
2. The known-positive claim matches E5, E7, and E8 because it keeps symbols out
   of the positive-dummy branch when positivity is already determined.
3. The model does not prove unrelated SymPy behavior such as all simplification
   effects of `.subs`; it only proves the replacement-map construction property
   that produced the reported bug.

## Public Compatibility Audit

No public signature changed. `posify` still accepts the same `eq` argument and
returns `(eq, replacements)`.

The public return-shape expectations remain intact:

1. Replacement symbols still have the same name because the call remains
   `Dummy(s.name, ...)`.
2. The reverse map still maps replacement to original because the return remains
   `{r: s for s, r in reps.items()}`.
3. Existing public behavior for already-positive and already-negative symbols is
   preserved because the guard remains `if s.is_positive is None`.
4. Iterable behavior continues to use the same recursive per-symbol mapping
   path.
