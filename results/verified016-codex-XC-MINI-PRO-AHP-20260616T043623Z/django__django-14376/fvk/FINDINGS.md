# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Findings

### F1: Pre-fix settings mapping generated deprecated kwargs

Input:

- `NAME = 'appdb'`
- `PASSWORD = 'secret'`
- `OPTIONS = {}`

Observed before V1:

- The MySQL backend generated `db: 'appdb'` and `passwd: 'secret'`.

Expected from public intent:

- Generate `database: 'appdb'` and `password: 'secret'`.
- Do not generate `db` or `passwd`.

Classification: code bug fixed by V1.

Related proof obligations: PO1, PO2.

### F2: V1 satisfies the standard-settings deprecation obligation

Input:

- `NAME = 'appdb'`
- `PASSWORD = 'secret'`
- `OPTIONS = {}`

Observed in V1 by static inspection:

- `NAME` maps to `kwargs['database']`.
- `PASSWORD` maps to `kwargs['password']`.
- The standard mapping no longer writes `kwargs['db']` or `kwargs['passwd']`.

Expected from public intent:

- Exactly this canonical mysqlclient keyword mapping.

Classification: confirmed fix; no further source edit required.

Related proof obligations: PO1, PO2, PO5.

### F3: Legacy user-supplied `OPTIONS['db']` and `OPTIONS['passwd']` remain pass-through

Input:

- `NAME = 'appdb'`
- `PASSWORD = 'secret'`
- `OPTIONS = {'db': 'legacydb', 'passwd': 'legacypw'}`

Observed in V1 by static inspection:

- The backend first adds canonical `database` and `password` from standard
  settings, then merges `OPTIONS` unchanged after removing only
  `isolation_level`.
- User-provided `db` and `passwd` would remain in the final dict.

Expected from public intent:

- The issue identifies Django's own use of deprecated kwargs in
  `mysql/base.py`, not a requirement to rewrite arbitrary user-supplied driver
  options.
- Django docs describe `OPTIONS` as taking precedence and as a channel for
  MySQLdb connection options.

Classification: intentional residual behavior, not a code bug under this
issue's public intent.

Related proof obligations: PO3, PO4.

### F4: Verification is constructed only

Input:

- The FVK `.k` artifacts and proof obligations in this directory.

Observed:

- Commands are recorded in `fvk/PROOF.md`.
- The task forbids running `kompile`, `kprove`, Python, or tests.

Expected:

- Label proof as constructed, not machine-checked.
- Do not delete or modify tests.

Classification: verification limitation, not a source-code issue.

Related proof obligations: PO7.
