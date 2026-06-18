# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

`sympy/polys/polytools.py::_generic_factor_list`

- Call shape unchanged.
- Return shape unchanged.
- Existing options (`frac`, `polys`) unchanged.
- Existing coefficient/fraction/sorting/output-conversion paths unchanged except
  that square-free factor lists are normalized before sorting.
- Public effect: `sqf_list()` and `sqf()` may now show a product where the legacy
  expression path showed multiple same-multiplicity entries.
- Compatibility status: intended by the issue for same-generator square-free
  factors.

`sympy/polys/polytools.py::_combine_factors`

- New private helper.
- No external callsites.
- Compatibility status: no public API surface added.

## Callsite/Consumer Audit

`factor_list()`

- Uses `_generic_factor_list(..., method='factor')`.
- V1 helper is guarded by `method == 'sqf'`.
- Compatibility status: preserved by `sqf-combine-spec.k` claim 4.

`sqf_list()`

- Uses `_generic_factor_list(..., method='sqf')`.
- Intended behavior changes for same-generator equal-multiplicity factors.
- Compatibility status: changed as required by E1-E4.

`sqf()`

- Uses `_generic_factor()` rather than `_generic_factor_list()`, so this V1
  helper does not directly alter `sqf()` reconstruction behavior.
- The SO example in the issue remains outside this V1 repair unless separately
  localized; no FVK counterexample here forces expanding the patch.

Mixed-generator expression products

- Public source test keeps `sqf_list(x*(x + y))` split.
- V1 groups by `(factor.gens, exp)`, so factors with different generator tuples
  remain split.
- Compatibility status: preserved by `sqf-combine-spec.k` claim 3.

## Unhandled Compatibility Risks

None requiring a source edit in this pass. The broader multiple-generator policy
remains underspecified in public intent and is not a safe target for a revision
under the no-regression discipline.
