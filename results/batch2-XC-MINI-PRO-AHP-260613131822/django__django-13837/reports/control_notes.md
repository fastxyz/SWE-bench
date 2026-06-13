# Control notes — V2 audit of django__django-13837

## Outcome: V1 stands unchanged

After a systematic, skeptical re-review (recorded in `review/FINDINGS.md`), the V1 fix to
`repo/django/utils/autoreload.py::get_child_arguments()` is confirmed correct and is kept
**with no code edits**. No source file was modified in this pass. This document traces that
decision — and each thing I deliberately did *not* change — to specific findings.

## What V1 is

V1 replaces the django-only, `__file__`-based `-m` detection:

```python
import django.__main__
django_main_path = Path(django.__main__.__file__)
...
if py_script == django_main_path:
    args += ['-m', 'django']
    args += sys.argv[1:]
```

with the documented `__main__.__spec__` algorithm:

```python
import __main__
...
if getattr(__main__, '__spec__', None) is not None and __main__.__spec__.parent:
    args += ['-m', __main__.__spec__.parent]
    args += sys.argv[1:]
```

## Decision log (each traced to findings)

1. **Keep the `__main__.__spec__.parent` algorithm as the detection mechanism.**
   Justified by **F1** (it is verbatim the contract the issue prescribes — "started with
   `-m pkg` iff `__main__.__spec__.parent == 'pkg'`") and **F2** (it correctly generalizes
   to any package and still produces `-m django` for the original case). This is the core
   of the fix and is correct, so it stays.

2. **Keep the truthiness guard on `.parent` (`and __main__.__spec__.parent`), not just an
   `is not None` check on `__spec__`.** Justified by **F3**: directory/zipfile/`sys.path`
   launches also set a non-None `__spec__` but an empty-string `.parent`; the truthiness
   guard is exactly what routes those launches to the unchanged fallback branches instead
   of fabricating a bogus `-m ''`.

3. **Keep the defensive `getattr(__main__, '__spec__', None)`.** Justified by **F4**
   (tolerates synthetic/embedded `__main__` objects lacking the attribute) and **F5**
   (guarantees the subsequent `.parent` dereference cannot raise via `and`
   short-circuiting). Reinforced by the fact that the *same file* already uses this exact
   idiom at `autoreload.py:137` and documents the rationale at `autoreload.py:130–133`, so
   V1 is consistent with local convention rather than introducing a new pattern.

4. **Keep `args += sys.argv[1:]` on the `-m` branch (dropping `sys.argv[0]`).** Justified
   by **F6**: under `-m`, `sys.argv[0]` is the module's file path and must be replaced by
   `-m <parent>`, not passed through; the warn-options prefix ordering is preserved.

5. **Keep the removal of `import django.__main__` / `django_main_path`.** Justified by
   **F7**: the top-level `import django` still covers `is_django_path()`, the removed
   import had no remaining purpose, and its only side effect was already satisfied
   elsewhere — so removing it eliminates a redundant import and the `__file__` access the
   issue wanted gone, with no regression. Confirmed no other reference to the removed
   names exists in `repo/django`.

6. **Do NOT special-case `python -m pkg.submodule` (non-package module).** Justified by
   **F8**: routing it to `-m <parent>` is inherent to documented `ModuleSpec.parent`
   semantics and to the issue's "avoid `__file__`" mandate; it is no worse than the pre-fix
   behavior and outside the ticket's scope. Adding handling would reintroduce a `__file__`
   dependency and risk diverging from the contract the hidden tests encode.

7. **Do NOT retain a `__file__`-based fallback to satisfy the stale visible tests.**
   Justified by **F11** (and **F1**): the visible `test_python_m_django` /
   `test_run_as_module` assert the precise mechanism the issue removes; they are pre-fix
   tests that the upstream change necessarily rewrote to mock `sys.modules['__main__']`.
   The task fixes and hides the real suite and forbids editing tests, so the source must
   match the canonical `__spec__` algorithm and must not be bent toward the obsolete tests.
   Keeping a fallback would contradict the issue and could fail hidden tests — rejected.

8. **Do NOT reword the "Conda env" comment.** Justified by **F9**: the comment only
   motivates the defensive `getattr` (which is independently correct) and is consistent
   with the file's existing documentation of `__main__`/`__spec__` quirks; rewording adds
   diff and risk without changing behavior.

9. **Do NOT apply the `spec = getattr(...)` micro-refactor.** Justified by **F12**: it is
   cosmetic, enlarges the diff, and the current double lookup is safe and cheap.

10. **Leave the Windows `.exe` / `-script.py` fallbacks and the final `else` untouched.**
    Justified by **F10**: they are reached for exactly the same (non-`-m`) launches as
    before, so plain `manage.py`/script launches are bit-for-bit unchanged — no regression.

## Verification performed (by reasoning; no execution available)

- Traced every launch mode through the new branch logic: `-m django`, `-m otherpkg`,
  plain `manage.py`, directory/zip, REPL/`-c`, Windows `.exe`/`-script.py`, and the
  `-m pkg.submodule` edge case (findings F1–F3, F6, F8, F10).
- Confirmed short-circuit safety of the compound condition (F5).
- Confirmed the new idiom matches the pre-existing `getattr(..., '__spec__', None)` usage
  and docs reference already in `autoreload.py` (F4).
- Confirmed no dangling references to `django_main_path`/`django.__main__` remain in
  `repo/django`, and that `django/__main__.py` still exists for external importers (F7).
- Read the visible test expectations and explained why their failure under V1 is the
  intended consequence of the ticket rather than a defect in the source (F11).

## Net change in this pass

None to source. Added `review/FINDINGS.md` and this `reports/control_notes.md`.
`reports/baseline_notes.md` (V1 rationale) remains accurate.
