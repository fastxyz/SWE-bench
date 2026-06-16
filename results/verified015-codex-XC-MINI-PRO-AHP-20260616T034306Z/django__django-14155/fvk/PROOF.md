# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or Django tests were run.

## Claims proved by construction

- `PARTIAL-REPR`: a single partial callback displays the wrapped callable path and merged display args/kwargs.
- `NESTED-PARTIAL-REPR`: nested partials display the innermost callable path and flatten args/kwargs in partial-application order.
- `NONPARTIAL-REPR`: non-partial repr metadata is unchanged.
- `FRAME-PUBLIC-TRIPLE`: public `func`, `args`, and `kwargs` fields are unchanged for dispatch and tuple unpacking.
- `VIEW-NAME-FRAME`: `url_name` precedence is preserved; unnamed partials use the unwrapped path.

## Proof sketch

The mini semantics models `ResolverMatch.__init__()` as a transition from `build(V, A, K, U, Apps, Namespaces, R)` to an `rm(...)` state. The first three fields of `rm` are the public runtime triple. The next fields are display-only metadata: display path, selected view name, display args, and display kwargs.

For a non-partial `view(FPATH)`, the equations for `path`, `selectedViewName`, `partialArgs`, and `partialKwargs` reduce to `FPATH`, `url_name` or `FPATH`, `.List`, and `.Map`, so the `build` rule rewrites to display args `A` and display kwargs `K`. This discharges `NONPARTIAL-REPR`.

For `partial(view(FPATH), PA, PK)`, `path` recursively unwraps to `FPATH`, `partialArgs` yields `PA`, and `partialKwargs` yields `PK`. The `build` rule therefore reaches display args `concatArgs(PA, A)` and display kwargs `mergeKwargs(PK, K)` while preserving public fields `partial(view(FPATH), PA, PK)`, `A`, and `K`. This discharges `PARTIAL-REPR` and the public triple part of `FRAME-PUBLIC-TRIPLE`.

For nested partials, the recursive equations apply one layer at a time. `path(partial(partial(view(FPATH), PA1, PK1), PA2, PK2))` reduces to `FPATH`; `partialArgs` reduces to `concatArgs(PA1, PA2)`; `partialKwargs` reduces to `mergeKwargs(PK1, PK2)`. The final `build` transition appends URL args and URL kwargs, discharging `NESTED-PARTIAL-REPR`.

The Python source mirrors this constructed proof: V1 assigns `self.func`, `self.args`, and `self.kwargs` before the partial-unwrapping loop, stores separate `_func_args` and `_func_kwargs` for repr, and leaves `__getitem__()` unchanged. `view_path = url_name or self._func_path` preserves URL-name precedence.

## Adequacy and compatibility

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim, and `SPEC_AUDIT.md` marks every claim as passing against `INTENT_SPEC.md`. `PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled public callsite, override, or dispatch-shape change.

The proof is partial-correctness style over initialization/display metadata. There are no loops in the audited code slice other than the finite partial-unwrapping traversal. Termination of that traversal is a standard Python object-structure assumption for finite partial chains and is not machine-proved here.

## Findings and code decision

The only code bug found is F-001, the legacy partial repr defect. V1 discharges F-001 through PO-1 and PO-2. F-002 and F-003 confirm compatibility and nested-partial completeness. F-004 is an out-of-domain note for manual construction with non-resolver-shaped args; it does not justify changing production code for this issue. Therefore V1 stands unchanged.

## Test recommendation

No test files were edited. Existing tests should be kept because the proof was not machine-checked and this task forbids test modifications. Future public tests should cover:

- repr for a partial callback with bound keyword args;
- repr for a partial callback with bound positional args;
- repr for a nested partial callback;
- tuple-unpacking compatibility for partial callbacks.

## Reproduce the machine check later

These commands are recorded only; they were not run in this session.

```sh
kompile fvk/mini-python-resolvermatch.k --backend haskell
kast --backend haskell fvk/resolvermatch-spec.k
kprove fvk/resolvermatch-spec.k
```

Expected result after a real machine check: `#Top` for all claims.
