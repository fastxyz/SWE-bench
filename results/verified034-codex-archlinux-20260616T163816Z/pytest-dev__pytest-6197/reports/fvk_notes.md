## FVK Decision Summary

V1 stands unchanged. The FVK audit found no additional production-code change
justified by the public intent and proof obligations.

## Decisions Traced to Findings and Proof Obligations

Kept the V1 removal of eager package mounting from `Package.collect()`.
`fvk/FINDINGS.md` F1 identifies the base regression as import of an unrelated
package initializer during directory collection. `fvk/PROOF_OBLIGATIONS.md` PO1
and PO2 discharge the required no-import behavior by showing that
`Package.collect()` no longer mounts the package and recursive package-only
collection emits no import event.

Kept V1's `_mount_package_parents()` call at the start of `Module.collect()`.
F3 records the compatibility requirement that package-level marks from
`__init__.py` remain visible to child tests. PO3 discharges that requirement
because package parents are mounted before `PyCollector.collect()` creates
`Function` items.

Did not remove `"__init__.py"` from the file-collection pattern list and did not
disable `Package` collector creation. F2 records the audit concern that package
collectors are still created for every package; PO1 and PO2 show this is safe
because collector creation is now separated from import. Removing the pattern
would have risked parent-chain and direct-file behavior that the issue did not
ask to change.

Kept the existing `python_files` gate for collecting tests from `__init__.py`.
F4 and PO4 cover this compatibility requirement: configured initializer tests
still collect when `python_files` matches, and import then occurs through the
normal `Module.collect()` path.

Made no public API or hook changes. F5 and PO5 require hook signatures,
collector classes, parent chains, and `python_files` semantics to remain stable;
V1 changes only internal import timing.

## Artifacts

Created the five requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also created the abstract K artifacts required by the FVK method:

- `fvk/mini-pytest-collection.k`
- `fvk/pytest-collection-spec.k`

These are constructed specifications only. I did not run `kompile`, `kast`,
`kprove`, tests, Python, or any other code, as required by the task. PO6 records
that honesty boundary.

## Residual Risk

The proof is partial correctness over an abstract collection model. It does not
prove filesystem traversal termination or arbitrary third-party collection hook
behavior. Those are recorded as residual risks in `fvk/FINDINGS.md` R1-R3 and do
not justify changing V1 for the reported built-in pytest regression.
