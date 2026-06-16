# Formal Specification In English

Status: paraphrase of the K claims in `concise-date-formatter-spec.k`.

1. C-001: For selected level `1`, `showOffset=true`, no January tick, and
   same-year ticks with year `Y`, the offset decision returns `year(Y)`.
2. C-002: For selected level `1`, `showOffset=true`, and at least one January
   tick, the offset decision returns `noOffset`.
3. C-003: For selected level `0` and `showOffset=true`, the offset decision
   returns `noOffset`.
4. C-004: For selected levels `2` through `5` and `showOffset=true`, the
   offset decision returns the existing level-specific formatted offset.
5. C-005: For any selected level `0` through `5` and `showOffset=false`, the
   offset decision returns `noOffset`.

