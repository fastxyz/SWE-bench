# Public Compatibility Audit

Changed symbols:

- `Axes.sharex(self, other)`
- `Axes.sharey(self, other)`

Compatibility result:

- Signatures are unchanged.
- Return behavior remains unchanged (`None`).
- Existing ticker, limit, and scale sharing behavior remains in place.
- Receivers with existing unit state are not overwritten because V1 copies only
  when `have_units()` is false.
- No public callsite or subclass override signature needs updating.

Rejected broad change:

- `Axes.relim()` was not changed. Its documented lack of collection support is
  preserved.
