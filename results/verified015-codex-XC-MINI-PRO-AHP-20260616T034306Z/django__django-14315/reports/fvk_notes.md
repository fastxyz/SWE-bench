# FVK Notes

## Decision summary

The FVK audit found that V1 fixed the PostgreSQL producer side but not the shared consumer side. V2 keeps the V1 PostgreSQL change and adds a base runner normalization so falsey env values cannot reach `subprocess.run()` as an explicit empty environment.

## Source changes

### `repo/django/db/backends/postgresql/client.py`

Decision: keep the V1 change `return args, env or None`.

Reasoning:

- `fvk/FINDINGS.md` F2 identifies `{}` as SUSPECT legacy behavior in visible PostgreSQL tests because the public issue says `{}` is the bug.
- `fvk/PROOF_OBLIGATIONS.md` PO-PG-NO-OVERRIDES requires PostgreSQL no-overrides output to be `None`.
- `fvk/PROOF_OBLIGATIONS.md` PO-PG-WITH-OVERRIDES requires non-empty PostgreSQL env mappings to remain mappings.
- `env or None` satisfies both: empty maps become `None`; non-empty maps are unchanged.

### `repo/django/db/backends/base/client.py`

Decision: add an `else` branch setting `env = None` when `env` is falsey.

Reasoning:

- `fvk/FINDINGS.md` F1 shows the V1 counterexample: a backend returning `(args, {})` still caused `runshell()` to pass `{}` through to `subprocess.run()`.
- `fvk/PROOF_OBLIGATIONS.md` PO-RUNSHELL-EMPTY requires empty mappings to normalize to `None`.
- `fvk/PROOF_OBLIGATIONS.md` PO-RUNSHELL-NONE requires `None` to remain the subprocess inheritance path.
- `fvk/PROOF_OBLIGATIONS.md` PO-RUNSHELL-NONEMPTY requires non-empty mappings to keep the existing `{**os.environ, **env}` overlay behavior.
- The new `else` branch satisfies PO-RUNSHELL-EMPTY without changing the truthy merge branch.

## Decisions not to change

### PostgreSQL argument construction

Decision: leave PostgreSQL command argument construction unchanged.

Reasoning:

- `fvk/PROOF_OBLIGATIONS.md` PO-ARGS-FRAME treats argument behavior as a frame condition.
- `fvk/FINDINGS.md` does not identify an argument-construction defect.
- The issue and proof obligations are about the env component and subprocess environment inheritance.

### Non-empty env mapping behavior

Decision: preserve populated env mappings.

Reasoning:

- `fvk/FINDINGS.md` F3 records this as a regression guard.
- `fvk/PROOF_OBLIGATIONS.md` PO-PG-WITH-OVERRIDES and PO-RUNSHELL-NONEMPTY require populated PostgreSQL env mappings to continue flowing into the subprocess environment.

### Tests

Decision: do not modify tests.

Reasoning:

- The benchmark forbids test-file edits.
- `fvk/FINDINGS.md` F2 records visible `{}` expectations as SUSPECT legacy evidence, but this task requires production-code changes only.

## Verification status

The FVK proof is constructed, not machine-checked. The commands recorded in `fvk/SPEC.md` and `fvk/PROOF.md` should be run only in an environment with K tooling available; they were not executed in this session.
