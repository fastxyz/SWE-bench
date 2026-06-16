# Intent Spec

Status: constructed from public issue text and source comments, before treating
V1 behavior as authoritative.

## Required behavior

I1. Python info-field type references created by `:type:`, inline
`:param Type name:`, and `:rtype:` must use the same Python reference context
as explicit Python xref roles. In particular, an unqualified `A` inside
`.. py:currentmodule:: mod` resolves as `mod.A`, and an unqualified `A` inside
`.. py:currentmodule:: mod.submod` resolves as `mod.submod.A` when those objects
exist.

I2. The issue reproduction with `mod.A` and `mod.submod.A` must produce no
"more than one target found" warnings for unqualified type-field `A` under
`mod` or `mod.submod`.

I3. The field-generated `A` in the `mod.submod` section must not silently resolve
to `mod.A`; it must resolve to `mod.submod.A`.

I4. In non-module scope, an ordinary unqualified field-generated `A` must not
silently use suffix-wide fuzzy lookup to link to an arbitrary `*.A`. If no exact
top-level `A` exists, it should remain unresolved or warn as a missing reference
under the usual Sphinx missing-reference path, rather than resolving to
`mod.A`.

I5. Leading-dot field targets keep explicit-role `refspecific` behavior:
`.A` requests more-specific/fuzzy lookup. Tilde-only targets keep display
shortening but do not request fuzzy lookup.

I6. The fix must not change public method signatures, the explicit Python role
path, non-Python domains, or test files.

## Default-domain assumptions

D1. Explicit Python xref roles are the comparison oracle because the issue says
the implicit info-field xrefs "do lookup differently than explicit xref roles"
and expects them to match.

D2. The existing Python-domain `find_obj()` ordering is the resolver semantics
to preserve; the fix should feed it the correct context and `refspecific` flag
rather than redefine object lookup globally.
