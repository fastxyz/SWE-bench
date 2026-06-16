# Intent Specification

Status: intent-only.

I1. In the reported twinned-axis sequence, later plotting on `ax2` must not
change the existing `ax1.dataLim`.

I2. The bug is a unit-handling edge case for categorical string data on a
shared axis.

I3. A fresh twin axis should inherit the shared axis' unit conversion state
when sharing is established.

I4. Existing unit state on a non-fresh receiving axis should not be overwritten
without explicit public intent.
