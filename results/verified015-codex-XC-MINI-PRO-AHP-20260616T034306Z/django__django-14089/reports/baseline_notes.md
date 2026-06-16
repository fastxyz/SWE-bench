# Baseline Notes

## Root cause

`django.utils.datastructures.OrderedSet` stores its contents in insertion order
using a backing `dict` and exposes forward iteration with `__iter__()`, but it
doesn't implement `__reversed__()`. Python's `reversed()` therefore can't obtain
a reverse iterator for `OrderedSet`, even though the collection has a stable
insertion order.

## Changed files

* `repo/django/utils/datastructures.py`: Added `OrderedSet.__reversed__()` and
  delegated to `reversed(self.dict)`, which returns the keys of the backing
  insertion-ordered dictionary from newest to oldest.

## Assumptions and rejected alternatives

* I assumed Django 4.0's supported Python versions include dictionary reverse
  iteration, so using `reversed(self.dict)` is the most direct implementation.
* I rejected converting keys to a list, such as `reversed(list(self.dict))`,
  because that needlessly copies the set contents.
* I rejected changing tests because the task explicitly forbids modifying test
  files and hidden tests are expected to cover the new behavior.
