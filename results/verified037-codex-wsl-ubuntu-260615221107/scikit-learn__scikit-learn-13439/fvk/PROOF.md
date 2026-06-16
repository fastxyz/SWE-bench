# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
tests, Python, or project code were run.

## Machine-check commands to run later

From the repository workspace root:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell pipeline-len-spec.k
kprove pipeline-len-spec.k
```

Expected machine-check result after the toolchain is run: `#Top` for all claims.

## Claims proved by construction

### LEN

Claim: for every `N >= 0`,
`pipelineLen(pipeline(N)) => N`.

Symbolic execution:

1. Start with `<k> pipelineLen(pipeline(N)) </k>` and side condition `N >= 0`.
2. Apply the `pipelineLen` semantic rule in `mini-python.k`.
3. The `<k>` cell rewrites to `N`.

No loop, recursion, or arithmetic verification condition remains.

Source correspondence: V1's `Pipeline.__len__` is exactly
`return len(self.steps)`. Under the public `steps : list` contract and Python
sequence convention, `len(self.steps)` is the cardinality represented by `N`.

### FULL-SLICE-AFTER-LEN

Claim: for every `N >= 0`,
`slicePrefix(pipeline(N), pipelineLen(pipeline(N))) => pipeline(N)`.

Symbolic execution:

1. Start with `<k> slicePrefix(pipeline(N), pipelineLen(pipeline(N))) </k>` and
   side condition `N >= 0`.
2. Strict evaluation of the second argument evaluates
   `pipelineLen(pipeline(N))`.
3. By the `LEN` rule, the second argument rewrites to `N`.
4. The expression is now `slicePrefix(pipeline(N), N)`.
5. Apply the `slicePrefix` semantic rule. Its side condition
   `0 <= N <= N` follows from `N >= 0`.
6. The `<k>` cell rewrites to `pipeline(N)`.

Source correspondence: existing `Pipeline.__getitem__` returns
`self.__class__(self.steps[ind])` for supported slices. A prefix slice whose
stop is the step sequence length preserves all steps.

## Adequacy gate

The English intent in `fvk/INTENT_SPEC.md` requires a length method returning
step cardinality, full-prefix slicing through that length, no unrelated sequence
methods, and no indexing regression. `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases
the two K claims in those terms. `fvk/SPEC_AUDIT.md` marks each item PASS, and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled public compatibility
issue.

Therefore the proof is about the intended public behavior, not merely an
as-built restatement of V1.

## Residual risk

The proof is constructed but not machine-checked. The trusted base is the
adequacy of the minimal K fragment, Python's standard sequence length and
prefix-slice conventions, and the future K toolchain run. The model abstracts
away estimator contents and step names because the issue's observable is only
the cardinality of the step sequence and the full-prefix slice that depends on
that cardinality.

## Test-redundancy recommendation

No test files were modified. If the K claims are machine-checked, a unit test
whose only assertions are `len(pipe) == len(pipe.steps)` for an in-domain
pipeline or `pipe[:len(pipe)].steps == pipe.steps` would be subsumed by PO-1 and
PO-2. Existing indexing and integration tests should be kept because this proof
does not machine-check the whole scikit-learn estimator stack.
