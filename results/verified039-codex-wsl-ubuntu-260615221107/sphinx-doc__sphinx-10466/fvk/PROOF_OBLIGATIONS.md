# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
|---|---|---|---|
| PO1 | For every message, rendered location comments contain no duplicate `(rendered_source, line)` pairs. | E1-E3, E7 | Discharged by C1-C4. |
| PO2 | Location de-duplication is general over all metadata entries for a message, not only the issue examples. | E2-E3 | Discharged by symbolic list claims over arbitrary finite `ES`. |
| PO3 | Normalization with `canon_path(relpath(source))` preserves the final rendered path for retained locations and makes equivalent paths compare equal before uniqueness. | E4-E7 | Discharged by path lemma C5; residual assumption is same-process cwd/outdir interpretation. |
| PO4 | `_unique_locations()` returns preserve-order unique locations with no duplicate retained tuple. | E1-E3, E8 | Discharged by stableUnique/uniqueSeen invariant. |
| PO5 | `Catalog.__iter__()` must normalize `(source, line)` before `Message` de-duplicates. | E4-E6 | Discharged by C2 and code inspection of V1. |
| PO6 | `Message.__init__()` must de-duplicate the normalized locations it receives. | E1, issue suggested location | Discharged by C1/C3 and code inspection of V1. |
| PO7 | Frame conditions: message text, message order, uuid list, catalog grouping, and renderer formatting are preserved. | E7-E9 | Discharged by code inspection; V1 changes only location construction/storage. |
| PO8 | FVK proof artifacts must be honest about not running tests or K tooling. | user constraints, FVK verify.md honesty gate | Discharged by labeling artifacts and commands as constructed, not machine-checked. |

## Loop Invariant For `_unique_locations`

For each processed prefix `P` and unprocessed suffix `S` of the input location
sequence:

- `unique` equals `StableUnique(P)`.
- `seen` equals the set of elements in `unique`.
- `unique` contains no duplicate locations.
- For every element in `unique`, its order is the order of its first occurrence
  in `P`.

The next iteration either skips an already-seen location, preserving the
invariant, or appends a new location and adds it to `seen`, preserving the
invariant for `P + [location]`.
