# Spec Audit

Status: pass. No required intent clause is omitted by the formal English spec.

| Formal clause | Intent coverage | Verdict |
| --- | --- | --- |
| C1 | Matches I1, D1, E8: field xrefs must carry explicit-role Python context. | Pass |
| C2 | Matches I1 and I4: ordinary unqualified field targets are not `refspecific`. | Pass |
| C3 | Matches I5 and E6: leading dot requests specific/fuzzy lookup. | Pass |
| C4 | Matches I5 and E6: tilde strips display/target prefix but does not request fuzzy lookup. | Pass |
| C5 | Matches I1 and I2 for `currentmodule = mod`. | Pass |
| C6 | Matches I1, I2, and I3 for `currentmodule = mod.submod`. | Pass |
| C7 | Matches I4 and the public hint E5. | Pass |
| C8 | Matches I5 and prevents overcorrection by preserving explicit dot semantics. | Pass |

## Suspect legacy evidence

The public in-repo assertions that field-generated refs under a current module
lack `py:module` / `py:class` are classified as SUSPECT. They encode the
missing-context behavior that the issue describes as the cause of false
ambiguity and wrong links.

## Completeness check

The formal model covers the whole observable involved in the issue:

- field xref metadata production;
- the `refspecific` flag that selects resolver search mode;
- resolver outcomes for the reported `mod.A` / `mod.submod.A` object database;
- the non-module-scope hint.

The model intentionally does not cover full docutils node rendering,
intersphinx, built-in type suppression, or all `find_obj()` object kinds. Those
are outside the issue observable and unchanged by V1.
