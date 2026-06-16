# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`combinatorics.Permutation` can't be subclassed properly" | Subclass construction must return subclass instances on in-domain construction paths. | Encoded by PO1, PO2, PO3. |
| E2 | `benchmark/PROBLEM.md` | "`_af_new` ... creates the object calling `Basic.__new__(Perm, perm)`" | The defect mechanism is base-class allocation in `_af_new`. | Encoded by PO1 and F1. |
| E3 | `benchmark/PROBLEM.md` | "use classmethods where appropriate ... use the mandatory reference to the class ... for instance creation" | Constructors should use `cls`/current class, not a module-level `Perm` alias. | Encoded by PO1, PO2, PO4. |
| E4 | public hint | "`_af_new` should probably be a `classmethod` with creating command `Basic.__new__(cls, perm)`" | `_af_new` must allocate with `cls`. | Encoded by PO1. |
| E5 | docstring in `Permutation.__new__` | Constructor accepts array form, cyclic form, `Cycle`, integer singleton, existing `Permutation`, and `size`. | The subclass fix must cover all constructor branches that allocate new objects, not only one reproducer. | Encoded by PO2 and PO3. |
| E6 | source callsites | `perm_groups.py`, `group_constructs.py`, `util.py`, `named_groups.py`, and tensor code bind `Permutation._af_new`. | Existing external aliases intentionally construct base permutations and should remain compatible. | Encoded by PO5. |
| E7 | source implementation | `_array_form` and `_size` are set by constructors and consumed throughout combinatorics. | Preserve array and size frame conditions. | Encoded by PO6. |
| E8 | task instruction | "do not attempt to run tests, Python, or K framework tooling" | Verification must be constructed only. | Encoded by PO8. |

