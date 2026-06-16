# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 needed one improvement: attribute-comment visibility metadata must take precedence over conflicting runtime-docstring visibility metadata when documenting variables. V2 implements that change in `repo/sphinx/ext/autodoc/__init__.py`.

## Next code iteration

No further source change is justified by the current FVK findings. Do not change the parser, analyzer, importer, directive options, or tests for this task.

## Suggested tests for a future executable environment

Do not edit tests in this benchmark task. In a normal development environment, add focused coverage for:

* `_foo = None  #: :meta public:` appears under `automodule :members:`.
* `foo = None  #: :meta private:` is hidden under `automodule :members:` unless private members are admitted.
* A variable with `#: :meta public:` remains visible even if the assigned object's runtime docstring contains `:meta private:`.
* Existing function docstring `:meta public:` / `:meta private:` tests continue to pass.

## Commands to run later, not in this session

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-filter-spec.k
kprove fvk/autodoc-filter-spec.k
```

Then run the Sphinx autodoc test subset. Keep all tests until the proof is actually machine-checked and maintainers decide whether any local unit tests are redundant.
