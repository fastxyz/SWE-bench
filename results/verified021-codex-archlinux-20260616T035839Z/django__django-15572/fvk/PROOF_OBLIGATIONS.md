# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Direct empty string exclusion

For every `directory` from `backend.engine.dirs`, if `directory == ""`, then the
directory contributes no path to `items`.

Discharged by source: the direct `items.update()` comprehension includes
`if directory != ""` before `cwd / to_path(directory)`.

Finding trace: F1.

## PO2: Loader empty string exclusion

For every `directory` from `loader.get_dirs()`, if `directory == ""`, then the
directory contributes no path to `items` and is not normalized.

Discharged by source: the loader `items.update()` comprehension includes
`if directory != "" and not is_django_path(directory)` before
`cwd / to_path(directory)`.

Finding trace: F2.

## PO3: Preservation of valid non-empty backend dirs

For every non-empty value in `backend.engine.dirs` that `to_path()` accepts, the
contributed path remains `Path.cwd() / to_path(directory)`.

Discharged by source: when `directory != ""`, the post-fix expression is the
same normalization expression used before V1.

Finding trace: F3.

## PO4: Preservation of valid non-empty loader dirs and Django filtering

For every non-empty loader value, the pre-existing `not is_django_path(directory)`
filter still decides whether the normalized path is included.

Discharged by source: V1 conjoins the new empty-string guard with the existing
Django-path guard without changing the normalization expression.

Finding trace: F2, F3.

## PO5: `template_changed()` false-positive removal

If the only reason `Path.cwd()` would be present in the template directory set is
`DIRS = [""]`, then after V1 `Path.cwd()` is absent from that set. Therefore an
unrelated non-Python file merely under `Path.cwd()` does not satisfy
`template_dir in file_path.parents` from the empty-string contribution, and
`template_changed()` does not return `True` for that reason.

Discharged by PO1 and PO2 plus the unchanged loop in `template_changed()`.

Finding trace: F1, F2.

## PO6: Explicit current-directory paths remain in scope

For an explicit current-directory value such as `"."` or `Path(".")`,
`directory != ""` is true, so V1 does not silently remove it. This preserves the
existing normalized path behavior for intentional relative path settings.

Discharged by source: the guard tests equality with the exact empty string, not
truthiness and not normalized path identity.

Finding trace: F3.

