# FVK ITERATION GUIDANCE

Status: V1 stands unchanged.

## Decision

Keep the V1 source change:

```python
self.__qualname__ = self.__class__.__qualname__
```

The decision is supported by F-001 and proof obligations PO-1, PO-2, and PO-3. The change repairs the metadata that the existing Bases rendering path already consumes.

## Changes Not Made

Do not rewrite mocked bases in `ClassDocumenter`.

Reason: F-002 and PO-4 show that changing the mock object's metadata is narrower and preserves the existing event and generic-base flow.

Do not add a mock-specific branch to `sphinx.util.typing.restify()`.

Reason: PO-1 establishes that the generic `__module__ + "." + __qualname__` contract can work for mock instances once their metadata is correct. A mock-specific `restify()` branch would duplicate metadata semantics outside the mock implementation.

Do not change annotation or decorator paths.

Reason: F-003, PO-5, and PO-6 show those paths are frame-preserved.

## Recommended Future Tests

These are recommendations only; no tests were edited in this task.

- Add an autodoc fixture where `autodoc_mock_imports = ["missing_module"]`, a class inherits `missing_module.Class`, and `:show-inheritance:` expects the Bases line to contain the Python class role for `missing_module.Class`.
- Add a nested-path fixture for `torch.nn.Module` or an equivalent mocked module path.
- Keep existing tests around mock annotations and decorators.

## Machine-Check Follow-Up

In an environment with K installed, run:

```sh
cd fvk
kompile mini-sphinx-mock.k --backend haskell
kast --backend haskell mock-base-spec.k
kprove mock-base-spec.k
```

Expected result: `kprove` discharges the claims to `#Top`.

## Open Questions

F-006 records one underspecified area: display of parameterized mocked bases such as `missing_module.Base[T]`. The public issue does not require a change there, so it is not a blocker for this fix.
