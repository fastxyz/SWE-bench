# Intent Spec

Status: constructed from public intent before treating the V1 implementation as authoritative.

## Required behavior

I-001: `Paginator` must implement Python iteration.

Evidence: the issue title says "Paginator just implement the __iter__ function" and the description says it would be more logical to use normal Python iteration.

I-002: Iterating a `Paginator` must visit all pages represented by its `page_range`.

Evidence: the issue says callers currently "iter into all the pages of a Paginator object" by using `page_range`.

I-003: The yielded values must be `Page` objects obtained by calling `self.page(page_num)`, not page numbers.

Evidence: the issue proposes:

```python
def __iter__(self):
    for page_num in self.page_range:
        yield self.page(page_num)
```

I-004: Iteration order must follow `page_range`.

Evidence: the proposed implementation loops directly over `self.page_range`; the public docs describe `Paginator.page_range` as "A 1-based range iterator of page numbers".

I-005: Existing pagination semantics are frame conditions. Iteration must not change how `page_range`, `page()`, `num_pages`, `orphans`, `allow_empty_first_page`, or `Page` construction work.

Evidence: the issue asks for a small addition enabling expected iteration behavior, not a change to page calculation.

I-006: Subclass page customization must remain honored.

Evidence: `Paginator._get_page()` is documented in code as the hook "used by subclasses to use an alternative to the standard Page object", and public tests include a `ValidAdjacentNumsPaginator` subclass overriding `_get_page()`.

## Domain

The proof domain is a `Paginator` instance whose `page_range` is a finite iterable of valid page numbers under that paginator's `page()` method. This domain is intent-derived from the existing `Paginator.page_range` contract and does not add a new public precondition for normal `Paginator` instances.

## Out of scope

This FVK pass does not prove termination, database query performance, warning stack levels, or correctness of the existing `count`, `num_pages`, `page_range`, `page`, or `Page.__getitem__` implementations except as frame conditions used by `__iter__()`.
