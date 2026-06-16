# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The K claims are in `fvk/paginator-iter-spec.k`.

`ITER-PAGES`:

If object `P` has `pageRange(P) = RANGE`, executing `iterPages(P)` terminates with `yielded = pagesFor(P, RANGE)`.

`YIELD-PAGES`:

For any yielded prefix `OUT`, executing `yieldPages(P, RANGE)` terminates with `yielded = appendPages(OUT, pagesFor(P, RANGE))`.

## Proof sketch for `YIELD-PAGES`

The proof is by guarded circularity over the finite `IntList` structure representing `page_range`.

Empty case:

* Start state: `<k> yieldPages(P, .Ints) </k>` with yielded prefix `OUT`.
* Semantics rule rewrites `yieldPages(P, .Ints)` to `.K`.
* `pagesFor(P, .Ints)` simplifies to `.Pages`.
* `appendPages(OUT, .Pages)` equals `OUT`.
* Postcondition holds.

Non-empty case:

* Start state: `<k> yieldPages(P, N ; NS) </k>` with yielded prefix `OUT`.
* Semantics rule rewrites to `emit(callPage(P, N)) ~> yieldPages(P, NS)`.
* `emit(callPage(P, N))` appends exactly `callPage(P, N)` to `OUT`.
* After this genuine semantic step, guarded circularity may invoke `YIELD-PAGES` on the tail `NS` with prefix `appendPages(OUT, callPage(P, N) ; .Pages)`.
* The tail proof yields:

```text
appendPages(appendPages(OUT, callPage(P, N) ; .Pages), pagesFor(P, NS))
```

* By associativity of `appendPages`, this equals:

```text
appendPages(OUT, callPage(P, N) ; pagesFor(P, NS))
```

* `pagesFor(P, N ; NS)` simplifies to `callPage(P, N) ; pagesFor(P, NS)`.
* Postcondition holds.

## Proof sketch for `ITER-PAGES`

* Start state: `<k> iterPages(P) </k>` with `pageRange` containing `P |-> RANGE` and empty yielded output.
* The `iterPages` rule looks up `RANGE` and rewrites to `yieldPages(P, RANGE)`.
* Apply `YIELD-PAGES` with `OUT = .Pages`.
* `appendPages(.Pages, pagesFor(P, RANGE))` simplifies to `pagesFor(P, RANGE)`.
* Postcondition holds.

## Source correspondence

`iterPages(P)` models:

```python
def __iter__(self):
    for page_number in self.page_range:
        yield self.page(page_number)
```

`pageRange(P)` models evaluating `self.page_range` for the loop source.

`callPage(P, N)` models dynamic dispatch of `self.page(N)`. This is the key frame condition preserving custom `page()` behavior and the `_get_page()` hook.

The model keeps page order and page-vs-number distinction observable, so it can distinguish V1 from failing alternatives such as yielding page numbers directly, yielding pages in reverse order, skipping a page number, or constructing `Page` without `self.page()`.

## Adequacy and compatibility

`fvk/SPEC_AUDIT.md` marks all formal claims as passing against `fvk/INTENT_SPEC.md`.

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public callsite, subclass, or signature blocker.

## Residual risk

This is partial correctness. Termination is not separately proved, although the modeled loop is over a finite `IntList` matching the existing finite `range` returned by `page_range`.

The proof depends on the adequacy of the mini-K model and the abstraction of `self.page(N)` as `callPage(P, N)`.

No K command was run. The proof is constructed, not machine-checked.

## Commands recorded, not executed

```sh
kompile fvk/mini-python-paginator.k --backend haskell
kast --backend haskell fvk/paginator-iter-spec.k
kprove fvk/paginator-iter-spec.k
```

Expected result after machine checking: `#Top` for both claims.

## Test redundancy recommendation

Do not remove any tests in this task. Existing pagination tests cover broader behavior not proved here, including `page()`, `Page` sequence behavior, model pagination, warnings, and `get_page()`.

After machine checking, a narrow test asserting `list(Paginator(items, per_page)) == [p.page(n) for n in p.page_range]` for an in-domain finite paginator would be subsumed by this proof. Boundary and integration tests should remain.
