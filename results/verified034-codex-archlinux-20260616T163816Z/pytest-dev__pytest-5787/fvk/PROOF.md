# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Adequacy Gate

The proof obligations are derived from the intent ledger in `fvk/SPEC.md`, not
from V1's behavior. The issue's xdist output that shows only the last exception
is marked SUSPECT legacy behavior because the public issue identifies it as the
bug.

The K model in `fvk/mini-pytest-report.k` is abstract, but it keeps the property
under verification observable: a multi-element chain and a single newest
exception serialize to different `JsonLongrepr` values. Therefore the model can
distinguish the failing legacy behavior from the required behavior.

## Proof Sketch

PO-001 follows by case analysis over supported entry types. A `ReprEntry` is
serialized as a type tag plus copied data; deserialization checks the same tag
and reconstructs each nested field. A `ReprEntryNative` is serialized and
deserialized through its native type tag and line data. The unknown-type branch
is outside this positive claim and is covered by PO-008.

PO-002 follows by induction over the finite traceback entry list. Base case:
the empty list serializes and deserializes to the empty list, preserving
`extraline` and `style`. Step case: PO-001 preserves the head entry, and the
induction hypothesis preserves the tail, so list order and metadata are
preserved.

PO-003 follows by case split. `None` maps to `None`; a crash location maps to a
plain data record and reconstructs the same path, line number, and message.

PO-004 follows from the serializer branch guarded by
`isinstance(rep.longrepr, ExceptionChainRepr) and len(rep.longrepr.chain) > 1`.
For each chain tuple `(reprtraceback, reprcrash, description)`, the serializer
stores exactly the serialized traceback, serialized crash, and description in
the same list order. It also emits top-level `reprtraceback`, `reprcrash`, and
`sections`, preserving compatibility fields.

PO-005 composes PO-001 through PO-004. The deserializer sees the `chain` key,
reconstructs every element in order, and passes that list into
`ExceptionChainRepr`. `ExceptionChainRepr.toterminal` iterates `self.chain` in
order and prints each element's description when present, so the reconstructed
object is terminal-equivalent to the original chain representation. Sections
are appended after reconstruction, preserving the existing section behavior.

PO-006 is the V2 compatibility repair. For a one-element `ExceptionChainRepr`,
the serializer does not emit `chain`, so deserialization takes the no-chain
branch and rebuilds `ReprExceptionInfo` from top-level `reprtraceback` and
`reprcrash`. A one-element `ExceptionChainRepr` and the rebuilt
`ReprExceptionInfo` print the same traceback plus sections, while the historical
single-exception deserialized shape is retained.

PO-007 is a frame condition. The `_to_json` branch for unstructured terminal
representations, raw longreprs, path normalization, and `result` clearing is not
changed by V2.

PO-008 follows by case split in `_deserialize_repr_entry`: the only supported
tags are `ReprEntry` and `ReprEntryNative`; all other tags call the same
failure function as before.

## Formal Core

The formal K core is in:

- `fvk/mini-pytest-report.k`
- `fvk/report-serialization-spec.k`

Expected machine-check commands, not executed here:

```sh
kompile fvk/mini-pytest-report.k --backend haskell
kast --backend haskell fvk/report-serialization-spec.k
kprove fvk/report-serialization-spec.k
```

Expected result after a real machine check: `kprove` discharges the claims to
`#Top`. Until then, the proof remains constructed, not machine-checked.

## Test Guidance

No tests were run and no test files were modified. Existing tests should be kept
until the K claims and pytest tests are run in a real execution environment.

Future public tests should cover:

- direct-cause chained exception round-trip preserves all exceptions;
- implicit-context chained exception round-trip preserves all exceptions;
- ordinary single-exception failure round-trip has no serialized `chain` key and
  preserves existing `reprtraceback`, `reprcrash`, and sections.

No test-removal recommendation is made because the proof was not
machine-checked.
