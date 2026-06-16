# FVK Proof

Status: constructed, not machine-checked. This proof was not run through K,
Python, or the test suite.

## Claims proved at the source level

The proof targets the observable property: a path ignored by configured
`ignore-paths` must not become a linted `FileItem`, including when recursive
discovery creates mixed path separators.

The constructed K-style claims are in `fvk/pylint-ignore-paths-spec.k`; the
mini-semantics are in `fvk/mini-pylint-ignore.k`.

## Proof sketch

1. Raw-match preservation. `_is_in_ignore_list_re_with_normalized_path` first
   calls `_is_in_ignore_list_re(element, ignore_list_re)` and returns `True` if
   it succeeds. Therefore every pre-existing raw regex match remains an ignore
   match. This proves PO-001.

2. Normalized fallback. If raw matching fails, the helper computes
   `os.path.normpath(element).replace("\\", "/")` and retries the same regex
   list. For the issue-shaped candidate `src/gen\about.py`, the normalized
   candidate is `src/gen/about.py`, so the configured pattern `^src/gen/.*$`
   matches. Because `_is_ignored_file` uses this helper for `ignore-paths`, the
   candidate is ignored. This proves PO-002.

3. Basename frame condition. `_is_ignored_file` retains the original basename
   membership and basename-regex disjuncts before the path-regex disjunct. The
   patch only changes the path-regex predicate. This proves PO-003.

4. Resolved-file emission. In `expand_modules`, the resolved `filepath` is
   normalized and assigned to `is_ignored` through `_is_ignored_file`. The only
   append for the resolved module is guarded by `not is_namespace and not
   is_ignored`. Thus an ignored direct file, module-resolved file, or package
   `__init__.py` is not emitted as a module description. This proves PO-004.

5. Package traversal precision. V1 failed this proof because it used `continue`
   after detecting an ignored resolved file. V2 removes that `continue`. The
   package traversal condition `has_init or is_namespace or is_directory` is
   evaluated after the guarded append, and every `subfilepath` is checked with
   `_is_ignored_file` before emission. Thus ignoring `pkg/__init__.py` suppresses
   that module while still allowing nonignored `pkg/sub.py`; a directory-wide
   pattern such as `^src/gen/.*$` suppresses every generated subfile
   independently. This proves PO-005.

6. Recursive call chain. `PyLinter.check` materializes recursive discovery, but
   `_check_file` is reached only through `_iterate_file_descrs`, which delegates
   to the patched `expand_modules`. Therefore the observable linting boundary is
   post-expansion, and no ignored module description reaches `_check_file`. This
   proves PO-006.

7. Compatibility and honesty. The patch changes no function signatures or config
   option names, does not modify tests, and the proof commands below were not
   executed. This proves PO-007.

## Machine-check commands for later

These commands were intentionally not run in this session:

```sh
kompile fvk/mini-pylint-ignore.k --backend haskell
kast --backend haskell fvk/pylint-ignore-paths-spec.k
kprove fvk/pylint-ignore-paths-spec.k
```

Expected result after adapting the mini-semantics to a local K installation:
`kprove` should discharge the claims to `#Top`. Until then, the proof remains
constructed, not machine-checked.

## Test guidance

No tests are removed. Existing recursive-ignore tests should be kept until the
proof is machine-checked. Additional tests are recommended in
`fvk/ITERATION_GUIDANCE.md` because the current public tests cover broad
`ignore-paths` patterns but not the anchored mixed-separator case or the
package-precision case found by the audit.
