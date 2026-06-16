## Root cause

Pytest creates `Package` collectors from `__init__.py` files while traversing
directories so package-aware collection can work. In 5.2.3, `Package.collect()`
started calling `_mount_obj_if_needed()` before looking for collectable children.
That eagerly imports the package initializer even when the package contains no
matching test modules. As a result, unrelated package `__init__.py` files under
the collection root can execute and fail during collection.

## Files changed

`repo/src/_pytest/python.py`

Moved package initializer mounting out of `Package.collect()` and into
`Module.collect()` via `_mount_package_parents()`. This keeps package-level
marks from `__init__.py` available before functions are collected from real test
modules, but avoids importing package initializers for package collectors that
produce no test modules.

## Assumptions

Package `__init__.py` code should be imported when collecting a test module
inside that package, because Python would import the package as part of importing
the test module anyway. The important distinction is that merely discovering a
directory with `__init__.py` should not import it unless pytest proceeds to
collect a module inside the package.

Explicit collection of `__init__.py` is still controlled by the existing
`python_files` checks in `Package.collect()`. The change preserves the behavior
where `python_files = *.py` allows tests inside `__init__.py` to be collected.

I did not run tests or any code because the task instructions forbid execution
in this benchmark workspace.

## Alternatives considered

Removing `"__init__.py"` from the `pytest_collect_file()` pattern list would
stop many package collectors from being created, but it would also break
package-aware parent chains for direct file collection and other existing package
collection behavior.

Keeping the eager import and filtering only empty package directories in
`Session._collect()` would address the minimal reproduction, but it would still
be fragile for packages containing only non-test files or nested packages. The
selected change defers imports until an actual module collection path needs the
package metadata.
