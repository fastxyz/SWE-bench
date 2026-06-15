# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, or K
tooling.

## Decisions

I kept the V1 source change unchanged. Finding F-001 localizes the bug to
compiler-time mutation of original child queries in `combined_queries`; PO-2
and PO-3 show that V1 removes that state leak by compiling cloned child
queries. Because the reported stale-column behavior is caused by persistent
child `values_select` state, moving `set_values()` onto the clone is the
minimal repair.

I did not replace V1 with a broader `Query.clone()` change. PO-2 only requires
isolation of compiler-time child-query mutations, and Finding F-003 found no
public API or clone-semantics requirement that justifies changing combined
query clone behavior globally.

I did not narrow V1 to clone only immediately before `set_values()`. Finding
F-002 and PO-1 show V1 preserves the required in-compilation column alignment,
and PO-5 benefits from cloning child compilers at the entry to the combinator
compilation path, including nested combined queries.

I added the five requested FVK markdown artifacts under `fvk/` and also added
the adequacy audit files plus `fvk/mini-django-query.k` and
`fvk/combinator-values-spec.k`. The extra files follow the FVK documentation's
requirement that the run include intent, formal-English, compatibility, and
formal-core artifacts rather than Markdown-only reasoning.

## Traceability

- `fvk/SPEC.md` records the public intent ledger and the abstract formal
  model.
- `fvk/FINDINGS.md` records F-001 through F-004, including the resolved bug and
  the constructed-not-machine-checked caveat.
- `fvk/PROOF_OBLIGATIONS.md` records PO-1 through PO-6, which justify keeping
  V1 unchanged.
- `fvk/PROOF.md` gives the symbolic pre-fix counterexample and the V1 proof.
- `fvk/ITERATION_GUIDANCE.md` records future tests and machine-check commands.
- `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` provide the adequacy and compatibility
  gate required by the FVK docs.

No production source files were changed during the FVK pass because the audit
confirmed V1 against the stated proof obligations.
