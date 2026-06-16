# Public Evidence Ledger

E-001

- Source: prompt / issue
- Quote: "`partitions()` iterator in `sympy.utilities.iterables` reuses the output dictionaries."
- Semantic obligation: the observable defect is dictionary object reuse at the generator yield boundary.
- Status: encoded by PO-001 and PO-002.

E-002

- Source: prompt / issue
- Quote: "It shouldn't be that much of a performance loss to copy the dictionary before yielding it."
- Semantic obligation: a shallow dictionary copy at yield time is an intended repair strategy.
- Status: encoded by PO-001, PO-002, and PO-003.

E-003

- Source: prompt / issue
- Quote: "something as simple as `list(partitions())` will give an apparently wrong result."
- Semantic obligation: retained outputs must keep their content after later generator steps.
- Status: encoded by PO-002 and PO-004.

E-004

- Source: prompt / issue
- Quote: "more subtle bugs if the partitions are used in a nontrivial way."
- Semantic obligation: yielded dictionaries should not alias mutable generator state; caller mutation of a yielded dictionary should not affect generation or other yielded outputs.
- Status: encoded by PO-001 and PO-002.

E-005

- Source: docstring
- Quote: "Each partition is represented as a dictionary, mapping an integer to the number of copies of that integer in the partition."
- Semantic obligation: preserve the public return type and dictionary contents.
- Status: encoded by PO-004 and PO-006.

E-006

- Source: docstring
- Quote: "when `True` then `(M, P)` is returned where M is the sum of the multiplicities and P is the generated partition."
- Semantic obligation: size mode has the same dictionary snapshot obligation for `P`, while keeping `M` accurate.
- Status: encoded by PO-003 and PO-006.

E-007

- Source: public tests
- Quote: public tests compare `[p.copy() for p in partitions(...)]` to expected partition dictionaries.
- Semantic obligation: the existing sequence of partition values is public compatibility evidence; the repair must not change value equality or filtering semantics.
- Status: encoded by PO-004. The old need for caller-side `.copy()` is SUSPECT legacy behavior because it conflicts with E-001 through E-003.

E-008

- Source: source callsites
- Quote: internal consumers iterate `for size, p in partitions(..., size=True)` and use `p.items()` or `sorted(p)`.
- Semantic obligation: preserve `size=True` tuple shape and dictionary API.
- Status: encoded by PO-006.
