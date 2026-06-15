# Iteration Guidance

Status: constructed from FVK audit.

## Code decision

V1 stands unchanged.

Rationale:

- F-001 and PO-1 justify the `split_exclude()` metadata copy.
- F-002 and PO-2 justify preserving filtered relation conditions across
  `trim_start()`.
- F-003 and PO-3 justify keeping the alias-safety guard.
- F-004, PO-4, and PO-5 show no compatibility issue requiring a code change.

## Tests to add to the fixed hidden/public suite

Do not modify tests in this task. If tests were being added separately, the FVK
audit suggests:

1. `exclude(book_alice__isnull=False)` on
   `FilteredRelation('book', condition=Q(book__title__iexact='poem by alice'))`
   should not raise `FieldError` and should exclude authors with matching
   filtered books.
2. `exclude(book_alice__title__contains='Jane')` on
   `FilteredRelation('book', condition=Q(book__title__startswith='The book by'))`
   should exclude only rows matching both predicates, covering the public Rob
   example.
3. A condition that references a parent alias, such as a base-field predicate,
   should not produce SQL with a missing alias after trimming.
4. Existing unfiltered multi-valued `exclude()` tests should remain.

## Machine-check guidance

The FVK proof is constructed, not machine-checked. In an environment with K,
run:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/django-11265-spec.k
kprove fvk/django-11265-spec.k
```

Keep all tests until the proof is machine-checked and conventional Django tests
pass in a real execution environment.

