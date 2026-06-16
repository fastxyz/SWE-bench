# Public Evidence Ledger

See `fvk/SPEC.md` for the full ledger. The critical entries are:

- E1: the issue reports `ax1.dataLim` becoming `[inf, -inf]`.
- E2: the expected behavior is not to change `ax1.dataLim` because no data was
  added to `ax1`.
- E3: the public hints localize the issue to unit machinery and creation order.
- E4: source comments and method names support sharing axis information.
- E5: `Axes.relim()` currently documents that collections are not supported.
