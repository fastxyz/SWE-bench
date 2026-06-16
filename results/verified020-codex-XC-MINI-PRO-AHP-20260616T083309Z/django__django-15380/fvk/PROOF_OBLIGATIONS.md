# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## O-001: Model rename normalization invariant

Given:

- old model key `(A, O)` exists in `from_state.models`;
- new model key `(A, N)` exists in `to_state.models`;
- the model rename `O -> N` is accepted by `generate_renamed_models()`.

Prove:

- `renamed_models[(A, N)] = O`;
- `old_model_keys` replaces `(A, O)` with `(A, N)`;
- `(A, N)` is the kept key used by later model and field comparison.

This obligation is backed by `SPEC.md` E-003 and E-004.

## O-002: Field-key preparation invariant

Given O-001 and kept model key `(A, N)`.

Prove:

- old field keys are stored as `(A, N, old_field)` while their field names are
  read from `from_state.models[(A, O)]`;
- new field keys are stored as `(A, N, new_field)` while their field names are
  read from `to_state.models[(A, N)]`.

This obligation is backed by `SPEC.md` E-005 and E-006.

## O-003: V0 counterexample

Given:

- O-001 and O-002;
- `to_state.models` contains `(A, N)`;
- `to_state.models` does not contain `(A, O)`;
- `(A, N, new_field)` is in `new_field_keys - old_field_keys`.

Prove:

- the V0 lookup `to_state.models[(A, old_model_name)]` equals
  `to_state.models[(A, O)]`;
- that lookup is undefined and can raise `KeyError`.

This obligation is the symbolic reproduction of the public traceback.

## O-004: V1 target-state lookup definedness

Given:

- O-001 and O-002;
- `to_state.models` contains `(A, N)`;
- `(A, N, new_field)` is in `new_field_keys - old_field_keys`.

Prove:

- the V1 lookup `to_state.models[(A, model_name)]` equals
  `to_state.models[(A, N)]`;
- that lookup is defined before `get_field(new_field)` is called.

This is the core obligation for confirming V1.

## O-005: Non-renamed frame condition

Given:

- no entry exists in `renamed_models` for `(A, M)`;
- both old and new field processing use kept key `(A, M)`.

Prove:

- `old_model_name = model_name = M`;
- changing the target lookup from `old_model_name` to `model_name` is
  observationally neutral for the lookup key.

This obligation prevents the fix from regressing ordinary field rename
detection on non-renamed models.

## O-006: Compatibility and abstraction honesty

Prove or record:

- the source change does not alter method signatures, operation classes, or
  caller protocols;
- the constructed proof covers the reported state-key crash and not the entire
  Django migration autodetector;
- test removal is not recommended unless the K artifacts are machine-checked
  later and mapped to public tests.

This obligation is backed by `SPEC.md` Public Compatibility Audit and
`FINDINGS.md` F-004.
