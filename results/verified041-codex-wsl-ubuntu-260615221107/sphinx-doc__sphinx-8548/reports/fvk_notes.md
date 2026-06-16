# FVK Notes

## Decisions

D1. Keep the V1 core idea of searching base-class attribute comments.

Trace:

- Finding: none against the core behavior.
- Proof obligations: PO-1, PO-3, PO-4, PO-5.
- Reason: public evidence E1-E5 requires inherited class/data attributes and
  explicit `autoattribute` to use base-class comment docs.

D2. Revise V1 to avoid a new base `Documenter` virtual hook.

Trace:

- Finding: F-001.
- Proof obligation: PO-6.
- Change: restored the original direct-comment shape of `Documenter.add_content()`
  and moved inherited fallback into `AttributeDocumenter.add_content()`.
- Reason: only attribute documenters need the inherited comment fallback; changing
  the base documenter dispatch surface is broader than the issue intent.

D3. Add MRO owner gating for inherited comments.

Trace:

- Finding: F-002.
- Proof obligations: PO-2 and PO-4.
- Change: added `_get_class_member_owner()` and made `get_class_attr_doc()` stop
  at the runtime/annotation owner of the member.
- Reason: Python MRO owner semantics require subclass overrides and earlier bases
  to block comments from later bases.

D4. Keep inherited instance-only synthesis out of scope.

Trace:

- Finding: F-003.
- Proof obligation: PO-7.
- Change: none beyond preserving the existing `cls == subject` synthesis guard.
- Reason: the public issue distinguishes inherited instance-only attributes as a
  related but separate behavior; broadening this fix would need a separate intent
  decision about superclass cutoff semantics.

D5. Do not run tests, Python, or K tooling.

Trace:

- Finding: F-004.
- Proof obligation: PO-8.
- Change: none.
- Reason: the task explicitly forbids execution. The artifacts include commands
  and expected outcomes for later checking instead.

## Files Changed in V2

- `repo/sphinx/ext/autodoc/importer.py`: adds class/MRO attribute doc helpers,
  records owner classes for inherited runtime members, attaches comments only
  from the defining class, and blocks fallback to older bases when an override
  has no comment.
- `repo/sphinx/ext/autodoc/__init__.py`: imports the helper, treats injected
  ObjectMember docstrings as attribute docs during filtering, and adds inherited
  comment fallback only to `AttributeDocumenter.add_content()`.
- `fvk/*`: records the specification, findings, obligations, constructed proof,
  and iteration guidance.

## Verification Status

Static checks only. `git diff --check` was run. No test suite, Python code, Sphinx
build, or K command was run.

