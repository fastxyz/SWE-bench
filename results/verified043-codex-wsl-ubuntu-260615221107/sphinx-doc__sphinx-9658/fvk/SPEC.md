# FVK SPEC

Status: constructed from public intent and source inspection; not machine-checked. No tests, Python, or K tooling were run.

## Intent Spec

IS-1: Mocked inherited base names must render completely.

Source: `benchmark/PROBLEM.md`, expected behavior: "The 'Bases' section should report `torch.nn.Module` not `torch.nn.`."

Obligation: for a class whose inherited base is a mocked object representing module `M` and class name `N`, autodoc's `Bases:` output must include `M.N`, including the final `N` component.

IS-2: The existing improvement that mocked-base subclasses are documented must be preserved.

Source: `benchmark/PROBLEM.md`: for `sphinx>=3.4.2`, "previously missing classes are now documented, but there is a problem with the 'Bases' section."

Obligation: the fix must not remove mocked-base subclassing support or make autodoc skip the subclass.

IS-3: Non-mocked inheritance and generic-base rendering must be preserved.

Source: `benchmark/PROBLEM.md`: "classes which inherit other classes from our own package are ok." Source tests also cover generic bases through `show-inheritance`.

Obligation: the fix should not alter `ClassDocumenter` base selection or `restify()` behavior for normal classes and typing generics.

IS-4: Existing mock API behavior must remain compatible.

Source: public in-repo tests and names around `_MockModule`, `_MockObject`, `autodoc_mock_imports`, decorators, `ismock()`, and annotation formatting.

Obligation: keep `repr(mock.attr)` as the full display path, keep mocked decorators unwrappable, keep `ismock()` behavior, and keep annotation rendering such as `missing_module.Class`.

## Public Evidence Ledger

E-1: Prompt evidence for the failing observable.

Quote: "the base class is listed as 'Bases: `torch.nn.`' instead of 'Bases: `torch.nn.Module`'."

Semantic obligation: postcondition on the rendered inheritance line. Status: encoded by PO-1 and PO-2.

E-2: Prompt evidence for the expected output.

Quote: "The 'Bases' section should report `torch.nn.Module` not `torch.nn.`."

Semantic obligation: the final mocked class-name component must be preserved through base formatting. Status: encoded by PO-1 and PO-2.

E-3: Prompt evidence for frame conditions.

Quote: "classes which inherit other classes from our own package are ok."

Semantic obligation: avoid changing normal/non-mock inheritance rendering. Status: encoded by PO-4.

E-4: Implementation evidence for the bug path.

Code: `ClassDocumenter.add_directive_header()` chooses `self.object.__orig_bases__` when present, emits `autodoc-process-bases`, then calls `restify(cls)` for every base.

Semantic obligation: the original mocked base object must carry enough metadata for `restify()` to produce the intended reference. Status: encoded by PO-2.

E-5: Implementation evidence for metadata construction.

Code: `_make_subclass(name, module)` sets `__module__` and `__display_name__`, and Python's `type(name, ...)` supplies the generated class `__qualname__`.

Semantic obligation: a mock instance created from that generated class should expose the same short `__qualname__`. Status: encoded by PO-1.

E-6: Compatibility evidence for annotation formatting.

Code: `sphinx.util.typing.stringify()` returns `repr(annotation)` before inspecting `__qualname__` for falsy annotations, and `_MockObject.__len__()` returns `0`.

Semantic obligation: V1's nonempty mock `__qualname__` does not change existing mocked annotation output. Status: encoded by PO-5.

## Formal Model

The formal core is the small abstract K model in `fvk/mini-sphinx-mock.k` and the claims in `fvk/mock-base-spec.k`.

The model intentionally abstracts away Python import machinery, HTML building, and docutils rendering. It keeps the observable axis under verification: the string produced by `restify()` for the mocked base object that `ClassDocumenter` passes to the `Bases:` line.

Model vocabulary:

- `makeSubclass(N, M)` abstracts `_make_subclass(name=N, module=M)`.
- `initMock(C)` abstracts `_MockObject.__init__()` for the instance of generated class `C`.
- `restify(O)` abstracts `sphinx.util.typing.restify()` on a mock instance carrying `__module__` and `__qualname__`.

Primary formal postcondition:

```k
claim <k>
    restify(initMock(makeSubclass("Module", "torch.nn")))
      => ":py:class:`torch.nn.Module`"
  </k>
  [all-path]
```

Generalized formal postcondition:

```k
claim <k>
    restify(initMock(makeSubclass(N:String, M:String)))
      => ":py:class:`" +String M +String "." +String N +String "`"
  </k>
  [all-path]
```

Adequacy check:

The formal postconditions say exactly that the generated mock class name is preserved as the instance `__qualname__`, so `restify()` emits `module + "." + name`. That matches IS-1 and does not encode the pre-fix buggy output.

## Compatibility Audit

Changed public symbol: `_MockObject.__init__()`.

Signature: unchanged, still accepts `*args` and `**kwargs`.

Return behavior: unchanged (`None`).

Instance metadata: changed from empty `__qualname__` to the generated class `__qualname__`.

Public callsites and affected uses:

- `_MockModule.__getattr__()` creates `_MockObject` instances. The resulting `repr()` is still governed by `__display_name__`, not `__qualname__`.
- `_MockObject.__getattr__()` creates nested mock instances. The module path still accumulates through `__display_name__`; the final name is now also available as `__qualname__`.
- `_MockObject.__call__()` creates decorator placeholders and stores `__sphinx_decorator_args__`; V1 does not change that field.
- `ismock()` checks `__sphinx_mock__` and the MRO shape; V1 does not change those.
- `typing.stringify()` keeps annotation output through the falsy-mock `repr()` branch; V1 does not change `__len__()` or `__repr__()`.

Audit result: pass. No public signature, dispatch, or producer/consumer shape changed.
