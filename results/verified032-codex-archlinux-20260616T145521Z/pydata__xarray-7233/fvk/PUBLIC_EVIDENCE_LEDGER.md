# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt / issue | "`ds.Coarsen.construct` demotes non-dimensional coordinates to variables" | The defect is loss of coordinate classification during `Dataset.coarsen(...).construct(...)`. | Encoded by I2/I3 and PO2. |
| E2 | prompt / issue | "All variables that were coordinates before the coarsen.construct stay as coordinates afterwards." | Universal coordinate-preservation postcondition over all original coordinate variable names. | Encoded by I2 and K claim `COORD-PRESERVATION-V2`. |
| E3 | prompt / issue example | `day` appears under `Coordinates` before and after `construct`; dimensions change from `(time)` to `(year, month)`. | Coordinate preservation applies even when the coordinate is not itself a coarsened dimension name and its dimensions are reshaped. | Encoded by I3, F1, and `PREFIX-COUNTEREXAMPLE`. |
| E4 | source docstring | `construct` "Convert this Coarsen object to a DataArray or Dataset, where the coarsening dimension is split or reshaped to two new dimensions." | The operation is a reshape/split, not a semantic demotion of coordinates to measured data variables. | Supports I1/I2. |
| E5 | source Dataset docs | Dataset "consists of variables, coordinates and attributes" and `coords` items are saved as "coordinate". | Coordinate membership is observable API state, represented internally by `_coord_names`. | Supports modeling coordinate status as membership in result coordinates. |
| E6 | source implementation | The reshape loop iterates `for key, var in obj.variables.items()` and assigns each `key` into `reshaped`. | Implementation fact for proof: original coordinate names are present as variables before `set_coords` is called. | Encoded by PO1/LOOP-PRESERVES-NAMES. |
| E7 | source implementation | `Dataset.set_coords` copies the dataset and updates `_coord_names` with `names` after asserting names exist. | Implementation fact for proof: passing all original coordinate names to `set_coords` establishes coordinate membership. | Encoded by PO2. |
| E8 | source implementation | `DataArray._to_temp_dataset` uses `coord_names = set(self._coords)` and `_THIS_ARRAY` is the data variable. | DataArray path should not turn the temporary data variable into an original coordinate; original DataArray coords remain the coordinate set to preserve. | Encoded by PO3. |
| E9 | V1 diff | V1 changed `set(window_dim) & set(self.obj.coords)` to `set(self.obj.coords)`. | Candidate fix directly replaces a dimension-name intersection with the full original coordinate set. | Audited by PO2 and F2. |

