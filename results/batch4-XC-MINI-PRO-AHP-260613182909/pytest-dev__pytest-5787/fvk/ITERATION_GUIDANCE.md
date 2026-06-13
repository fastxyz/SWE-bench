# ITERATION_GUIDANCE.md — pytest-5787

What the FVK pass concluded, and what a next code-generation / review iteration
should (and should not) do.

## Verdict

**V1 stands, unchanged.** The round-trip contract (SPEC.md) was writable cleanly,
every proof obligation (PROOF_OBLIGATIONS.md) discharged ✅, and the construction
required no invented precondition (FINDINGS PD4). Per the kit’s "spec-difficulty is
a bug signal" criterion, the clean spec is positive evidence of correctness. No
source edit is warranted; making one would risk regressing a behaviorally-identical
path (PO-IDENT-V0) for no proven gain.

## Why no repair pass

The task authorizes edits *if the audit surfaced problems*. It surfaced none that
are in-contract:

- The single **latent** finding (F4 / PD3, bare `["chain"]` KeyError on a
  cross-version payload) is explicitly out of the hook’s documented contract
  ("subject to change between pytest releases…"; "restores a report previously
  serialized with pytest_report_to_serializable()"). Patching it (`.get("chain")`)
  is zero-downside hardening but pure gold-plating against a disclaimed scenario,
  and diverges from the file’s established bare-key style (`["sections"]`,
  `["reprtraceback"]`). **Declined.** If a future requirement makes
  `pytest-reportlog` cross-version reads first-class, revisit and add the `.get`
  guard plus a test — that is the one concrete, bounded change on the table.

## For the next iteration (if reopened)

1. **Run the machine check.** `kompile`/`kprove` the artifacts (PROOF.md §9). A
   `#Top` upgrades the proof from *constructed* to *verified* and unlocks the
   (currently withheld) test-removal recommendations.
2. **Confirm the two scrutiny points** a machine check targets: the `List{}`
   structural-induction framing (PO-LIST-INDUCTION) and the partiality model of the
   `RuntimeError` (PO-EXC). Neither indicates a code defect.
3. **Keep the boundary tests.** `test_unserialization_failure` (out-of-domain guard)
   and a chained-exception round-trip test (the FAIL_TO_PASS witness) must stay;
   they pin precisely what the abstract contract excludes or headlines (PD1).
4. **Intent to elicit (PD3):** decide the cross-version-payload policy before
   evolving the serialized schema again.

## Risks a reviewer should still weigh (honest residuals)

- Trusted base: the three modeling abstractions in SPEC §5 (opaque leaves,
  tuple↔list, `ReprTracebackNative`≅`ReprTraceback`). They are argued sound but
  asserted, not machine-checked.
- The proof is **constructed, not machine-checked** — every claim in this package
  carries that caveat until `kprove` returns `#Top`.
