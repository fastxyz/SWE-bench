# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were executed.

## Unit Under Audit

Primary function: `django.template.autoreload.get_template_directories()`.

Consumers covered by the observable behavior:

- `watch_for_template_changes()`, which watches every returned directory.
- `template_changed()`, which returns `True` when a changed non-Python file has
  a returned template directory among its parents.

## Public Intent Ledger

The detailed ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligations
are:

- E1/E2: `DIRS = [""]` is invalid but must not break autoreload.
- E3: the defect mechanism is `""` being normalized by `pathlib.Path` into
  the current directory.
- E4: `template_changed()` must not return `True` for unrelated non-template
  files merely because they are under `Path.cwd()`.
- E5/E6: both `backend.engine.dirs` and loader `get_dirs()` values feed
  `get_template_directories()`.
- E7: non-empty relative string and `Path` directory values must keep being
  normalized to `Path.cwd() / value`.

## Intended Contract

Let `B` be the sequence of configured directories from `backend.engine.dirs`,
`L` be the concatenated sequence of directories from loaders with `get_dirs()`,
and `cwd = Path.cwd()`.

`get_template_directories()` returns the set:

```text
{ cwd / to_path(d) | d in B and d != "" }
union
{ cwd / to_path(d) | d in L and d != "" and not is_django_path(d) }
```

The contract is partial over the same type domain as the pre-existing code:
non-empty invalid values still reach `to_path()` or `is_django_path()` and may
raise the same type errors as before. The only newly skipped value is the exact
empty string `""`.

## Observable Autoreload Contract

If all template directory contributions relevant to a non-template changed file
are `""`, then `Path.cwd()` is not introduced into the watched template
directory set by those contributions. Consequently, for an unrelated non-Python
file under `Path.cwd()` but outside every valid template directory,
`template_changed()` returns `None` rather than `True`.

## Scope Boundary

The public issue does not require filtering `"."`, `Path(".")`, or other
explicit current-directory paths. Those values remain intentional configuration
values and are outside the empty-string regression.

## Formal Artifacts

`fvk/mini-autoreload.k` models the directory collection slice as two finite
lists, one for backend dirs and one for loader dirs. `fvk/autoreload-spec.k`
states claims corresponding to the proof obligations below.

