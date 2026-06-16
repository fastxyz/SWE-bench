# FVK Spec: django__django-14376

Status: constructed, not machine-checked.

## Target

Function under audit:

- `repo/django/db/backends/mysql/base.py`
- `DatabaseWrapper.get_connection_params()`

The observable is the dictionary of keyword arguments later passed to
`Database.connect(**conn_params)`.

## Intent-Only Contract

Public issue intent requires Django's MySQL backend to stop generating the
deprecated mysqlclient keyword arguments `db` and `passwd` for normal database
settings. mysqlclient supports the non-deprecated names `database` and
`password` in every mysqlclient version supported by this Django checkout.

For settings dictionaries in Django's normal shape:

- If `NAME` is truthy, the returned params contain `database: NAME`.
- If `PASSWORD` is truthy, the returned params contain `password: PASSWORD`.
- Django's standard settings mapping does not add `db` or `passwd`.
- Canonical entries supplied in `OPTIONS`, such as `database` or `password`,
  still take precedence because `OPTIONS` is merged last.
- Arbitrary `OPTIONS` entries remain pass-through driver options, except for
  `isolation_level`, which is consumed by Django before the merge.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "MySQL backend uses deprecated 'db' and 'passwd' kwargs." | The backend must not generate those deprecated kwargs for its own standard connection settings. | Encoded by PO1 and PO2. |
| E2 | `benchmark/PROBLEM.md` | "in favor of 'database' and 'password' respectively" | Replacement kwargs are exactly `database` for `NAME` and `password` for `PASSWORD`. | Encoded by PO1. |
| E3 | `benchmark/PROBLEM.md` | mysqlclient supports the replacements before Django's minimum supported version. | No compatibility guard is required for supported mysqlclient versions. | Encoded by PO5. |
| E4 | `repo/docs/ref/databases.txt` | "Connection settings are used in this order: OPTIONS, NAME, USER, PASSWORD, HOST, PORT, MySQL option files." | `OPTIONS` entries override standard Django settings when they use the same driver keyword. | Encoded by PO3. |
| E5 | `repo/docs/ref/databases.txt` | "Several other MySQLdb connection options may be useful" | `OPTIONS` is a pass-through channel for driver options. | Encoded by PO4. |
| E6 | `repo/django/db/backends/mysql/base.py` | Existing control flow handles `USER`, `HOST`, `PORT`, `client_flag`, and `isolation_level`. | Unrelated connection behavior is a frame condition. | Encoded by PO6. |

## Domain and Preconditions

The contract ranges over Django-normalized MySQL database settings dictionaries
with keys `NAME`, `USER`, `PASSWORD`, `HOST`, `PORT`, and `OPTIONS`.

Preconditions:

- `OPTIONS` is a mapping.
- `HOST` supports `startswith('/')`.
- If `PORT` is truthy, `int(PORT)` is valid.
- `isolation_level`, when present and truthy, is one of the backend's supported
  isolation levels. Invalid isolation levels raise `ImproperlyConfigured` as an
  unchanged pre-existing validation path.

These are existing Django configuration expectations, not new requirements.

## Postconditions

Let `P = get_connection_params(settings_dict)` return normally.

1. `P['conv'] == django_conversions` and `P['charset'] == 'utf8'`.
2. If `settings_dict['USER']` is truthy and `OPTIONS` does not override `user`,
   then `P['user'] == settings_dict['USER']`.
3. If `settings_dict['NAME']` is truthy and `OPTIONS` does not override
   `database`, then `P['database'] == settings_dict['NAME']`.
4. If `settings_dict['PASSWORD']` is truthy and `OPTIONS` does not override
   `password`, then `P['password'] == settings_dict['PASSWORD']`.
5. Django's own settings-derived updates never introduce `db` or `passwd`.
6. If `HOST` starts with `/`, `unix_socket` is set from `HOST`; otherwise a
   truthy `HOST` sets `host`.
7. A truthy `PORT` sets `port` to `int(PORT)`.
8. `client_flag` is set to `CLIENT.FOUND_ROWS`.
9. `OPTIONS` is copied, `isolation_level` is removed and validated, and the
   remaining entries are merged last.

## Formal Model

The constructed K artifacts model the dictionary-building fragment as a small
map-update language:

- `fvk/mini-python-dict.k`
- `fvk/mysql-connection-params-spec.k`

There are no loops or recursive calls in the target, so no circularity claim is
needed. The proof obligations are straight-line symbolic execution plus map
frame/override reasoning.

## Adequacy Result

The formal English obligations in `fvk/FORMAL_SPEC_ENGLISH.md` match the
intent-only obligations in `fvk/INTENT_SPEC.md`.

The only intentionally unproven stronger property is:

- "The final params never contain `db` or `passwd` under any settings." This is
  not public intent, because user-supplied `OPTIONS` are documented as
  pass-through driver options. The proven property is narrower and intent-based:
  Django does not generate deprecated `db` or `passwd` from its standard
  `NAME`/`PASSWORD` settings, and canonical `OPTIONS` can override with
  `database`/`password`.
