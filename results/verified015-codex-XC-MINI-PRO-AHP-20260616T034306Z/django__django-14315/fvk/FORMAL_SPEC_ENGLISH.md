# Formal Spec English

This file paraphrases the nontrivial K claims in `dbshell-env-spec.k`.

## PG-NO-OVERRIDES

For any PostgreSQL settings whose password, service, sslmode, sslrootcert, sslcert, sslkey, and passfile fields are all absent or falsey, the PostgreSQL client environment result is `NoEnv`. `NoEnv` corresponds to Python `None`.

## PG-WITH-OVERRIDES

For any PostgreSQL settings with at least one truthy PostgreSQL environment source, the PostgreSQL client environment result is `Env(M)`, where `M` is the mapping produced by adding exactly the selected PostgreSQL environment variables. The proof model includes the representative password case and the general normalization rule for non-empty maps.

## RUNSHELL-NONE

If a backend returns `NoEnv` to the base runner, the subprocess environment result is `Inherit`, meaning `subprocess.run(..., env=None)`.

## RUNSHELL-EMPTY

If a backend returns `Env(.Map)` to the base runner, the subprocess environment result is also `Inherit`. This is the V2 improvement over V1: an empty mapping is not allowed to reach `subprocess.run()` as an explicit empty environment.

## RUNSHELL-NONEMPTY

If a backend returns `Env(M)` with `M =/= .Map`, the subprocess environment result is `Explicit(overlay(OS, M))`, meaning the subprocess receives the current `os.environ` with backend variables overlaid.

## Frame Conditions

The claims are restricted to environment handling. PostgreSQL command argument construction is intentionally framed as unchanged; it remains governed by the existing code paths for `-U`, `-h`, `-p`, database name/default database, and parameter appending.
