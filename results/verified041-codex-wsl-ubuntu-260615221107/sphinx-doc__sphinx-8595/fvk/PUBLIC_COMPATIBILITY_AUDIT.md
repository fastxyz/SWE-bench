# Public Compatibility Audit

Status: no public API or signature change.

## Changed symbol

`ModuleDocumenter.get_object_members(self, want_all: bool)`

Compatibility result:

- Signature unchanged.
- Return shape unchanged: still returns `(members_check_module, members)`.
- No caller update required.

## Public callsites and consumers

`Documenter.document_members()` consumes the return tuple and then calls
`filter_members()`.

Compatibility result:

- The type and shape of `members_check_module` and `members` remain unchanged.
- For empty explicit `__all__`, the returned members list is still a list of
  `ObjectMember` instances, preserving downstream event/filter behavior.

## Extension hooks

`autodoc-skip-member` remains reached through `filter_members()` for members
that are present in the returned list.

Compatibility result:

- V1 preserves this for empty explicit `__all__` by reusing the existing
  explicit-export branch rather than returning an immediate empty list.

## Options

- `ignore-module-all`: preserved because ignored `__all__` leaves
  `self.__all__ is None`.
- explicit `:members: name`: preserved because the edited condition is only in
  the `want_all` branch.
- non-empty `__all__`: preserved because the explicit-export branch body is
  unchanged.

No compatibility blockers found.
