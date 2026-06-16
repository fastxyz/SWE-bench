# Public Compatibility Audit

Status: pass.

Changed public callback: `_skip_member(app, what, name, obj, skip, options)`.

The callback signature is unchanged. The return protocol is unchanged:
`False` force-includes a member and `None` leaves autodoc's default decision in
place. No caller must pass new arguments, and no public return type is added.

New private helper: `_get_class_from_qualname(obj, cls_path)`.

The helper is internal to `sphinx.ext.napoleon.__init__` and is not connected to
Sphinx events or public extension APIs. It preserves the old top-level
`obj.__globals__[cls_path]` behavior as a fallback when module+qualname
resolution fails for a non-dotted class path.

New import: `sphinx.util.inspect.unwrap`.

This imports an existing Sphinx utility already used elsewhere in the project.
It is used only to inspect class wrappers that follow the standard
`__wrapped__` convention; it does not alter callable signatures or autodoc
event dispatch.

Public callsites searched:

- `setup()` connects `_skip_member` to `autodoc-skip-member`.
- `sphinx.ext.autodoc` emits that event with the same arguments.
- `sphinx.ext.autosummary.generate` emits that event with the same arguments.
- Visible Napoleon tests call `_skip_member` directly with the same signature.

No public callsite or override requires an update.
