# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Claims

The constructed K claims are in `fvk/autodetector-spec.k` and are read against
the abstract semantics in `fvk/mini-django-autodetector.k`.

The core claims are:

- `(MODEL-RENAME-NORMALIZES-KEYS)` for O-001.
- `(FIELD-LISTS-USE-KEPT-NEW-KEY)` for O-002.
- `(V0-OLD-TO-STATE-LOOKUP-FAILS)` for O-003.
- `(V1-NEW-TO-STATE-LOOKUP-SUCCEEDS)` for O-004.
- `(NO-RENAME-FRAME)` for O-005.

## Constructed Proof

P-001. `generate_renamed_models()` iterates new model keys that are absent from
the old model key set. When it accepts `O -> N`, it records
`renamed_models[(A, N)] = O`. It then removes `(A, O)` from `old_model_keys` and
adds `(A, N)`. By direct symbolic execution of these map and set updates, the
post-state satisfies O-001.

P-002. `_prepare_field_lists()` ranges over `kept_model_keys =
old_model_keys & new_model_keys`. By P-001, the renamed model contributes kept
key `(A, N)`. The old-field comprehension stores each field tuple with model
component `N`, but the source of field names is
`from_state.models[(A, renamed_models.get((A, N), N))] =
from_state.models[(A, O)]`. The new-field comprehension stores tuples with the
same kept key `(A, N)` and reads `to_state.models[(A, N)]`. This proves O-002.

P-003. In the reported state shape, `to_state.models` contains `(A, N)` and not
`(A, O)`. V0 computed `old_model_name = O` and looked up
`to_state.models[(A, old_model_name)] = to_state.models[(A, O)]`. The key is
not present, so the abstract lookup is undefined. This reproduces the
traceback in `benchmark/PROBLEM.md` and proves O-003.

P-004. V1 keeps the same computation of `old_model_name` for the historical
state lookup, so `old_model_state = from_state.models[(A, O)]` remains defined
under the renamed-model precondition. It then looks up
`new_model_state = to_state.models[(A, model_name)] =
to_state.models[(A, N)]`. Since `(A, N)` is the target model key by O-001 and
O-002, this lookup is defined. The `get_field(new_field)` step therefore is not
blocked by the reported model-key `KeyError`. This proves O-004.

P-005. If no model rename entry exists for `(A, M)`, then
`renamed_models.get((A, M), M)` returns `M`. The pre-fix and V1 target-state
lookups both address `to_state.models[(A, M)]`. Therefore the patch is neutral
for non-renamed models, proving O-005.

P-006. The source diff changes only the target-state lookup expression inside
`generate_renamed_fields()`. It does not alter a method signature, operation
class, public callsite shape, or test file. This proves the compatibility part
of O-006. The abstract proof boundary is recorded in `FINDINGS.md` F-004.

## Residual Risk

This is a focused proof over the state-key invariant that caused the reported
crash. It is not a full proof of all Django migration autodetection behavior.
The trusted base is the adequacy of the abstract K model for this property, the
manual symbolic proof above, and any future K/SMT toolchain used to check the
claims. Termination is not separately proved.

## Test Recommendation

No test files were read for removal, no hidden tests are available, and the
proof is not machine-checked. Keep all tests. A future public regression test
should cover an accepted model rename and field rename in one autodetection
pass and assert that operations are produced without `KeyError`.

## Reproduce the Machine Check Later

These commands are recorded for a later environment with K installed. They were
not executed in this session.

```sh
kompile fvk/mini-django-autodetector.k --backend haskell
kast --backend haskell fvk/autodetector-spec.k
kprove fvk/autodetector-spec.k
```
