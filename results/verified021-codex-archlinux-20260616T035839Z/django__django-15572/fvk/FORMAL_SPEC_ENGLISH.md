# Formal Spec English

Status: constructed, not machine-checked.

## Claims

C1. For each directory value from `backend.engine.dirs`, `get_template_directories()`
adds `Path.cwd() / to_path(value)` if and only if `value != ""`.

C2. For each directory value from a loader `get_dirs()`, `get_template_directories()`
adds `Path.cwd() / to_path(value)` if and only if `value != ""` and
`is_django_path(value)` is false.

C3. If the only configured template directory contribution is the empty string,
then `get_template_directories()` does not contain `Path.cwd()` from that
contribution, and `template_changed()` does not return `True` for an unrelated
non-Python file merely because that file is under `Path.cwd()`.

C4. For any non-empty value that was accepted by the previous normalized path
logic, the normalized output path is unchanged by the fix.

C5. Invalid non-empty values are not converted into silent skips by this fix;
they still flow into the existing validation/conversion path.

