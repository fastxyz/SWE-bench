# Public Evidence Ledger

E-001

* Source: `benchmark/PROBLEM.md`
* Evidence: "Allow calling reversed() on an OrderedSet"
* Obligation: `reversed(OrderedSet(...))` is defined for valid instances.
* Status: encoded by PO-003 and the main K claim.

E-002

* Source: `benchmark/PROBLEM.md`
* Evidence: "This would be natural to support given that OrderedSet is ordered."
* Obligation: reverse iteration must use the collection's established order.
* Status: encoded by PO-001, PO-003, and the main K claim.

E-003

* Source: `repo/django/utils/datastructures.py`
* Evidence: class docstring says "A set which keeps the ordering of the inserted items."
* Obligation: insertion order is part of the public class contract.
* Status: encoded by PO-002.

E-004

* Source: `repo/django/utils/datastructures.py`
* Evidence: `self.dict = dict.fromkeys(iterable or ())` and `__iter__()` returns `iter(self.dict)`.
* Obligation: the implementation representation is a dict whose keys are the ordered set elements.
* Status: modeled as `dictFromKeys()` and `iter(os(KS))` in the K semantics.

E-005

* Source: `repo/setup.cfg`
* Evidence: `python_requires = >=3.8`
* Obligation: use of Python dictionary reverse iteration is within the supported runtime domain.
* Status: encoded by PO-006.
