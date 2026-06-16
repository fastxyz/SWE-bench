# Intent Spec

Status: constructed, not machine-checked.

The public intent for `dateformat.y()` is:

1. For every supported Python date/datetime year `Y` in `1..9999`, format
   character `y` returns exactly two decimal digits.
2. The two digits are the last two digits of `Y`, equivalent to `Y % 100`
   rendered with left zero padding to width two.
3. The reported concrete case `Y = 123` must return `"23"`.
4. The issue's related boundary cases for years like `9`, `99`, and years below
   `999` must also be handled.
5. Existing ordinary behavior such as `Y = 1979` returning `"79"` must be
   preserved.
6. The fix must not change `Y`, unrelated date/time tokens, public call
   signatures, or formatter dispatch.
