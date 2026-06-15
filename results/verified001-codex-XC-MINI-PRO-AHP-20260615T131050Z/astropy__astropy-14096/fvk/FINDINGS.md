# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1: Legacy SkyCoord fallback masked the inner AttributeError

Classification: code bug fixed by V1 and preserved by V2.

Input:

- A `SkyCoord` subclass defines `@property prop`.
- `prop` evaluates `self.random_attr`.
- `random_attr` is not present.

Observed legacy behavior:

- Python calls `SkyCoord.__getattr__("prop")` after the property getter raises
  `AttributeError`.
- The final exception says the subclass object has no attribute `prop`.

Expected behavior:

- The final exception should identify `random_attr`, matching the actual missing
  attribute inside the property.

Evidence:

- Public issue text explicitly states that `prop` is misleading and
  `random_attr` should be reported.

Related proof obligations:

- PO1, PO3.

Resolution:

- V2 stores the original `AttributeError` when normal lookup fails through a
  custom subclass property and re-raises it from `__getattr__`.

## F2: V1 re-entered the property and could evaluate it twice

Classification: code bug introduced by V1 audit; fixed in V2.

Input:

- A custom subclass property mutates state, logs, caches, or otherwise has an
  observable action before raising `AttributeError`.

Observed V1 behavior:

- Normal Python lookup invokes the property once.
- V1 then calls `descriptor.__get__` again inside `SkyCoord.__getattr__`.
- The property body can run twice for one `c.prop` access.

Expected behavior:

- A normal attribute access path should not replay the property just to recover
  the original error.

Evidence:

- V1 diff in `reports/baseline_notes.md` and source showed direct descriptor
  re-entry from `__getattr__`.

Related proof obligations:

- PO1, PO2, PO5.

Resolution:

- V2 captures the first `AttributeError` in `__getattribute__` and re-raises that
  saved exception from `__getattr__`; `__getattr__` no longer invokes the
  property descriptor.

## F3: V1's subclass-property scan stopped too early in the MRO

Classification: completeness bug in V1's intended subclass-property domain;
fixed in V2.

Input:

- A `SkyCoord` subclass obtains a custom property from another user-defined base
  class or mixin.
- The first MRO provider for the attribute is outside `SkyCoord.__mro__`.

Observed V1 behavior:

- V1 stopped scanning when it reached `SkyCoord`.
- A custom property supplied later in the MRO could be missed, allowing the
  misleading SkyCoord fallback to remain.

Expected behavior:

- The decision should follow Python's first MRO provider for the attribute:
  intercept custom property providers outside the `SkyCoord` hierarchy, but do
  not intercept `SkyCoord`'s own properties.

Evidence:

- FVK full-domain audit of "subclassed SkyCoord with custom properties" plus the
  default Python MRO convention.

Related proof obligations:

- PO4.

Resolution:

- V2 scans the full MRO for the first class defining the attribute and only
  treats it as a custom property if that provider is outside `SkyCoord.__mro__`.

## F4: Descriptor scope is intentionally limited to `property`

Classification: residual scope decision, not a code bug under the public issue.

Input:

- A subclass uses a non-`property` descriptor whose `__get__` raises
  `AttributeError`.

Observed behavior after V2:

- V2 does not special-case that descriptor family.

Expected behavior under current public intent:

- The issue reproducer and wording identify `@property` custom properties, so
  the verified domain is Python `property` descriptors.

Related proof obligations:

- PO1 domain clause, PO4 domain clause.

Resolution:

- No source change. If future public intent requires arbitrary descriptors, add
  a new proof obligation and expand the helper accordingly.

## F5: Proof and tests remain unexecuted by task constraint

Classification: verification capability constraint.

Observed:

- No tests, Python snippets, `kompile`, or `kprove` were run.

Expected:

- Artifacts include exact commands and constructed proof reasoning only.

Related proof obligations:

- All obligations are constructed, not machine-checked.

Resolution:

- Keep test removal at "none recommended" and label proof status honestly.

