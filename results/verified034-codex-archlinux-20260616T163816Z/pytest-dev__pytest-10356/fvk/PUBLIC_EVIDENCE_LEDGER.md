# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "markers in two baseclasses `Foo` and `Bar` ... lose the markers of one" | Multiple marked bases must all contribute marks. |
| E2 | `benchmark/PROBLEM.md` | "I'd expect `foo` and `bar` to be markers for `test_dings`" | The derived test item has both marker names. |
| E3 | public hint in `benchmark/PROBLEM.md` | "pytest should walk the mro of a class to get all markers" | Class lookup must inspect the MRO explicitly. |
| E4 | public hint in `benchmark/PROBLEM.md` | "The marks have to transfer with the mro" | Inherited marks remain part of the class marker model. |
| E5 | public discussion in `benchmark/PROBLEM.md` | Derived `test_d` should have marks from both parents: "Correct" | Newly defined tests inherit marks from all marked bases. |
| E6 | existing public tests under `repo/testing/test_mark.py` | Tests assert subclass marks do not pass to base or sibling classes. | Storage must be direct and non-mutating for bases/siblings. |
| E7 | `repo/doc/en/reference/reference.rst` | `iter_markers` yields closest-to-function markers first in its example. | Marker iteration has order semantics, but sibling-base order is not directly specified. |
| E8 | V1/root-cause code inspection | Pre-fix `getattr` follows MRO and stops at the first attribute. | Normal class attribute lookup is insufficient for this bug. |
