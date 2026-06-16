# FVK Specification: autodoc empty `__all__`

Status: constructed for audit, not machine-checked.

## Unit under audit

Primary source unit: `repo/sphinx/ext/autodoc/__init__.py`,
`ModuleDocumenter.get_object_members()`.

Downstream observable unit: `Documenter.filter_members()`, specifically its
forced-skip handling for `ObjectMember.skipped`.

The modeled observable is whether `automodule` with `:members:` and no user
skip-event override emits module members by default.

## Public intent ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "autodoc: empty `__all__` attribute is ignored" | Empty explicit `__all__` is a boundary case and must not be treated as absent. | Encoded in claims `EMPTY-ALL-BRANCH` and `EMPTY-ALL-FILTER`. |
| I2 | prompt | Reproducer has `__all__ = []` and `.. automodule:: example` with `:members:`. | For `want_all == True`, an explicit empty export list is in-domain. | Encoded in precondition-free empty-sequence claims. |
| I3 | prompt | "Expected behavior: No entries should be shown because `__all__` is empty." | With no user event override, every module member is forced skipped and the final filtered member list is empty. | Encoded in `EMPTY-ALL-FILTER`. |
| I4 | source/public test | `inspect.getall()` returns `None` only when no `__all__` exists, and otherwise returns a valid list/tuple of strings. | Missing/ignored/invalid `__all__` and explicit empty sequence are distinct states. | Encoded as `AllState = noAll | exports(Names)`. |
| I5 | public test | `test_autodoc_ignore_module_all` expects `ignore-module-all` to document implicit members. | If `__all__` is absent or ignored, autodoc keeps the implicit member path and asks later checks to filter imported members. | Encoded in `NO-ALL-BRANCH`. |
| I6 | public test | `test_skip_module_member` shows `autodoc-skip-member` can show a member not in `__all__`. | The fix must preserve the existing extension point; forced skipped members may still be overridden by user skip-event logic. | Recorded as compatibility/frame condition, not modeled as default issue behavior. |

## Intent-derived contract

For `ModuleDocumenter.get_object_members(want_all=True)`:

1. If `self.__all__ is None`, return `(True, members)`.
   This is the absent/ignored `__all__` path and preserves imported-member
   checking.
2. If `self.__all__` is any valid explicit sequence, including an empty list or
   tuple, return `(False, members')`, where each member whose name is not in the
   sequence has `skipped = True`.
3. For `self.__all__ = []`, every member name is not in the sequence, so every
   returned member has `skipped = True`.
4. Under the default skip policy in `filter_members()` with no user event
   override, every forced-skipped member is omitted from the documented output.
   Therefore `:members:` on a module with `__all__ = []` emits no module-member
   entries.

Frame conditions:

1. Explicit member lists (`want_all=False`) are not changed by this issue fix.
2. `ignore-module-all` remains represented as `self.__all__ is None`, preserving
   implicit member behavior.
3. Non-empty `__all__` behavior is unchanged except that the same explicit-list
   branch now also covers empty explicit lists.
4. User `autodoc-skip-member` event overrides remain a supported extension
   point; the issue reproducer does not install such an override.

## K artifact mapping

`fvk/mini-python.k` models the relevant Python/autodoc fragment:

- `AllState`: `noAll` for absent/ignored/invalid `__all__`, or
  `exports(Names)` for any valid explicit sequence.
- `Members`: module members with a forced-skip Boolean.
- `getObjectMembers(WantAll, AllState, Members, Selected)`: abstracted
  semantics of `ModuleDocumenter.get_object_members()`.
- `filterMembers(Members)`: abstracted default forced-skip filter.

`fvk/autodoc-module-all-spec.k` contains the claims:

- `NO-ALL-BRANCH`: absent/ignored `__all__` keeps the implicit path.
- `EXPLICIT-ALL-BRANCH`: explicit sequence marks non-exported members skipped.
- `EMPTY-ALL-BRANCH`: empty explicit sequence is handled by the explicit path.
- `EMPTY-ALL-FILTER`: after default filtering, an empty explicit sequence yields
  no documented members.
- `EXPLICIT-MEMBERS-FRAME`: explicit `:members: name` selection is unchanged.

## Adequacy statement

The model intentionally abstracts away object import, signature formatting,
docstring extraction, and rendering, because they do not decide whether an empty
explicit `__all__` is treated as missing. The model preserves the property under
test: it distinguishes the failing branch (`noAll`, returning unskipped members)
from the fixed branch (`exports(.Names)`, returning all members forced skipped).
