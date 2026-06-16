# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Verdict | Notes |
|---|---|---|---|
| `LOOP-PRESERVES-NAMES` | I1, E6 | Pass | The claim is implementation-derived only for the loop mechanics, but it supports the intent-derived coordinate-preservation proof. |
| `COORD-PRESERVATION-V2` | I2, I3, I4, E1, E2, E3 | Pass | This exactly states that all original coordinates remain coordinates after construct. It is not weakened to dimension coordinates only. |
| `PREFIX-COUNTEREXAMPLE` | E1, E3, baseline root cause | Pass | This demonstrates why the old intersection with `window_dim` violated the public issue. |
| `DATAARRAY-TEMP-PRESERVATION` | I6, E8 | Pass | The shared `construct` path remains compatible with DataArray inputs because `_THIS_ARRAY` is not part of `self.obj.coords`. |
| Exact equality of result coordinates | I5 | Not claimed | Public intent requires preserving original coordinates, not proving no xarray dimension-coordinate rule can add another coordinate. |
| Invalid argument behavior | In-domain definition | Not claimed | Existing validation branches are outside the issue's repair obligation and were not changed. |

No required behavior is marked fail or ambiguous.

