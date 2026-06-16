# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited unit is Sphinx application startup for internal translated
messages:

- `Sphinx._init_i18n()` in `repo/sphinx/application.py`
- `sphinx.locale.init()` in `repo/sphinx/locale/__init__.py`, as the existing
  merge/fallback helper used by `_init_i18n()`

The observable is `translator.gettext(message)` for the `sphinx` text domain
after `_init_i18n()` runs with `config.language` set.

## Public Intent Ledger

This is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E-1, E-5: `locale_dirs` is a supported source of internal `sphinx` message
  catalogs at `locale/<language>/LC_MESSAGES/sphinx.mo`.
- E-2, E-3, E-4: a project catalog entry intentionally supplied through
  `locale_dirs` must override a built-in/system entry for the same message.
- E-6: `locale.init()` gives precedence to the first loaded catalog and uses
  later catalogs as fallbacks.
- E-7: adjacent HTML JS translation lookup already checks user locale
  directories before built-in resources.
- E-8: the existing system-vs-bundled fallback order is system (`None`) before
  bundled `package_dir/locale`; the issue does not require changing that order.
- E-9: extension catalog APIs are not part of the bug and must remain unchanged.

## Spec Obligations

SO-1: Project override winner rule.
For any configured language `L`, message `M`, and project locale directory `P`
yielded by `CatalogRepository.locale_dirs`, if `P/L/LC_MESSAGES/sphinx.mo`
contains `M -> Vp`, then the initialized `sphinx` translator returns `Vp` for
`M` even if system or bundled catalogs also contain `M`.

SO-2: Project directory order.
If multiple configured project locale directories are yielded, their configured
order is preserved. The first project directory containing `M` wins among
project catalogs.

SO-3: Partial project catalog fallback.
If no yielded project locale directory contains `M`, lookup falls through to
the pre-existing built-in chain: system gettext location (`None`) first, then
Sphinx's bundled `package_dir/locale`.

SO-4: No-project frame condition.
If `CatalogRepository.locale_dirs` yields no directories, `_init_i18n()` passes
the same built-in order as V0: `[None, path.join(package_dir, 'locale')]`.

SO-5: Auto-build preservation.
The existing loop that compiles an outdated project `sphinx.po` to `sphinx.mo`
before initialization remains before `locale.init()`.

SO-6: Compatibility frame condition.
No public method signatures, direct `locale.init()` semantics, or
`add_message_catalog()` behavior change.

## Candidate Implementation Facts

V1 changed `_init_i18n()` from:

```python
locale_dirs = [None, path.join(package_dir, 'locale')] + list(repo.locale_dirs)
```

to:

```python
locale_dirs = list(repo.locale_dirs) + [
    None, path.join(package_dir, 'locale')
]
```

`locale.init()` still iterates `locale_dirs` in order. The first successful
catalog becomes `translator`; later successful catalogs are appended with
`translator.add_fallback(trans)`.

## Formal Model

The formal core is intentionally narrow and property-complete for this issue:

- `fvk/mini-locale-precedence.k` models the directory list built by
  `_init_i18n()` and first-hit fallback over catalogs.
- `fvk/locale-precedence-spec.k` states reachability claims for SO-1 through
  SO-4.

The model abstracts away gettext file parsing, PO-to-MO compilation, and the
full Python object graph because those are not the manipulated property. It
keeps the ordering axis visible, so a failing order
`[system, package, project]` and a passing order
`[project, system, package]` have distinct observables.
