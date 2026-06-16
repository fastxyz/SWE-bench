# Public Compatibility Audit

## Changed Symbol: `KeyboardTransform.run`

Signature: unchanged (`def run(self, **kwargs: Any) -> None`).

Public call shape: unchanged. The Sphinx post-transform framework still calls
`run()` in the same way.

Observable compatibility: ordinary compound examples remain covered by PO-3.

Status: compatible.

## Added Helper: `KeyboardTransform.split_keys`

Signature: new internal helper (`def split_keys(self, text: str) ->
List[Tuple[str, str]]`).

Public call shape: no public callsites changed. The helper is used only by
`KeyboardTransform.run()`.

Status: compatible.

## Added Helper: `KeyboardTransform.is_separator`

Signature: new internal helper (`def is_separator(self, char: str) -> bool`).

Public call shape: no public callsites changed. The helper is used only by
`KeyboardTransform.split_keys()`.

Status: compatible.

## Unchanged Public Surfaces

- `setup(app)` still registers `KeyboardTransform` only.
- The transform remains limited to HTML builders through `builders = ('html',)`.
- The role registration in `repo/sphinx/roles.py` is unchanged.
- HTML writer classes are unchanged.
- LaTeX/text/other non-HTML output paths are unchanged.

Status: no unhandled compatibility issue found.
