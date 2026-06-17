# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`sympy.polys.matrices.normalforms._hermite_normal_form`

- Signature unchanged.
- Return type unchanged: `DomainMatrix`.
- Error behavior for non-`ZZ` domains unchanged.
- Internal dense representation use unchanged.

## Public wrappers

`sympy.polys.matrices.normalforms.hermite_normal_form`

- Signature unchanged.
- The dispatch to `_hermite_normal_form_modulo_D` for the modular path is
  unchanged.
- The non-modular path still delegates to `_hermite_normal_form`.

`sympy.matrices.normalforms.hermite_normal_form`

- Signature unchanged.
- Return type unchanged: public `Matrix`.
- Conversion of `D` values unchanged.

## Public callsites and overrides

No virtual dispatch signature, subclass override protocol, or public callsite
contract is changed. The behavior change is limited to correcting the returned
HNF value for tall matrices whose pivots occur above the old bottom-row window.

## Compatibility findings

Existing public tests that assert the old zero-column result for rank-positive
tall matrices are classified as suspect legacy behavior in Finding F3, because
they conflict with the HNF rank/module preservation contract.
