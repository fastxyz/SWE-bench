# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 was mostly aligned with the intent, but FVK finding F1 surfaced a dependency
tracking gap in the new `ClassDocumenter` source-comment path. V2 keeps the V1
content behavior and adds `self.directive.record_dependencies.add(analyzer.srcname)`
when a class-alias docstring-comment is found.

No other code changes are recommended by the current proof obligations.

## Tests To Add Or Keep

Do not modify tests in this benchmark task. For a normal project follow-up, keep
or add tests for:

- a module-level `Dict[...]` alias with a next-line docstring: docstring rendered,
  fallback absent;
- a module-level `Callable[...]` alias with a next-line docstring: docstring
  rendered, fallback absent;
- a module-level `Union[...]` alias with a next-line docstring: docstring
  rendered, fallback absent;
- an undocumented generic alias: fallback still rendered;
- a `ClassDocumenter.doc_as_attr` alias with a source docstring-comment:
  docstring rendered, fallback absent, aliasing source recorded as a dependency.

Existing tests that expect documented aliases to include `alias of ...` are
SUSPECT under the issue intent and should be revised after human review, not
treated as a reason to preserve legacy behavior.

## Machine Check

When a K environment is available, run:

```sh
kompile fvk/mini-autodoc-alias.k --backend haskell
kast --backend haskell fvk/autodoc-alias-spec.k
kprove fvk/autodoc-alias-spec.k
```

Until `kprove` returns `#Top`, treat the proof as constructed evidence and keep
the normal regression tests.
