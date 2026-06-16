# FVK Iteration Guidance

## Decision

V1 stands unchanged.

The audit found that V1 discharges the public issue's relevant obligations:

- PO3 confirms trailing ordinary comments no longer invalidate a closed inline script metadata
  block.
- PO5 confirms metadata comments selected by PO3 and PO4 cannot reach ERA001 detection.
- PO6 and PO7 confirm the change does not broaden suppression to unclosed blocks or unrelated
  comments.

## Next Code Action

No production source edit is recommended. The only source difference from baseline remains
`skip_script_comments` selecting the last delimiter in the valid embedded-content prefix.

## Recommended Future Test

Add a regression fixture after this constrained session:

```python
#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "rich-click",
#   "imagehash",
# ]
# ///
#
# Bla bla bla
#
#   $ ruff check --select ALL --ignore A001,D200,D203,D212 phototool
"""
Do important things.
"""
print(__doc__)
```

Expected behavior: `ruff check --select ERA001` emits no `ERA001` diagnostic for the inline script
metadata lines.

## Future Clarification If Scope Expands

The current public issue does not require suppressing ERA001 for ordinary comments after the closing
delimiter. If maintainers want all comments collected by the shared `ScriptTag::parse` scan to be
excluded from ERA001, PO4 should be revised and the source should skip through the first invalid
embedded-content line instead of only through the selected delimiter.
