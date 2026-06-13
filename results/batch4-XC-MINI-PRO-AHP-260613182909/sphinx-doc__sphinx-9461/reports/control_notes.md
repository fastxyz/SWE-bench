# Control notes — V2 review outcome for sphinx-doc__sphinx-9461

This round audited the V1 fix (see `review/FINDINGS.md`). The conclusion is that
V1 is correct and complete for the reported issue; exactly **one** zero-risk
consistency edit was made, and two edge cases were deliberately left out of scope
with documented rationale. Each decision below is traced to numbered findings.

## Code change made

### C1 — `import_object`: `self.objpath[-1]` → `self.object_name`
File: `sphinx/ext/autodoc/__init__.py`, `PropertyDocumenter.import_object`.
Trace: **F6**. `MethodDocumenter` performs the identical "raw descriptor from the
owner's `__dict__`" lookup using `self.object_name`; V1 used `self.objpath[-1]`.
The two are equal in the reachable path (after a successful `super().import_object`,
`object_name` is the last `objpath` element), so this is a behavior-preserving
consistency fix that aligns `PropertyDocumenter` with its sibling. No other
behavior changes.

## Decisions to keep V1 unchanged

### K1 — Root-cause fix stays in `get_class_members`
Trace: **F1, F2, F12**. The review re-confirmed that `filter_members` runs before
documenter selection and drops docstring-less members, so the property must be
surfaced during member collection. The V1 unwrap (`isinstance(raw, classmethod)
and isproperty(raw.__func__)` → use `raw.__func__`) is the minimal root-cause fix
and triggers for no other member kind (F12). Kept as-is.

### K2 — `PropertyDocumenter.can_document_member` fallback kept
Trace: **F1, F4**. The `else` branch (inspecting `parent.object.__dict__`) is a
defensive net for the case where the member reaching the documenter is a raw
`classmethod` rather than the already-unwrapped property. The review verified it
is safe for every non-property member because `Documenter.__init__` defaults
`self.object = None`, so the autosummary "fake parent" path returns `{}`/`None`
cleanly with no `AttributeError`. Kept.

### K3 — `import_object` returns `False` on a `__dict__` miss
Trace: **F5**. Returning `False` (rather than proceeding with the computed value)
is correct: the computed value is not a property, so documenting it would yield a
wrong signature/docstring. The only situation this drops a member is a *private*
(name-mangled) classmethod-property under `:private-members:` — which (a) is not a
regression (it was dropped pre-fix too), (b) is astronomically rare, and (c)
mirrors the codebase's existing non-mangling descriptor lookups (e.g.
`MethodDocumenter`). Adding `mangle()` handling would expand scope beyond the
issue, so V1's behavior is kept and the limitation is documented.

### K4 — No `isclassmethod` class-level default
Trace: **F7**. `self.isclassmethod` is always assigned by `import_object` before
`add_directive_header` can run (generate aborts if `import_object` fails). Adding a
class attribute would be inconsistent with how the codebase initializes documenter
state. Kept.

### K5 — No MRO walk for inherited classmethod-properties
Trace: **F14**. Inherited classmethod-properties under `:inherited-members:` are
out of the issue's scope (the issue documents each class's own members). An MRO
walk would add complexity for an unrequested case. Kept.

### K6 — Abstract / `:type:` / option-ordering / prefix unchanged
Trace: **F8, F9, F10, F11**. Verified correct for standard usage: abstract
detection works via `property.__isabstractmethod__`; `:type:` derives from
`fget`'s return annotation exactly like an ordinary property; option emission
order and the `class property` / `class abstract property` prefix are consistent
with `PyMethod` and the pre-existing abstract-property behavior. No edits.

### K7 — Autosummary needs no separate change
Trace: **F3**. Autosummary consumes the same `get_class_members`, so the V1 change
also corrects its classification of classmethod-properties; the surrounding
`__module__`/`imported` checks are unaffected. No edit.

### K8 — Docs/CHANGES left as written
Trace: **F15**. `:classmethod:` documented with `versionadded:: 4.2`; changelog
entries present. The feature-vs-bugfix classification is a non-test-relevant
judgment call. Kept.

## Net effect
One token-level consistency edit (C1). The substance of V1 — surfacing the
property in `get_class_members`, recovering it in `PropertyDocumenter`, emitting
`:classmethod:`, and teaching `py:property` the option — stands, justified by the
review findings.
