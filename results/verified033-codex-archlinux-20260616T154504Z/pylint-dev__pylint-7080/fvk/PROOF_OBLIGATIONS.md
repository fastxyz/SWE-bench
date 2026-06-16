# FVK Proof Obligations

Status legend: `discharged by source inspection` means the obligation is
supported by the current source and constructed proof, but was not
machine-checked.

## PO-001: Raw regex behavior is preserved

Linked findings: F-001.

Claim: for any `element` and `ignore_list_re`, if `_is_in_ignore_list_re(element,
ignore_list_re)` is true, then
`_is_in_ignore_list_re_with_normalized_path(element, ignore_list_re)` is true.

Source evidence: the helper first checks `_is_in_ignore_list_re(element,
ignore_list_re)` and immediately returns `True`.

Status: discharged by source inspection.

## PO-002: Normalized path fallback catches mixed separators

Linked findings: F-001.

Claim: for any path `p`, if `norm(p) = os.path.normpath(p).replace("\\", "/")`
matches an `ignore-paths` pattern, then `_is_ignored_file(p, ..., ignore_paths)`
returns true unless basename checks already returned true.

Source evidence: `_is_in_ignore_list_re_with_normalized_path` computes
`normalized_element = os.path.normpath(element).replace("\\", "/")` and retries
the same regex list against it. `_is_ignored_file` uses this helper for
`ignore_list_paths_re`.

Concrete symbolic case: `p = "src/gen\\about.py"`, `norm(p) =
"src/gen/about.py"`, pattern `^src/gen/.*$`; normalized matching is true, so the
candidate is ignored.

Status: discharged by source inspection.

## PO-003: Basename ignore semantics are unchanged

Linked findings: F-001.

Claim: `basename in ignore` and `ignore-patterns` basename regex matching still
cause `_is_ignored_file` to return true.

Source evidence: `_is_ignored_file` still computes `basename =
os.path.basename(element)` and keeps the existing first two disjuncts:
`basename in ignore_list` and `_is_in_ignore_list_re(basename, ignore_list_re)`.

Status: discharged by source inspection.

## PO-004: Ignored resolved files are not emitted as module descriptions

Linked findings: F-001, F-002.

Claim: after `expand_modules` resolves a file or package to `filepath`, if
`is_ignored` is true and the module is not a namespace, no result entry is
appended for that resolved file.

Source evidence: V2 computes `is_ignored = os.path.exists(filepath) and
_is_ignored_file(filepath, ...)`; the result append is guarded by `if not
is_namespace and not is_ignored`.

Status: discharged by source inspection.

## PO-005: Ignored package `__init__.py` does not suppress independent submodule filtering

Linked findings: F-002.

Claim: when a resolved package `__init__.py` is ignored, `expand_modules` still
enters the package traversal branch if `has_init` is true, and each `subfilepath`
is filtered independently with `_is_ignored_file`.

Source evidence: V2 no longer `continue`s on `is_ignored`. The `has_init` test is
computed after the guarded append, and the loop remains `if has_init or
is_namespace or is_directory`. Inside the loop, V2 calls `_is_ignored_file` for
each `subfilepath`.

Status: discharged by source inspection.

## PO-006: Recursive linting consumes only post-expansion `FileItem`s

Linked findings: F-001, F-003.

Claim: in recursive mode, a discovered ignored file cannot reach `_check_file`.

Source evidence: `PyLinter.check` replaces `files_or_modules` with
`tuple(self._discover_files(...))`, then calls `_check_files(self.get_ast,
self._iterate_file_descrs(files_or_modules))`. `_iterate_file_descrs` yields
only descriptors returned by `_expand_files`, and `_expand_files` delegates to
the patched `expand_modules`.

Status: discharged by source inspection.

## PO-007: Honesty and compatibility obligations

Linked findings: F-004.

Claim: the patch changes no public API and makes no machine-checked proof claim.

Source evidence: only `repo/pylint/lint/expand_modules.py` is edited; function
signatures and option names remain unchanged. The FVK artifacts label the proof
as constructed, not machine-checked, and provide commands rather than executing
them.

Status: discharged by source inspection.
