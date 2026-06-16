# FVK Proof

Status: constructed, not machine-checked. The commands below were not executed.

## Claims

The constructed K claims are in:

- `fvk/mini-python-dict.k`
- `fvk/mysql-connection-params-spec.k`

The main claims are:

- `STANDARD-CANONICAL-NAMES`: standard `NAME` and `PASSWORD` settings produce
  `database` and `password`, not `db` and `passwd`.
- `CANONICAL-OPTIONS-PRECEDENCE`: canonical `OPTIONS['database']` and
  `OPTIONS['password']` override standard settings.
- `LEGACY-OPTIONS-PASSTHROUGH`: user-provided legacy `OPTIONS['db']` and
  `OPTIONS['passwd']` remain user-supplied pass-through entries and are outside
  the Django-generated no-deprecated-kwargs obligation.

## Constructed Symbolic Execution

There are no loops or recursive calls in `get_connection_params()`, so no
circularity proof is required.

For a normal-return path with valid settings:

1. Initialize `kwargs` to `{conv: django_conversions, charset: 'utf8'}`.
2. If `USER` is truthy, update `user`.
3. If `NAME` is truthy, V1 updates `database` with `NAME`.
4. If `PASSWORD` is truthy, V1 updates `password` with `PASSWORD`.
5. If `HOST` starts with `/`, update `unix_socket`; else if `HOST` is truthy,
   update `host`.
6. If `PORT` is truthy, update `port` with `int(PORT)`.
7. Update `client_flag` with `CLIENT.FOUND_ROWS`.
8. Copy `OPTIONS`, remove `isolation_level`, validate it, and update `kwargs`
   with the remaining options.
9. Return `kwargs`.

The only settings-derived updates for database name and password in steps 3-4
use canonical keys. Therefore, if `OPTIONS` does not itself contain legacy keys,
the final dictionary does not contain `db` or `passwd`.

If `OPTIONS` contains canonical `database` or `password`, step 8 overwrites the
settings-derived canonical values. This proves the documented precedence for
canonical driver options.

If `OPTIONS` contains legacy `db` or `passwd`, step 8 preserves those
user-supplied pass-through entries. This does not contradict the issue-derived
claim because the no-deprecated-kwargs obligation is scoped to Django-generated
kwargs from standard settings.

## Verification Conditions

No arithmetic loop invariant or termination variant is required.

The proof uses map-update facts:

- Updating key `database` cannot introduce key `db`.
- Updating key `password` cannot introduce key `passwd`.
- A later update with the same canonical key overwrites the earlier value.
- A merge of arbitrary options preserves arbitrary option keys unless they are
  removed before the merge; the source removes only `isolation_level`.

## Machine-Check Commands

These are recorded for later machine checking only:

```sh
cd fvk
kompile mini-python-dict.k --backend haskell
kast --backend haskell mysql-connection-params-spec.k
kprove mysql-connection-params-spec.k
```

Expected outcome if the constructed artifacts are accepted by the K toolchain:
`#Top` for the claims above.

## Test Recommendation

No tests were run or modified.

After machine checking, unit tests that only assert `NAME` maps to `database`
and `PASSWORD` maps to `password` would be subsumed by PO1 and PO2. Integration
tests involving real mysqlclient connections, invalid isolation levels, socket
paths, port conversion, and arbitrary `OPTIONS` pass-through should be kept
because this proof is scoped to dictionary construction and does not execute
the driver.
