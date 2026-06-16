# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1 - Legacy value-only collection misses the reported type hint

Input:

```python
class C(object):
    def __init__(self, a: str = None):
        self.a = a
```

Observed before the fix: `handle_assignattr_type` used only
`AssignAttr.infer()`. With a `None` default, the collected values can contain
only `None` or an uninferable value, so `ClassDiagram.class_names` has no
displayable type for `a`.

Expected from E1/E2/E3: the annotation `str` contributes a displayable type,
allowing output like `a : str` / `a : String`.

Resolution: V1 addresses this by adding the annotated parameter's inferred type
to `instance_attrs_type` for direct assignments such as `self.a = a`. Covered by
PO1 and PO4.

## F2 - Annotated assignment path had the same value-only gap

Input class of interest:

```python
self.a: str = None
a: str = None
```

Observed before the fix: the assignment value `None` could dominate the
inference result and the annotation was not consulted.

Expected from E1: annotations should contribute to UML type collection.

Resolution: V1 also adds `AnnAssign.annotation` inference for `AssignName` and
`AssignAttr` targets. Covered by PO2 and PO3.

## F3 - Full PEP 484 expression rendering remains outside the proven scope

Input class of interest:

```python
from typing import Optional

class C:
    def __init__(self, a: Optional[str] = None):
        self.a = a
```

Observed from the audit: V1 relies on astroid inference of the annotation node
and continues to feed resulting nodes into existing pyreverse rendering. It does
not add a new textual renderer for complex type expressions.

Expected from public evidence: the concrete issue requires directly inferable
annotation support for `a: str = None`. The broader phrase "PEP 484" suggests
future coverage may be useful, but the issue does not specify exact UML output
for complex annotations.

Resolution: no source change in this FVK pass. Keep this as a test/spec gap if
the project wants full type-expression rendering later. Covered by PO7.

## F4 - V1 preserves public compatibility

Input/callsite class of interest: existing calls to
`handle_assignattr_type(assignattr, node)` and downstream consumers of
`instance_attrs_type` / `locals_type`.

Observed from the audit: V1 adds private helpers and keeps the existing method
signatures and node-list map shape.

Expected from frame conditions: no public API or map-shape break.

Resolution: V1 stands. Covered by PO5 and PO6.

## Proof-Derived Findings From `/verify`

No code bug was derived from the constructed proof obligations. The only open
proof-derived item is F3, a deliberate scope boundary: the proof confirms the
reported direct-annotation path, not full PEP 484 textual formatting.
