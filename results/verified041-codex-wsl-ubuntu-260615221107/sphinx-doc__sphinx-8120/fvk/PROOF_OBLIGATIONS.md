# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Project locale directories are first in the initialization order

Statement:
`_init_i18n()` must pass `list(repo.locale_dirs)` before built-in fallback
locations to `locale.init()`.

Evidence:
SPEC SO-1, SO-2; ledger E-1 through E-5.

V1 discharge:
`repo/sphinx/application.py` constructs:

```python
locale_dirs = list(repo.locale_dirs) + [
    None, path.join(package_dir, 'locale')
]
```

Status: DISCHARGED.

## PO-2: First loaded catalog wins for messages it contains

Statement:
Given `locale.init([D1, D2, ...], language)`, if `D1` contains message `M`,
then `translator.gettext(M)` returns `D1`'s value, not a fallback value.

Evidence:
SPEC SO-1; ledger E-6; `locale.init()` assigns the first successful catalog to
`translator` and adds later catalogs with `translator.add_fallback(trans)`.

K claims:
`PROJECT-OVERRIDES`, `PROJECT-ORDER`.

Status: DISCHARGED in the constructed model; not machine-checked.

## PO-3: Project partial catalogs fall through to built-ins for missing messages

Statement:
If no yielded project locale directory contains `M`, lookup must fall through
to the built-in chain.

Evidence:
SPEC SO-3; ledger E-1 and E-8; issue workaround says users needed Danish
translations for the rest of the internal messages.

K claims:
`BUILTIN-FALLBACK`, `PACKAGE-FALLBACK`.

Status: DISCHARGED in the constructed model; not machine-checked.

## PO-4: No-project behavior preserves old built-in order

Statement:
If `repo.locale_dirs` is empty, V1's order must equal V0's built-in order:
`[None, path.join(package_dir, 'locale')]`.

Evidence:
SPEC SO-4; ledger E-8.

K claim:
`NO-PROJECT-PRESERVES-OLD-BUILTINS`.

Status: DISCHARGED by list identity:
`.List ++ [system, package] = [system, package]` in the model.

## PO-5: Auto-build still happens before lookup

Statement:
The existing compilation of outdated project `sphinx.po` into `sphinx.mo` must
remain before `locale.init()` so the generated catalog can participate in the
new precedence order.

Evidence:
SPEC SO-5; problem statement notes `gettext_auto_build = True` creates
`sphinx.mo`.

V1 discharge:
The `for catalog in repo.catalogs` compilation loop remains immediately before
the `locale_dirs` assignment and `locale.init()` call.

Status: DISCHARGED by source inspection.

## PO-6: Public compatibility is preserved

Statement:
The fix must not change public signatures or extension catalog semantics.

Evidence:
SPEC SO-6; PUBLIC_COMPATIBILITY_AUDIT.

V1 discharge:
Only a local list construction expression changed. `locale.init()`,
`init_console()`, and `add_message_catalog()` are unchanged.

Status: DISCHARGED.
