# Public Compatibility Audit

Status: no compatibility break found.

Changed public symbol: none.

Changed implementation location:

- `ConciseDateFormatter.format_ticks` in `repo/lib/matplotlib/dates.py`.

Compatibility checks:

- Method signature unchanged.
- Return type unchanged: still a list of labels.
- `get_offset()` storage location unchanged: still `self.offset_string`.
- `show_offset` parameter semantics preserved by PO-005.
- TeX wrapping path preserved by PO-007.
- No subclass/override dispatch shape changed.
- No public tests or test helpers modified.

