# Proof Obligations

Status: constructed, not machine-checked.

## PO-PG-NO-OVERRIDES

Claim:

- For PostgreSQL settings where `PASSWORD`, `OPTIONS['service']`, `OPTIONS['sslmode']`, `OPTIONS['sslrootcert']`, `OPTIONS['sslcert']`, `OPTIONS['sslkey']`, and `OPTIONS['passfile']` are all absent or falsey, `settings_to_cmd_args_env()` returns `env is None`.

Evidence:

- E2, E4, E5, E8.

Formal claim:

- `PG-NO-OVERRIDES` in `fvk/dbshell-env-spec.k`.

V1 status:

- Satisfied by V1.

V2 status:

- Satisfied by `return args, env or None`.

## PO-PG-WITH-OVERRIDES

Claim:

- If PostgreSQL has at least one truthy env source, `settings_to_cmd_args_env()` returns the populated env dict and does not normalize it to `None`.

Evidence:

- E3, E4, E8.

Formal claim:

- `PG-WITH-OVERRIDES` in `fvk/dbshell-env-spec.k`.

V1 status:

- Satisfied.

V2 status:

- Satisfied; `env or None` leaves non-empty mappings unchanged.

## PO-RUNSHELL-NONE

Claim:

- If a backend returns `env is None`, `BaseDatabaseClient.runshell()` passes `env=None` to `subprocess.run()`.

Evidence:

- E1, E3, E4.

Formal claim:

- `RUNSHELL-NONE` in `fvk/dbshell-env-spec.k`.

V1 status:

- Satisfied.

V2 status:

- Satisfied.

## PO-RUNSHELL-EMPTY

Claim:

- If a backend returns `env == {}`, `BaseDatabaseClient.runshell()` passes `env=None` to `subprocess.run()`, not `{}`.

Evidence:

- E1, E3, E7.

Formal claim:

- `RUNSHELL-EMPTY` in `fvk/dbshell-env-spec.k`.

V1 status:

- Failed. V1 still passed `{}` through from any backend that returned an empty mapping.

V2 status:

- Satisfied by the new `else: env = None` branch.

## PO-RUNSHELL-NONEMPTY

Claim:

- If a backend returns a non-empty env mapping, `BaseDatabaseClient.runshell()` passes `{**os.environ, **env}` to `subprocess.run()`.

Evidence:

- E4, E7.

Formal claim:

- `RUNSHELL-NONEMPTY` in `fvk/dbshell-env-spec.k`.

V1 status:

- Satisfied.

V2 status:

- Satisfied; the truthy branch is unchanged.

## PO-ARGS-FRAME

Claim:

- PostgreSQL command argument construction is unchanged by the fix.

Evidence:

- E4 and absence of public issue evidence about argument construction.

Formal handling:

- Frame condition in `fvk/SPEC.md` and `fvk/FORMAL_SPEC_ENGLISH.md`; not modeled in detail because the edited lines do not affect args.

V1 status:

- Satisfied.

V2 status:

- Satisfied.
