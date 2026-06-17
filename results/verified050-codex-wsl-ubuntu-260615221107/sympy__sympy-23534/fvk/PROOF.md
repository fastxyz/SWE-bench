# Constructed Proof

Status: constructed, not machine-checked. No commands in this file were run.

## Claims

The formal claims are in `fvk/symbols-spec.k`.

`SYMBOLS-FUNCTION-NESTED-RANGES` states that the modeled issue input
`symbols(tuple(range("q", 0, 2), range("u", 0, 2)), FunctionCls)` reaches a
nested tuple-like value whose four leaves all carry `FunctionCls`.

`SYMBOLS-ITERABLE-PRESERVES-CLASS` states that the modeled iterable branch
maps each child name through `symbolsValue(child, C)`, preserving the caller's
class token `C`.

## Source-Level Proof

P1. In Python, `cls` is keyword-only in
`symbols(names, *, cls=Symbol, **args)`. Therefore, inside `symbols()`,
`args` does not contain `cls`.

P2. The issue input is a non-string iterable, so execution enters the final
`else` branch of `symbols()`.

P3. Before V1, that branch called `symbols(name, **args)`. By P1, the recursive
call did not receive `cls=Function`, so it used the default `Symbol`. This
derives the reported pre-fix symptom without executing code.

P4. After V1, the branch calls `symbols(name, cls=cls, **args)`. For the issue
input, the recursive call for `'q:2'` receives `cls=Function`.

P5. The existing string/range branch expands `'q:2'` into `q0` and `q1` and
constructs each name as `cls(s, **args)`. With `cls=Function`, this is
`Function('q0')` and `Function('q1')`.

P6. `Function.__new__` returns `UndefinedFunction(*args, **options)` when
called through the base `Function` constructor. Therefore the first element in
the `q` group has undefined-function type.

P7. V1 does not alter the iterable branch's result accumulation or
`type(names)(result)` reconstruction. Therefore the outer tuple and separate
inner range groups are preserved.

P8. V1 preserves `**args` in the recursive call. Therefore assumptions and
other existing keyword arguments still reach the string/range constructor path.

Conclusion: V1 satisfies PO1 through PO7. No source edit beyond V1 is justified
by the FVK audit.

## Machine-Check Commands Not Run

The commands that would be used to machine-check the constructed artifacts are:

```sh
kompile fvk/mini-symbols.k --backend haskell
kast --backend haskell fvk/symbols-spec.k
kprove fvk/symbols-spec.k
```

Expected result if the mini semantics and claims are accepted by the K toolchain:
`kprove` discharges the claims to `#Top`.

## Test Guidance

No test was run or modified. Because this proof is not machine-checked, no
existing tests should be removed. A future public test should cover
`symbols(('q:2', 'u:2'), cls=Function)` and may also cover another custom class
such as `Dummy` or `Wild` to enforce the general `cls` propagation property.
