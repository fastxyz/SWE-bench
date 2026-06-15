# PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims

The abstract claim `DBSHELL-SSL-ENV` in `fvk/postgresql-dbshell-spec.k` states
that executing `runShellDb(CP, ENV0)` reaches a final state with:

- `args = expectedArgs(CP)`
- `env = expectedEnv(CP, ENV0)`
- `sigintRestored = true`

The helper equations are listed concretely in `fvk/PROOF_OBLIGATIONS.md`.

## Constructed proof sketch

1. Start in the initial state for `runshell_db(conn_params)` with symbolic
   `CP` and initial process environment `ENV0`.
2. Argument construction executes before the V1 SSL block. By PO-002, the
   resulting list is the legacy `expectedArgs(CP)` and is independent of SSL
   parameters.
3. Environment construction starts from `os.environ.copy()`, modeled as `ENV0`.
   By PO-003, a truthy `password` updates `PGPASSWORD` to `str(password)`.
4. The fixed `ssl_env` map is finite and contains exactly the issue-named
   pairs. Symbolic unrolling of the four loop iterations gives:
   - truthy `CP['sslmode']` updates `PGSSLMODE`
   - truthy `CP['sslrootcert']` updates `PGSSLROOTCERT`
   - truthy `CP['sslcert']` updates `PGSSLCERT`
   - truthy `CP['sslkey']` updates `PGSSLKEY`
   Missing or falsey values do not add new updates, matching the existing
   truthy style used for `password`.
5. Map frame reasoning gives PO-005: all unrelated environment bindings remain
   from `ENV0`.
6. The subprocess call consumes the constructed `args` and `env` with
   `check=True`. The V1 patch does not alter this call.
7. The `finally` block restores the saved SIGINT handler on all paths through
   the call, establishing PO-006.
8. Therefore the final modeled state satisfies `DBSHELL-SSL-ENV` and the
   English contract in `fvk/FORMAL_SPEC_ENGLISH.md`.

## Adequacy and compatibility

The adequacy gate passes in `fvk/SPEC_AUDIT.md`: the formal claim covers the
mutual TLS options required by the issue and does not over-preserve a buggy
legacy behavior. Public compatibility passes in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: no signature, callsite, or visible command
argument shape changes.

## Exact commands to machine-check later

These commands are required by the FVK method but were not executed here:

```sh
kompile fvk/mini-dbshell.k --backend haskell
kast --backend haskell fvk/postgresql-dbshell-spec.k
kprove fvk/postgresql-dbshell-spec.k
```

Expected outcome if the abstract semantics is accepted by the toolchain:
`kprove` reduces the claims to `#Top`.

## Test recommendation

Do not remove tests based on this constructed proof. Add or keep tests that
mock `subprocess.run()` and assert that the environment includes
`PGSSLMODE`, `PGSSLROOTCERT`, `PGSSLCERT`, and `PGSSLKEY` when the matching
`conn_params` keys are present. Existing non-SSL dbshell tests remain valuable
until the proof is machine-checked and the real test suite passes.
