# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Canonical standard settings mapping

For every valid settings dictionary where `NAME` is truthy, the normal return
path maps the database name to `database`. For every valid settings dictionary
where `PASSWORD` is truthy, the normal return path maps the password to
`password`.

Intent evidence: E1, E2, E3.

Discharged by V1 static source:

- `kwargs['database'] = settings_dict['NAME']`
- `kwargs['password'] = settings_dict['PASSWORD']`

## PO2: No deprecated Django-generated standard kwargs

For the standard settings-derived part of the returned params, the backend never
updates the dictionary with keys `db` or `passwd`.

Intent evidence: E1, E2.

Discharged by V1 static source and the constructed K claim
`STANDARD-CANONICAL-NAMES`.

## PO3: Canonical `OPTIONS` precedence

If `OPTIONS` contains `database` or `password`, those canonical driver options
override the values derived from `NAME` or `PASSWORD`, because `kwargs.update`
runs after the standard settings mapping.

Intent evidence: E4.

Discharged by the source order:

1. Populate standard kwargs.
2. Copy `OPTIONS`.
3. Pop `isolation_level`.
4. `kwargs.update(options)`.

## PO4: Pass-through frame condition for arbitrary `OPTIONS`

Except for `isolation_level`, user-supplied `OPTIONS` entries remain
pass-through mysqlclient options. This includes legacy `db` and `passwd` if a
user explicitly supplies them.

Intent evidence: E4, E5.

Discharged by preserving V1 behavior. Rewriting these keys would be a broader
behavior change than the public issue requires.

## PO5: Supported mysqlclient versions accept the replacement kwargs

The issue states mysqlclient has supported `database` and `password` since
1.3.8, while this Django checkout requires mysqlclient 1.4.0 or newer.

Intent evidence: E3 plus the version check in
`repo/django/db/backends/mysql/base.py`.

Discharged by the existing import-time version guard.

## PO6: Non-regression frame for unrelated connection params

The V1 fix must not change the existing behavior for:

- `conv`
- `charset`
- `user`
- socket-vs-host selection
- `port`
- `client_flag`
- isolation level validation
- non-isolation `OPTIONS` merge

Intent evidence: E6.

Discharged by the source diff: only the two key names for `NAME` and `PASSWORD`
changed.

## PO7: Honesty gate

Because this environment forbids execution, the proof must remain labeled
"constructed, not machine-checked"; test deletion is not justified.

Intent evidence: FVK instructions and task constraints.

Discharged by `fvk/PROOF.md` and `reports/fvk_notes.md`.
