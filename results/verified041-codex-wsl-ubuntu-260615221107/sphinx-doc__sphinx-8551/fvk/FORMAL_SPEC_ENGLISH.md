# Formal Spec in English

The K claims in `sphinx-xref-spec.k` state the following obligations. The proof
is constructed, not machine-checked.

C1 `FIELD-CONTEXT`: For every Python field xref node and every current Python
reference context `(py:module, py:class)`, `process_field_xref` rewrites the
node so those two context fields equal the current context, preserving target,
display text, and `refspecific`.

C2 `PLAIN-FIELD`: For every current context, a field-generated raw target `A`
becomes a pending reference whose target is `A`, whose display text is `A`, and
whose `refspecific` flag is false.

C3 `DOT-FIELD`: For every current context, a field-generated raw target `.A`
becomes a pending reference whose target and display text are `A`, and whose
`refspecific` flag is true.

C4 `TILDE-FIELD`: For every current context, a field-generated raw target
`~mod.A` becomes a pending reference whose target is `mod.A`, whose display text
is `A`, and whose `refspecific` flag is false.

C5 `RESOLVE-MOD`: In the issue object database containing `mod.A` and
`mod.submod.A`, a plain field target `A` in current module `mod` resolves to
`mod.A` as a single match.

C6 `RESOLVE-SUBMOD`: In the same database, a plain field target `A` in current
module `mod.submod` resolves to `mod.submod.A` as a single match.

C7 `RESOLVE-NONMODULE-PLAIN`: In the same database, a plain field target `A`
with no current module does not resolve by suffix-fuzzy lookup. It produces no
target in this model, leaving normal missing-reference handling outside the
modeled unit.

C8 `RESOLVE-NONMODULE-DOT`: A leading-dot `.A` with no current module keeps
`refspecific` behavior and can observe the suffix ambiguity between `mod.A` and
`mod.submod.A`. This confirms that the proof does not remove explicit
leading-dot fuzzy lookup.
