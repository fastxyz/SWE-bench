# Baseline Notes

## Root Cause

Pyreverse records displayed attribute types through `Linker.instance_attrs_type`
and `Linker.locals_type`. Both maps were populated only from astroid value
inference on assignment nodes. For an assignment such as `self.a = a` where
`a` is annotated as `str` but has a default value of `None`, the assignment
inference can only see `None` or an uninferable value. The annotation on `a`
was never consulted, so the class diagram had no useful type to display for
`a`.

The same value-only path also meant annotated assignments such as
`self.a: str = None` or `a: str = None` could lose their annotation when the
assigned value was not informative.

## Files Changed

`repo/pylint/pyreverse/inspector.py`

- Added small helpers for inferring an annotation node, finding the annotation
  attached to an `AnnAssign`, and finding the annotation for a function
  parameter name.
- Updated local assignment handling so annotated assignments contribute their
  annotation-inferred type in addition to the assigned value's inferred type.
- Updated instance attribute handling so pyreverse keeps existing value
  inference and also adds type information from `self.attr: Type` annotations
  and from assignments of annotated parameters such as `self.attr = attr`.

## Assumptions

- The existing diagram code should continue to decide how inferred nodes are
  rendered. The fix therefore feeds annotation-derived `ClassDef` or `Instance`
  nodes into the existing `locals_type` and `instance_attrs_type` maps instead
  of adding a separate string formatting path.
- A direct assignment from a parameter name, for example `self.a = a`, is the
  intended propagation point for constructor and method parameter annotations.
  More complex expressions such as `self.a = factory(a)` were left to normal
  inference because mapping those back to parameter annotations would be
  speculative.
- Annotation inference can fail in the same way value inference can fail. In
  that case pyreverse should keep the previous best-effort behavior and simply
  omit annotation-derived values.

## Alternatives Considered

- Formatting annotation strings directly in `diagrams.py` was rejected because
  it would bypass the existing association extraction and class-name filtering.
  Keeping the type data as astroid nodes lets associations to user-defined
  annotated classes work through the current code path.
- Replacing value inference with annotation inference was rejected because
  existing diagrams already derive useful types from assigned values such as
  `self.relation = DoNothing()`. The fix augments rather than replaces that
  behavior.
