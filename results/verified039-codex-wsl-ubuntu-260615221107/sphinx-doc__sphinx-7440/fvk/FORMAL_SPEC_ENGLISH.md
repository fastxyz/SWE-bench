# Formal Spec English

This is the English paraphrase of the nontrivial claims in
`sphinx-glossary-spec.k`.

CASE-DISTINCT-REGISTRATION:

Starting from an empty standard-domain term object map, registering the glossary
term `MySQL` at label `term-MySQL` and then registering `mysql` at label
`term-mysql` produces two map entries, one keyed by `MySQL` and one keyed by
`mysql`, and produces no duplicate warning.

EXACT-DUPLICATE-WARNS:

Starting from an empty term object map, registering `mysql` twice produces one
term map entry for `mysql` and emits a duplicate warning for `mysql` on the
second registration.

TERM-ROLE-COMPAT-SHAPE:

Parsing a `:term:` target with visible target text `MySQL` produces a pending
reference whose public `reftarget` is `mysql` and whose internal original-term
attribute is `MySQL`.

EXACT-TERM-RESOLUTION:

When both `MySQL` and `mysql` are present as different term objects, resolving a
local term reference whose original target is `MySQL` returns the `MySQL`
target, even though the compatibility `reftarget` is `mysql`.

UNAMBIGUOUS-FOLD-FALLBACK:

When only one target exists among all term names with the same lowercased form,
a reference with different case may resolve to that unique target.

AMBIGUOUS-FOLD-REFUSES-GUESS:

When two different labels share the same lowercased form, a non-exact reference
with that folded form resolves to no local term target instead of choosing
arbitrarily.

ANY-TERM-USES-SAME-RESOLVER:

Standard-domain `:any:` term lookup uses the same exact-first and
unique-case-fold fallback resolver as `std:term`.
