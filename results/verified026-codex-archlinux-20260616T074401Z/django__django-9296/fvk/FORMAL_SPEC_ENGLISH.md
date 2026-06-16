# Formal Spec English

This is the adequacy round trip for the K claims in `paginator-iter-spec.k`.

Claim `ITER-PAGES`:

Given a paginator object `P`, if the model's `pageRange` cell maps `P` to a finite list of page numbers `RANGE`, executing `iterPages(P)` terminates with the yielded sequence equal to `pagesFor(P, RANGE)`.

Meaning of `pagesFor(P, RANGE)`:

For the empty page-number list, `pagesFor(P, .Ints)` is the empty page list. For a non-empty list `N ; REST`, `pagesFor(P, N ; REST)` is `callPage(P, N) ; pagesFor(P, REST)`.

Claim `YIELD-PAGES`:

For any current yielded prefix `OUT`, executing `yieldPages(P, RANGE)` appends exactly `pagesFor(P, RANGE)` to `OUT`, preserving order and adding no other values.

Meaning of `callPage(P, N)`:

`callPage(P, N)` is the observable result of dynamically calling `P.page(N)`. It intentionally abstracts the existing `page()` body while preserving the property under audit: the iterator calls `page()` for each page number rather than yielding raw numbers or constructing pages by another path.

Frame condition:

The claims do not alter the model's `pageRange` map. They reason only about the new iterator traversal and delegate page creation to the existing `page()` behavior.

Machine status:

The claims are constructed, not machine-checked.
