# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Verdict | Notes |
| --- | --- | --- | --- |
| `REMAINDER-PROPAGATED` | E1, E2, E4 | Pass | Directly encodes the issue's missing propagation to estimator-valued `remainder`. |
| `CLONED-REMAINDER-PANDAS` | E5, E6 | Pass | Models the actual fit path: `_iter` includes `_remainder`, `_fit_transform` clones it, and clone copies output config. |
| `PANDAS-HSTACK` | E3, E7 | Pass | Preserves the discriminator that made the reported output wrong: all child chunks must be pandas for pandas concat. |
| `SENTINEL-UNCHANGED` | E4, E5 | Pass | `drop` and `passthrough` are not estimator-valued remainder cases. |
| `NONE-NOOP` | E8 | Pass after V2 | V1 relied on `_safe_set_output` even for `None`; V2 adds an explicit no-op before capability checks. |

## Adequacy Result

The formal claims cover the full issue-relevant behavior space:

- pre-fit `set_output(pandas)`;
- estimator-valued remainder;
- fit-time clone of the remainder;
- pandas dense stacking branch;
- sentinel remainders;
- `transform=None` no-op behavior for the helper used by the new remainder
  propagation call.

The formal model intentionally does not prove full pandas dtype mechanics. It
does prove the branch discriminator that caused dtype loss in the issue.
