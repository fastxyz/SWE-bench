# Intent Specification

Status: intent-only; written from public evidence before accepting candidate
behavior.

1. In a plot covering less than one year where January is not included among
   visible month ticks, the year must still be visible.
2. For the reproducer, the visible year is `2021`, and the expected location
   is the offset to the right of the x-axis.
3. `ConciseDateFormatter` should remain concise: when a January month tick is
   visible, that tick can carry the year via the zero-format and the offset can
   remain empty.
4. `show_offset=False` must continue to suppress offsets.
5. Existing finer-grained offset behavior is not part of the reported defect
   and should be preserved.

