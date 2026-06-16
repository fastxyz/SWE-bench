# FVK PROOF

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## What Is Proved

For a mocked inherited base created from a module path `M` and class/attribute name `N`, V1 ensures the mock instance carries `__qualname__ == N`. Therefore autodoc's existing `restify()` path renders the base as the Python class role for `M.N`. For the issue's concrete case, the Bases line receives the class role for `torch.nn.Module` rather than `torch.nn.`.

This proof covers the source-to-observable path described by PO-1 through PO-3:

1. mocked attribute access creates a generated mock class with module path and short class name;
2. `_MockObject.__init__()` copies the generated class qualname onto the instance;
3. `ClassDocumenter` passes the original mocked base to `restify()`;
4. `restify()` formats `__module__ + "." + __qualname__`.

## Adequacy Gate

Intent: IS-1 requires complete mocked inherited base names, specifically `torch.nn.Module` rather than `torch.nn.`.

Formal English: the K claims in `fvk/mock-base-spec.k` say that `restify(initMock(makeSubclass("Module", "torch.nn")))` reaches the string `:py:class:\`torch.nn.Module\`` and, generally, `restify(initMock(makeSubclass(N, M)))` reaches the Python class role for `M.N`.

Audit result: pass. The formal postconditions match the public intent and do not encode the pre-fix legacy output.

Compatibility audit result: pass. PO-4, PO-5, and PO-6 show that normal base rendering, typing generic base rendering, annotation stringification, decorator unwrapping, and mock detection are frame-preserved.

## Constructed Proof

### PO-1: Mock Instance Qualname Propagation

Symbolic start:

```text
initMock(makeSubclass(N, M))
```

Apply the `makeSubclass` abstraction:

```text
makeSubclass(N, M) => mockClass(N, M, N)
```

The third field is the generated class qualname. This is justified by Python's `type(name, bases, attrs)` class creation behavior and the local code's use of `type(name, ...)` in `_make_subclass()`.

Apply the V1 `initMock` abstraction:

```text
initMock(mockClass(N, M, N)) => mockObj(M, N, M + "." + N)
```

The mock instance now carries module `M`, qualname `N`, and display name `M.N`.

Conclusion: PO-1 holds for all modeled `M` and `N`.

### PO-2: Bases Rendering

Symbolic start:

```text
restify(initMock(makeSubclass(N, M)))
```

By PO-1:

```text
initMock(makeSubclass(N, M)) => mockObj(M, N, M + "." + N)
```

Apply the `restify` abstraction:

```text
restify(mockObj(M, N, _)) => ":py:class:`" + M + "." + N + "`"
```

Concrete instantiation for the issue:

```text
M = "torch.nn"
N = "Module"
```

Result:

```text
":py:class:`torch.nn.Module`"
```

This is the string `ClassDocumenter` places after `Bases:` before docutils/HTML rendering.

### PO-3: Nested Mock Path Closure

For direct submodule import, `_MockModule("torch.nn").__getattr__("Module")` calls `_make_subclass("Module", "torch.nn")`, so PO-1 and PO-2 apply directly.

For chained attribute access, `_MockModule("torch").__getattr__("nn")` creates a mock object whose display path is `torch.nn`. `_MockObject.__getattr__("Module")` uses that display path as the next module argument, producing `_make_subclass("Module", "torch.nn")`. PO-1 and PO-2 then apply.

The induction step is: if a mock object displays path `P`, accessing attribute `A` creates a child with display path `P.A` and short qualname `A`.

### PO-4 through PO-6: Frame Conditions

PO-4 follows syntactically: V1 does not edit `ClassDocumenter`, `restify()`, typing generic handling, or normal class handling.

PO-5 follows from branch order in `typing.stringify()`: mock annotations are falsy because `_MockObject.__len__()` returns `0`, so they stringify through `repr(annotation)`. V1 does not edit `__len__()` or `__repr__()`.

PO-6 follows syntactically: V1 does not edit `__mro_entries__()`, `_make_subclass()`, `__call__()`, `undecorate()`, `ismock()`, or the mock marker fields used by those paths.

## Why V1 Stands

The pre-fix implementation violated IS-1 because the original mock base carried an empty instance `__qualname__`. V1 changes exactly that metadata source. The proof obligations show that this is sufficient for the reported Bases output and narrower than changing `ClassDocumenter` or `restify()`.

No additional source edits are justified by the FVK findings.

## Residual Risk

The proof is constructed, not machine-checked. The exact commands to run in a normal environment are:

```sh
cd fvk
kompile mini-sphinx-mock.k --backend haskell
kast --backend haskell mock-base-spec.k
kprove mock-base-spec.k
```

The proof is partial over the modeled observable. It does not prove full Python import semantics, docutils HTML rendering, termination, performance, or unspecified parameterized mocked-base display forms.

## Test Guidance

Do not delete tests based on this un-machine-checked proof.

Recommended tests to add in a normal development environment:

- an autodoc `show-inheritance` case for a class inheriting `missing_module.Class`, expecting the Bases line to contain the Python class role for `missing_module.Class`;
- a nested mocked path case equivalent to `torch.nn.Module`;
- a frame test showing mocked annotation output remains `missing_module.Class`.
