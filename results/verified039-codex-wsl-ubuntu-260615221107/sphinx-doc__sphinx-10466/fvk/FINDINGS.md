# Findings

Status: constructed, not machine-checked.

## F1 - V1 Satisfies The Duplicate Location Intent

Classification: confirmed source behavior.

Input shape:

```text
metadata["Type"] = [
  ("/cwd/manual/modeling/hair.rst", 0, "u1"),
  ("manual/modeling/hair.rst", 0, "u2"),
  ("/cwd/build/gettext/../../manual/modeling/hair.rst", 0, "u3")
]
```

Observed in V1 by code inspection:

- `Catalog.__iter__()` normalizes each source to `canon_path(relpath(source))`.
- `Message.__init__()` stores `_unique_locations(locations)`.
- The normalized location `(manual/modeling/hair.rst, 0)` is retained once.

Expected by intent:

- The rendered POT output has one `#: ../../manual/modeling/hair.rst:0` line
  for this message, not three.

Trace: PO1, PO3, PO4, PO5, PO6.

Recommended action: no source change beyond V1.

## F2 - Babel Wrapping And Sorting Suggestions Are Adjacent, Not Required

Classification: scope decision.

The problem text contains additional observations about `babel/messages/pofile.py`
wrapping and optional sorting. The core reported Sphinx issue is duplicate
`Message.locations` output through `sphinx/builders/gettext.py`, and the public
hint localizes the necessary fix to `Message.__init__()` and `Catalog.__iter__()`.

Trace: E10, PO1, PO7.

Recommended action: do not modify Babel writer behavior or message sorting in
this patch.

## F3 - UUID Comments Are Not Part Of The Proven Duplicate-Location Contract

Classification: residual ambiguity/out of scope.

V1 preserves the `uuids` list exactly. If `gettext_uuid` is enabled, UUID comment
lines are emitted independently from location comment lines. The issue examples
and expected behavior discuss duplicate file/line locations, not UUID comment
identity.

Trace: PO7.

Recommended action: no UUID de-duplication without a separate public intent
source.

## F4 - Proof Is Constructed, Not Machine-Checked

Classification: proof capability/honesty boundary.

No tests, Python code, or K tooling were executed. The proof package includes
the commands that a later environment could run to machine-check the claims.

Trace: PO8.

Recommended action: keep any existing tests. Do not remove tests based only on
this constructed proof.

## F5 - No Public Compatibility Blocker Found

Classification: compatibility confirmation.

V1 adds a private helper and changes no public signatures. `Message.__init__()`
still accepts the same arguments; `Catalog.__iter__()` still yields `Message`
objects in message insertion order.

Trace: PO7 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Recommended action: no compatibility source change.
