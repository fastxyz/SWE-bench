# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit found the same root cause as the baseline:
the old branch treated a valid empty `__all__` as missing because it used
truthiness. The V1 fix, `self.__all__ is None`, is the minimal source change
needed to distinguish absent/ignored `__all__` from an explicit empty sequence.

## Trace to findings and proof obligations

F-001 identifies the resolved bug: for `__all__ = []` and `:members:`, the old
code returned the implicit-member path. PO-1 and PO-2 require separating
`None` from an empty valid sequence and require the empty sequence to enter the
explicit-`__all__` branch. V1 satisfies both obligations directly.

PO-3 and PO-4 then show why no additional source change is needed. The existing
explicit-`__all__` branch already marks every member not in `__all__` as
`skipped`, and the default `filter_members()` path already omits forced-skipped
members. For `__all__ = []`, every member is outside the export list, so the
existing pipeline produces no documented entries.

F-002 and PO-6 explain why I did not replace this with a special-case early
return of an empty list. Existing public behavior lets `autodoc-skip-member`
event handlers override skip decisions for members not in `__all__`. Reusing the
normal explicit-`__all__` skip path preserves that extension point; returning an
empty list immediately would be a broader behavior change than the public issue
requires.

PO-5 confirms that ignored, invalid, raising, or absent `__all__` remains on the
implicit-member path because those cases leave `self.__all__` as `None`. PO-7
confirms that explicit named-member selection is unchanged because the edit is
only inside the `want_all` branch. F-003 records that no further source defect
was surfaced by the FVK audit.

## Artifacts produced

The required FVK artifacts are under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`

The FVK method also requires the formal and adequacy core, so I added:

- `mini-python.k`
- `autodoc-module-all-spec.k`
- `INTENT_SPEC.md`
- `PUBLIC_EVIDENCE_LEDGER.md`
- `FORMAL_SPEC_ENGLISH.md`
- `SPEC_AUDIT.md`
- `PUBLIC_COMPATIBILITY_AUDIT.md`

## Execution constraints

No tests, Python code, `kompile`, `kast`, or `kprove` commands were run. The K
commands are recorded in the artifacts for future machine checking only, and
the proof is labeled constructed, not machine-checked.
