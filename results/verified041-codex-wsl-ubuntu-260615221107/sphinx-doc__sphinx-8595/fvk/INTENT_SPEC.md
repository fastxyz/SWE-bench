# Intent Specification

This file records public intent before accepting the candidate implementation as
correct.

## Required behavior

1. `automodule` with `:members:` must honor a module's explicit `__all__`.
2. A valid empty `__all__` means the module explicitly exports no names.
3. Therefore, with `__all__ = []`, documented functions such as `foo`, `bar`,
   and `baz` must not be emitted by default.
4. Missing, invalid, raising, or ignored `__all__` is a different case from an
   explicit empty sequence and may continue using autodoc's implicit member
   behavior.
5. Existing extension hooks, including `autodoc-skip-member`, should not be
   bypassed by a narrower fix unless public intent requires it.

## Out of scope

1. The issue does not require changing explicit named member selection such as
   `:members: foo,bar`.
2. The issue does not require changing sort order for non-empty `__all__`.
3. The issue does not require changing rendering, signature formatting, import
   behavior, or docstring extraction.
