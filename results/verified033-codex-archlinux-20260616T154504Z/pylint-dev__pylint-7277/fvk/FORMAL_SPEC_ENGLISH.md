# Formal Spec English

The K files are `mini-python-syspath.k` and `modify-sys-path-spec.k`.
All claims are constructed, not machine-checked.

## Claim Paraphrases

C1. `FIRST-NONCWD-NOEDGE`: for any non-empty path list whose first item is not
`""`, `"."`, or `cwd`, and with no relevant implicit `PYTHONPATH` edge-colon
case, `modify_sys_path` returns the same list.

C2. `FIRST-CWD-NOEDGE`: for any non-empty path list whose first item is `""`,
`"."`, or `cwd`, and with no relevant implicit `PYTHONPATH` edge-colon case,
`modify_sys_path` removes that first item.

C3. `EMPTY-PATH`: an empty `sys.path` remains empty. This is a totality/safety
side condition of the helper model; it is not an externally observed Pylint
startup path.

C4. `FIRST-NONCWD-LEADING`: when `PYTHONPATH` contributes an implicit leading
current-directory entry and the first path is caller-owned, the first path is
preserved and only a CWD-like second entry is removed.

C5. `FIRST-CWD-LEADING`: when the first path is CWD-like and `PYTHONPATH`
contributes an implicit leading current-directory entry, the first CWD-like item
is removed first, then the next CWD-like item is removed.

C6. `FIRST-NONCWD-TRAILING`: when `PYTHONPATH` contributes an implicit trailing
current-directory entry and the first path is caller-owned, the first path is
preserved and only a CWD-like third entry is removed.

C7. `FIRST-CWD-TRAILING`: when the first path is CWD-like and `PYTHONPATH`
contributes an implicit trailing current-directory entry, the first CWD-like
item is removed first, then the CWD-like item now at index `1` is removed.

C8. `EXPLICIT-LEADING` and `EXPLICIT-TRAILING`: when the `PYTHONPATH` edge case
is explicit `.` or explicit `cwd`, the extra colon cleanup is skipped; only the
first-entry rule applies.

C9. `LATER-CWD-PRESERVED`: a CWD-like entry outside the modeled startup slots is
not removed merely because it equals `cwd`.

## Frame Conditions

F-API. `modify_sys_path()` remains a public zero-argument function returning
`None`; the proof models only mutation of the `sys.path` list.

F-ORDER. Remaining path entries keep their relative order. The only allowed
list operation is deletion of a targeted CWD-like slot.
