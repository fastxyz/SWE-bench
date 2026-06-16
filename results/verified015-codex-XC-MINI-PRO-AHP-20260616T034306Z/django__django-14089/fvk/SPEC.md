# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the benchmark issue target:
`django.utils.datastructures.OrderedSet` reverse iteration. It does not attempt
to formalize all of Django. The proof target is the observable behavior of
`list(reversed(OrderedSet(xs)))` and the representation facts needed to justify
the V1 implementation.

## Intent Ledger

E-001: `benchmark/PROBLEM.md` says "Allow calling reversed() on an OrderedSet".
This imposes a postcondition that `reversed(s)` is defined for valid
`OrderedSet` instances.

E-002: `benchmark/PROBLEM.md` says this is natural because `OrderedSet` is
ordered. This imposes an ordering postcondition: reverse iteration is the
opposite of the set's established insertion order.

E-003: `repo/django/utils/datastructures.py` describes `OrderedSet` as "A set
which keeps the ordering of the inserted items." This supports insertion order
as public API behavior.

E-004: `repo/django/utils/datastructures.py` initializes `self.dict` with
`dict.fromkeys()` and implements `__iter__()` as `iter(self.dict)`. This is
implementation evidence for the representation invariant: keys of `self.dict`
are the set contents in insertion order.

E-005: `repo/setup.cfg` states `python_requires = >=3.8`. This supports the
runtime side condition that Python dictionaries are reversible.

## Contract

Let `unique_first(xs)` be the list formed by retaining only the first occurrence
of each value in `xs`. For any finite iterable `xs` whose elements are acceptable
dictionary keys:

* `list(OrderedSet(xs)) == unique_first(xs)`.
* `list(reversed(OrderedSet(xs))) == reversed(unique_first(xs))`.
* `reversed(OrderedSet(xs))` does not mutate the `OrderedSet`.

Boundary cases:

* `list(reversed(OrderedSet([]))) == []`.
* `list(reversed(OrderedSet([a]))) == [a]`.
* `list(reversed(OrderedSet([a, b, a]))) == [b, a]`.

## Formal Core

The K model is in:

* `fvk/mini-python-orderedset.k`
* `fvk/orderedset-reversed-spec.k`

The model represents hashable Python values as integer atoms. This abstraction
is adequate for this property because the proof uses only equality,
deduplication by equality, insertion order, and reverse order. It distinguishes a
passing duplicate case (`[1, 2, 1] -> [2, 1]`) from failing alternatives such as
including duplicates (`[1, 2, 1]`) or preserving forward order (`[1, 2]`).

## Adequacy Result

The formal claims match the public intent: they require reverse iteration to be
defined, to use the reverse of insertion order, to handle empty and duplicate
inputs, and to rely only on the local Python runtime domain. No claim preserves
the legacy bug where `OrderedSet` lacked reverse iteration.
