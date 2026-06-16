# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`cs.set_paths(transformed_paths)`" | `ContourSet` exposes a callable setter with one `paths` argument. | Encoded in spec claim CSET-SET-PATHS. |
| E2 | prompt | "`paths = cs.get_paths(); paths[:] = transformed_paths`" | The setter replaces the contour path sequence used by `get_paths`/`_paths`, rather than transforming values internally. | Encoded in final `<paths>` postcondition. |
| E3 | prompt | "replaces all the paths on the `ContourSet`" | Consumers of the `ContourSet` path store should see the new path sequence. | Encoded in path replacement postcondition. |
| E4 | public hint | "copy what `PathCollection` has" | Setter should assign `_paths` and mark the artist stale, mirroring `PathCollection.set_paths`. | Encoded in stale postcondition. |
| E5 | implementation | `Collection.set_paths` raises `NotImplementedError`; `Collection.get_paths` returns `_paths`. | The legacy behavior is self-declared incompleteness for this in-domain setter call. | Finding F1; fixed by `ContourSet.set_paths`. |
| E6 | implementation | `_split_path_and_get_label_rotation` deletes `_old_style_split_collections` before mutating `_paths`. | Cached old-style collections are derived from `_paths` and should be invalidated when `_paths` changes. | Finding F2; fixed in V2. |
| E7 | implementation | Other collection subclasses override `set_paths` with specialized setters. | Avoid broad base-class behavior changes. | Encoded in compatibility audit and notes. |

