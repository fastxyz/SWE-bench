# Intent Spec

Status: constructed from public/local evidence only. The current implementation
is treated as a candidate, not as the specification.

## Required Behavior

I-001. Case-distinct glossary terms are distinct glossary entries.

Evidence: `benchmark/PROBLEM.md` reports a duplicate warning for `mysql` and
asks: `MySQL != mysql term right ?`; the public hint says this is a bug.

Obligation: registering glossary terms whose visible texts differ only by case
must not emit a duplicate-term warning and must not overwrite one entry with the
other in the standard-domain term object map.

I-002. Exact duplicate glossary terms still warn.

Evidence: `repo/tests/test_domain_std.py` has an existing public test for two
`term-case4` entries expecting `duplicate term description of term-case4`.

Obligation: only exact same term object names are duplicate term descriptions.

I-003. Term references should resolve the intended term when exact spelling is
available.

Evidence: the issue identifies `MySQL` and `mysql` as different terms. Once the
standard domain can store both, exact same spelling is the only public-intent
way to distinguish them.

Obligation: local `std:term` resolution must prefer an exact term spelling over
case-folded compatibility lookup.

I-004. Historical lowercased term-reference target shape should be preserved
where possible.

Evidence: base Sphinx 3.0 code used `XRefRole(lowercase=True)` for `std:term`;
intersphinx lookup uses `pending_xref['reftarget']` directly, and existing
inventories can contain lowercased term names.

Obligation: the public pending-xref `reftarget` for `:term:` should remain
lowercased for compatibility, while local resolution may carry extra metadata
to distinguish exact spellings.

I-005. Unambiguous legacy case-insensitive term references should keep working.

Evidence: the old `std:term` role lowercased targets, and Sphinx i18n tests
require translated glossary terms not to warn `term not in glossary`.

Obligation: if no exact term is found but all case-folded matches point to one
target, resolution may use that unique target. If case-folded matches point to
different targets, resolution must not guess.

I-006. `:any:` lookup for standard-domain terms should use the same term
identity rule.

Evidence: `StandardDomain.resolve_any_xref()` had a term-specific lowercased
branch before this fix.

Obligation: `:any:` should be able to find exact-case terms and must not
collapse case-distinct term targets.
