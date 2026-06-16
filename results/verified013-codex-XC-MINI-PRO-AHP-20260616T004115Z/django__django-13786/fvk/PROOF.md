# FVK Proof

Status: constructed, not machine-checked.

## Claim

For every `CreateModel` operation `C` and following `AlterModelOptions`
operation `Aop` on the same model, the V1 implementation returns a singleton
replacement `CreateModel` whose `options` map equals the state that would result
from applying `C.state_forwards()` followed by `Aop.state_forwards()`.

Equivalently, for `M = C.options`, `A = Aop.options`, and
`K = Aop.ALTER_OPTION_KEYS`, the returned options map `R` satisfies:

```text
if key in A:
    R[key] = A[key]
elif key in K:
    key is absent from R
elif key in M:
    R[key] = M[key]
else:
    key is absent from R
```

## Proof Sketch

1. The branch precondition is `isinstance(operation, AlterModelOptions)` and
   matching `name_lower`. Under this precondition the code enters the audited
   branch and returns a list containing one `CreateModel`. This discharges
   PO-001.

2. The statement `options = {**self.options, **operation.options}` creates the
   map `merge(M, A)`. By Python dictionary merge semantics, every key in `A`
   maps to `A[key]`, and every key not in `A` but present in `M` maps to
   `M[key]`. This establishes the loop invariant before processing any
   alterable keys.

3. Consider the loop over `operation.ALTER_OPTION_KEYS`. Use the invariant:

   ```text
   After processing the first i keys from K:
     - processed keys absent from A are absent from options;
     - processed keys present in A map to A[key];
     - unprocessed keys and non-K keys still equal merge(M, A).
   ```

   Initialization holds for `i = 0` because no key has been processed and
   `options = merge(M, A)`.

4. Preservation:

   If the next key `k` is absent from `A`, the code executes
   `options.pop(k, None)`. The key is absent afterward, satisfying the processed
   key clause. `pop(..., None)` is safe whether `k` was present or absent.

   If `k` is present in `A`, the code skips the pop. The merge value `A[k]`
   remains in `options`, satisfying the processed key clause. This reasoning is
   independent of truthiness, so PO-006 follows.

   In both cases no other key is modified, so the invariant is preserved for
   already processed keys, unprocessed keys, and non-K keys.

5. The loop terminates because `ALTER_OPTION_KEYS` is a finite class-level list.
   At loop exit every key in `K` has been processed. The invariant therefore
   implies the pointwise postcondition in PO-002 through PO-005.

6. The constructor call uses `self.name`, `self.fields`, `self.bases`, and
   `self.managers` unchanged and uses the proven `options` map. This discharges
   PO-007.

7. The patch changed no method signature, branch predicate, or other branch
   body. This discharges PO-008.

## Adequacy Gate

The formal English claim matches the intent spec:

I-002 maps to PO-003 and F-002.

I-003 maps to PO-005 and F-004.

I-004 maps to PO-004 and F-003.

I-005 maps to PO-007.

I-006 maps to PO-008.

No claim preserves the legacy plain-merge behavior reported as buggy. No claim
uses an implementation-derived key set other than `ALTER_OPTION_KEYS`, which is
named by the public hint and the implementation comment.

## Proof-derived Findings

The proof produces no source-code findings beyond the original plain-merge bug
already fixed by V1. The key proof obstacle in the pre-fix implementation was
PO-003: a plain merge cannot remove `ordering`, `verbose_name`, or any other
omitted alterable key. V1 removes that obstacle.

Residual finding F-006 remains: the proof is constructed but not
machine-checked.

## Machine-check Commands

These commands are required by the FVK method but were not executed because the
task forbids K tooling:

```sh
kompile fvk/mini-migration-options.k --backend haskell
kast --backend haskell fvk/create-model-reduce-spec.k
kprove fvk/create-model-reduce-spec.k
```

Expected result after providing the mini map/list semantics described in
`SPEC.md`: `kprove` returns `#Top` for the option-equivalence and loop
invariant claims.

## Test Guidance

No test removal is recommended. The proof is not machine-checked, tests were not
read or run in this phase, and the user explicitly forbids modifying test files.
Useful public tests to add in a normal development environment would cover:

```text
CreateModel(options={"ordering": ["name"]})
AlterModelOptions(options={})
=> squashed CreateModel(options={})

CreateModel(options={"ordering": ["old"], "db_table": "app_model"})
AlterModelOptions(options={"ordering": ["new"]})
=> squashed CreateModel(options={"ordering": ["new"], "db_table": "app_model"})

CreateModel(options={"verbose_name": "Old"})
AlterModelOptions(options={"ordering": []})
=> squashed CreateModel(options={"ordering": []})
```
