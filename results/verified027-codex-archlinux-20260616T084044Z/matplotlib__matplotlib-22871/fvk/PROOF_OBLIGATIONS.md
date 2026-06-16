# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: No-January month-level ticks show the year in the offset

Preconditions:

- `level == 1`.
- `self.show_offset == True`.
- No visible tick has month `1`.
- Tick list is non-empty and all visible ticks share year `Y`.
- `offset_formats[1] == "%Y"` or an equivalent user-supplied year format.

Postcondition:

- `offset_string == strftime(last_tick, offset_formats[1])`.
- Under the default format, `offset_string == str(Y)`.

Evidence: E1, E2, E3, E5.

## PO-002: January month-level ticks keep the offset suppressed

Preconditions:

- `level == 1`.
- `self.show_offset == True`.
- At least one visible tick has month `1`.

Postcondition:

- `offset_string == ""`.
- The January tick is formatted by `zero_formats[1]`, `%Y` by default.

Evidence: E4, E6.

## PO-003: Year-level ticks keep the offset suppressed

Preconditions:

- `level == 0`.
- `self.show_offset == True`.

Postcondition:

- `offset_string == ""`.
- Tick labels use `formats[0]`, `%Y` by default.

Evidence: E3.

## PO-004: Levels finer than months retain existing offset behavior

Preconditions:

- `level in {2, 3, 4, 5}`.
- `self.show_offset == True`.

Postcondition:

- `offset_string == strftime(last_tick, offset_formats[level])`.

Evidence: E5, E7.

## PO-005: User-suppressed offsets stay suppressed

Preconditions:

- `level in {0, 1, 2, 3, 4, 5}`.
- `self.show_offset == False`.

Postcondition:

- `offset_string == ""`.

Evidence: E8.

## PO-006: Label selection is frame-preserved

Preconditions:

- Any non-empty tick list in the audited domain.

Postcondition:

- For each tick and selected level, the choice between `formats[level]` and
  `zero_formats[level]` is unchanged from the pre-V1 implementation.

Evidence: the V1 code only moves `zerovals` earlier and changes the
offset-suppression condition; it does not change the label-rendering loop.

## PO-007: TeX wrapping is frame-preserved

Preconditions:

- Any audited case with `self._usetex` either true or false.

Postcondition:

- If `_usetex` is true, labels and any non-empty offset are still wrapped by
  `_wrap_in_tex`; if false, they are returned unwrapped.

Evidence: the V1 code does not edit the `_usetex` branches.

## PO-008: Honesty gate

Preconditions:

- This session has no execution environment and forbids running tests, Python,
  `kompile`, or `kprove`.

Postcondition:

- FVK artifacts must record exact commands for later machine checking and must
  label the proof as constructed, not machine-checked.

Evidence: task instructions and FVK `verify.md`.

