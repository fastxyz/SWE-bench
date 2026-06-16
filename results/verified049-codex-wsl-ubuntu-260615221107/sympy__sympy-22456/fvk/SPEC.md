# FVK Spec

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

This FVK pass audits the V1 repair for `sympy.codegen.ast.String` argument
invariance. The target behavior is the observable constructor/reconstruction
surface of `String` and its subclasses in `repo/sympy/codegen/ast.py`.

Supporting artifacts:

- `fvk/mini-sympy-string.k`
- `fvk/sympy-string-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Public Intent Ledger Summary

Critical entries are mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E1 and E2: the issue requires `expr.func(*expr.args) == expr` for
  `codegen.ast.String` because it is a `Basic` subclass.
- E3 and E6: `Basic.args` entries must be `Basic` objects; therefore the
  reconstruction carrier for text cannot be a raw Python `str`.
- E4: `sympy.core.symbol.Str` is the local Basic-compatible representation of
  textual data.
- E5: public `String` behavior includes `.text` as the raw Python string,
  kwargs reconstruction, `is_Atom`, subclass separation, `str`, and `repr`.
- E7: public codegen behavior expects `String` to remain a default atom leaf in
  token trees such as `sizeof(...)`.

## Domain

For every class `C` where `C` is `String` or inherits from `String`, and every
Python string `s`, public construction `C(s)` is in domain. Internal
reconstruction `C(Str(s))` is also in domain because `.args` is required to
contain `Basic` objects.

Inputs that are neither Python `str` nor `Str` remain out of domain for text
construction and must raise `TypeError`.

## Contract

For every in-domain `C` and `s`:

1. `obj = C(s)` has `obj.text == s`.
2. `obj.args == (Str(s),)`.
3. Every element of `obj.args` is a `Basic` instance.
4. `obj.func(*obj.args) == obj`.
5. `obj.func(**obj.kwargs()) == obj`.
6. `obj.is_Atom` remains true.
7. Default `Token.atoms()` returns codegen `String` leaves, not the internal
   `Str` reconstruction wrapper.
8. `repr`, `str`, equality, and subclass distinction remain based on the public
   class and `.text` attribute.

## Candidate Mapping

V1 implements the contract as follows:

- [repo/sympy/codegen/ast.py:139](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/codegen/ast.py:139) imports `Str`.
- [repo/sympy/codegen/ast.py:917](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/codegen/ast.py:917) installs `Str(obj.text)` into `_args` during `String.__new__`.
- [repo/sympy/codegen/ast.py:923](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/codegen/ast.py:923) accepts `Str` and normalizes it back to `text.name` during reconstruction.
- [repo/sympy/codegen/ast.py:340](/home/patrickmao/.swe-fvk-runs/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22456/repo/sympy/codegen/ast.py:340) keeps default codegen atom traversal treating `String` as a leaf.

## Adequacy

`fvk/SPEC_AUDIT.md` marks every formal claim as PASS against the intent spec.
No formal claim is justified solely by V1 behavior, and no compatibility issue
requires a V2 source edit.
