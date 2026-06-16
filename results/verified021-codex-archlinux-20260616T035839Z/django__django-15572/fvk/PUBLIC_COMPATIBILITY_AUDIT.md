# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

No public function signatures, method signatures, return types, signal names, or
dispatch protocols were changed.

## Callers and consumers

`watch_for_template_changes()` still iterates over the set returned by
`get_template_directories()` and calls `sender.watch_dir(directory, "**/*")`.
The directory element type remains a `Path` value for included entries.

`template_changed()` still calls `get_template_directories()` and compares each
template directory to `file_path.parents`. Its return shape remains `True` for
handled template changes and `None` otherwise.

## Compatibility result

The patch changes only membership of the returned directory set for the invalid
empty string. Existing valid non-empty string and `Path` values keep the same
normalization path and observable type.

