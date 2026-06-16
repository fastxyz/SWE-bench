# FVK PROOF OBLIGATIONS

Status: constructed, not machine-checked. The formal claims are mirrored in `fvk/mock-base-spec.k`.

## PO-1: Mock Instance Qualname Propagation

Intent trace: IS-1, E-2, E-5.

Statement: for a generated mock class created from `_make_subclass(name=N, module=M)`, a newly initialized mock instance must expose `__module__ == M` and `__qualname__ == N`.

Precondition: `N` is the mocked attribute/class name and `M` is the mocked module path accumulated by `_MockModule.__getattr__()` or `_MockObject.__getattr__()`.

V1 implementation fact: `_MockObject.__init__()` assigns `self.__qualname__ = self.__class__.__qualname__`.

Formal claim:

```k
claim <k>
    initMock(makeSubclass(N:String, M:String))
      => mockObj(M, N, M +String "." +String N)
  </k>
  [all-path]
```

Discharge argument: `_make_subclass()` constructs a Python class whose `__module__` is `M`; Python's `type(name, ...)` supplies class `__qualname__ == N`; V1 copies that class `__qualname__` onto the instance.

Status: discharged by V1.

## PO-2: Bases Rendering for Original Mock Bases

Intent trace: IS-1, E-1, E-2, E-4.

Statement: when `ClassDocumenter` obtains a mocked original base from `__orig_bases__`, `restify(base)` must render a Python class reference containing `M.N`, not `M.`.

Precondition: the base object is a `_MockObject` instance produced as in PO-1.

Formal claim:

```k
claim <k>
    restify(initMock(makeSubclass("Module", "torch.nn")))
      => ":py:class:`torch.nn.Module`"
  </k>
  [all-path]
```

General claim:

```k
claim <k>
    restify(initMock(makeSubclass(N:String, M:String)))
      => ":py:class:`" +String M +String "." +String N +String "`"
  </k>
  [all-path]
```

Discharge argument: `restify()`'s py37+ branch formats any object with `__qualname__` as `:py:class:` + `__module__` + "." + `__qualname__`; PO-1 gives nonempty `N` for mocked base instances.

Status: discharged by V1.

## PO-3: Nested Mock Path Closure

Intent trace: IS-1 and the issue's nested `torch.nn.Module` example.

Statement: nested mock attribute access preserves all parent path components as the next module path and preserves the final attribute as the next short qualname.

Precondition: starting from module `torch`, attribute access proceeds through `nn` and then `Module`, or starts directly from mocked module `torch.nn` and accesses `Module`.

Discharge argument: `_MockModule.__getattr__(name)` calls `_make_subclass(name, self.__name__)`; `_MockObject.__getattr__(key)` calls `_make_subclass(key, self.__display_name__, self.__class__)`; `__display_name__` is constructed as `module + "." + name`. By one-step induction on the attribute chain, the final object for `torch.nn.Module` has module `torch.nn` and qualname `Module`.

Status: discharged by existing code plus PO-1.

## PO-4: Non-Mock and Generic Base Frame

Intent trace: IS-3, E-3.

Statement: the change must not alter rendering for normal classes, own-package classes, or typing generic bases.

Precondition: base object is not a `_MockObject` instance initialized by autodoc mocking.

Discharge argument: V1 edits only `_MockObject.__init__()`. `ClassDocumenter` still selects `__orig_bases__` and `__bases__` the same way; `restify()` is unchanged; all non-mock and typing branches are syntactically identical to the baseline.

Status: discharged by frame reasoning.

## PO-5: Mock Annotation Formatting Frame

Intent trace: IS-4, E-6.

Statement: mocked objects used as type annotations continue to stringify through their display path, not through the new `__qualname__` branch.

Precondition: annotation is a `_MockObject` instance.

Discharge argument: `_MockObject.__len__()` returns `0`, so `typing.stringify()` takes its `elif not annotation: return repr(annotation)` branch before reaching `_stringify_py37()` and its `__qualname__` branch. V1 does not alter `__len__()` or `__repr__()`.

Status: discharged by frame reasoning.

## PO-6: Mock API Compatibility Frame

Intent trace: IS-2, IS-4.

Statement: mocked subclassing, decorator unwrapping, and `ismock()` detection continue to work.

Precondition: existing mock objects are created, called as decorators, inherited from, or checked by `ismock()`.

Discharge argument: V1 does not change `_make_subclass()`, `__mro_entries__()`, `__call__()`, `__sphinx_decorator_args__`, `__sphinx_mock__`, or generated-class MRO shape. The only changed field is instance `__qualname__`, which these APIs do not use for their control flow.

Status: discharged by frame reasoning.

## Machine-Check Commands

These commands are recorded for a normal environment. They were not executed here.

```sh
cd fvk
kompile mini-sphinx-mock.k --backend haskell
kast --backend haskell mock-base-spec.k
kprove mock-base-spec.k
```
