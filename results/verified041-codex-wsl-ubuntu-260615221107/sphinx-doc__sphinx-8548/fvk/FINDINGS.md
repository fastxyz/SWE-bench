# FVK Findings

Status labels:

- Resolved in V2: code was changed during this FVK pass.
- Confirmed: V1 behavior is retained and justified.
- Residual: noted risk or gap, not changed because public intent does not require
  a different behavior.

## F-001: V1 widened base Documenter virtual dispatch

Status: Resolved in V2.

Evidence:

- V1 added `Documenter.get_attribute_comment()` and made
  `Documenter.add_content()` call `self.get_attribute_comment()`.
- FVK compatibility rule: changed public or virtual dispatch shape must be
  audited for public subclasses/overrides.

Observed vs expected:

- Observed V1: every `Documenter` subclass would receive a new virtual no-arg
  call during `add_content()`.
- Expected by I5: only attribute documentation needs inherited class comment
  fallback; unrelated documenters should keep the previous base behavior.

Decision:

- Removed the base `Documenter` hook from V2.
- Kept the inherited fallback in `AttributeDocumenter.add_content()` only.

Trace:

- Discharges PO-6.

## F-002: V1 could attach a base comment to an overridden subclass attribute

Status: Resolved in V2.

Evidence:

- Public intent says inherited attributes need inherited comments.
- Python default-domain convention says subclass definitions shadow base
  definitions by MRO.

Concrete input:

```python
class Base:
    #: base doc
    ham = True

class Inherited(Base):
    ham = False
```

Observed vs expected:

- Observed V1 risk: explicit `autoattribute:: Inherited.ham` could miss the
  current namespace and fall back to `Base.ham`'s comment.
- Expected: no inherited comment should be used, because `Inherited.ham` is not
  the inherited `Base.ham` member.

Decision:

- Added `_get_class_member_owner()` and made `get_class_attr_doc()` return a
  base comment only for the MRO owner of the member. If the owner has no comment,
  fallback to older bases is blocked.

Trace:

- Discharges PO-2 and PO-4.

## F-003: Inherited instance-only attributes remain outside this fix

Status: Residual, not a code bug for this task.

Evidence:

- The public issue discussion separates inherited instance attributes into a
  related issue and states they are not supported yet.
- V1 and V2 still synthesize missing comment-only instance attributes only for
  the class currently being documented.

Observed vs expected:

- Observed: `Base.__init__` comment-only `self.ham` is not newly added to
  `Inherited`'s member list by this patch.
- Expected for this issue: inherited runtime/data attributes and explicit
  attribute directives are fixed; inherited instance-only synthesis is not
  required by the active issue scope.

Decision:

- Preserve the narrow synthesis behavior.

Trace:

- Covered by PO-7 and the frame condition E7.

## F-004: FVK proof is constructed, not machine-checked

Status: Residual honesty gate.

Evidence:

- The task forbids K tooling, tests, Python execution, and command execution for
  verification.

Observed vs expected:

- Observed: no `kompile`, `kast`, `kprove`, unit tests, or Sphinx builds were run.
- Expected: artifacts contain the exact commands and reasoned expected result
  instead.

Decision:

- Keep all test-removal recommendations conditional on future machine checking.

Trace:

- Covered by PO-8.

