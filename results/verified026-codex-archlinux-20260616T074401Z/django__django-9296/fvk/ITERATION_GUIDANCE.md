# Iteration Guidance

## Verdict

Keep V1 unchanged.

The FVK audit found that the current source:

```python
def __iter__(self):
    for page_number in self.page_range:
        yield self.page(page_number)
```

matches the public issue proposal, discharges PO-1 through PO-8, and has no open code-bug findings in `fvk/FINDINGS.md`.

## Recommended next iteration

No production-code edit is recommended.

Future public tests, if this were ordinary development rather than the benchmark's fixed hidden suite, should cover:

* `list(paginator)` yields the same `Page` objects as `[paginator.page(n) for n in paginator.page_range]`.
* Empty `page_range` yields an empty list.
* An empty paginator with `allow_empty_first_page=True` yields the existing empty first page.
* A subclass overriding `_get_page()` receives custom page objects through iteration.

These are recommendations only. Do not edit test files in this task.

## Machine-check follow-up

The constructed K proof should be checked later with:

```sh
kompile fvk/mini-python-paginator.k --backend haskell
kast --backend haskell fvk/paginator-iter-spec.k
kprove fvk/paginator-iter-spec.k
```

The proof and any test-redundancy claim remain conditioned on `kprove` returning `#Top`.
