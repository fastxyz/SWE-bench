# Spec Audit

Status: pass.

| Formal spec | Intent item | Result | Notes |
| --- | --- | --- | --- |
| FS1 | I2/I3 | pass | Fresh shared x-axis inherits the unit state needed to avoid a late categorical update. |
| FS2 | I3 plus axis symmetry | pass | The public sharing contract is symmetric; no contrary evidence. |
| FS3 | I1-I3 | pass | Matches the reported twinx path. |
| FS4 | I1/I2 | pass | Encodes the unit-machinery root cause from public hints and source flow. |
| FS5 | I1 | pass | Directly states the expected preservation of `ax1.dataLim`. |
| FS6 | I4 | pass | Avoids candidate overreach on public `sharex` / `sharey` methods. |

No formal claim is based solely on the buggy pre-fix output. The pre-fix output
is used only as a counterexample to localize the defect.
