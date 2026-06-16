# FVK Spec

Status: constructed, not machine-checked.

## Target

`repo/django/core/paginator.py`, method `Paginator.__iter__()`.

V1 source under audit:

```python
def __iter__(self):
    for page_number in self.page_range:
        yield self.page(page_number)
```

## Public intent ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligations are:

* `Paginator` implements Python iteration. Evidence: the issue asks for `__iter__`.
* Iteration covers all pages in `page_range`. Evidence: the issue says callers currently iterate all pages by using `page_range`.
* Iteration yields page objects produced by `self.page(page_num)`. Evidence: the issue's proposed implementation.
* The traversal order is `page_range` order. Evidence: the proposed `for page_num in self.page_range` loop and docs describing `page_range` as a 1-based range of page numbers.
* Existing pagination behavior is a frame condition. Evidence: the issue requests a small expected behavior addition, not a page calculation change.
* Subclass page customization is a frame condition. Evidence: `page()` delegates to `_get_page()`, and public tests exercise a subclass overriding `_get_page()`.

## Formal model

The mini-K semantics are in `fvk/mini-python-paginator.k`; K claims are in `fvk/paginator-iter-spec.k`.

The model keeps the property under audit visible:

* `pageRange(P)` is represented by the `pageRange` cell mapping object `P` to a finite ordered `IntList`.
* Dynamic `self.page(N)` dispatch is represented by the observable value `callPage(P, N)`.
* The yielded output sequence is represented by the `yielded` cell as a `PageList`.

The model abstracts the internals of `page()`, `num_pages`, object slicing, and `Page` sequence behavior because V1 delegates to those existing APIs and does not change them.

## Contract

For any paginator object `P` with finite page-number list `RANGE = self.page_range`, consuming `iter(P)` yields exactly:

```text
[self.page(N) for N in RANGE]
```

in the same order as `RANGE`, with no extra yielded values and no omitted yielded values.

Boundary consequences:

* If `page_range` is empty, iteration yields no pages.
* If `page_range` contains only page 1, iteration yields exactly `self.page(1)`.
* For ordinary `Paginator`, those boundary cases are inherited from existing `num_pages` and `allow_empty_first_page` behavior.

## Adequacy

The formal-English round trip is in `fvk/FORMAL_SPEC_ENGLISH.md`, and the claim-by-claim adequacy audit is in `fvk/SPEC_AUDIT.md`. All formal claims pass the public-intent audit.

## Compatibility

The compatibility audit is in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`. It found no public callsite, subclass, or signature blocker. The important compatibility point is that V1 calls `self.page(page_number)`, preserving dynamic dispatch and the `_get_page()` hook.
