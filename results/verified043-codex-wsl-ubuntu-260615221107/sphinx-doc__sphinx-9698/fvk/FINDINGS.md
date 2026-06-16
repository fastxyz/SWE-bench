# FVK Findings

Constructed, not machine-checked.

## F-001: Legacy callable property index text

Input:

```rst
.. py:method:: Foo.bar
   :property:
```

Legacy observed behavior: an index entry shaped like `bar() (Foo property)`.

Expected behavior from public intent: `bar (Foo property)`, with no `()` after
`bar`.

Status: fixed by the V1 source change. `PyMethod.get_index_text()` now checks
`property in self.options` before callable method variants and returns the same
qualified property format used by `PyProperty`.

Proof obligations: PO-1, PO-3.

## F-002: Existing public test encodes the reported bug

Input:

```rst
.. py:class:: Class

   .. py:method:: meth5
      :property:
```

Public test expectation at `repo/tests/test_domain_py.py:758`:
`meth5() (Class property)`.

Expected behavior from the issue: `meth5 (Class property)`.

Status: SUSPECT legacy evidence. The test is valuable for localizing the old
behavior but cannot be used as the desired spec. It should be updated by the
project test suite owner; this benchmark forbids editing tests.

Proof obligations: PO-1, PO-8.

## F-003: No source defect found after V1

The V1 code covers all in-scope property-option branches found during the FVK
audit:

- qualified names;
- unqualified names with a module;
- unqualified names without a module;
- property combined with other method-like flags;
- non-property methods, classmethods, and staticmethods as frame conditions.

Status: V1 stands unchanged after FVK. No additional source edit is justified by
the public intent or proof obligations.

Proof obligations: PO-1 through PO-7.

## F-004: Proof is constructed but not machine-checked

No `kompile`, `kast`, `kprove`, Python, or tests were run in this session. The
formal claims and proof are therefore constructed artifacts only.

Status: honesty caveat. Machine-checking commands are recorded in `SPEC.md` and
`PROOF.md`; test removal or stronger verification claims must wait for those
commands to return `#Top`.

Proof obligations: PO-8.
