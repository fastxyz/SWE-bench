# Formal Spec in English

Status: paraphrase of the K claims in `nominal-axis-spec.k`.

## C1 - Nominal x with no explicit limit

For every nominal x coordinate axis with `N > 0` categories and no user limit,
finalization disables the x grid and sets x limits to `(-0.5, N - 0.5)`. The y
inversion flag is not changed by this x-axis operation.

## C2 - Nominal y with no explicit limit

For every nominal y coordinate axis with `N > 0` categories and no user limit,
finalization disables the y grid and sets y limits to `(N - 0.5, -0.5)`, which
is inverted.

## C3 - Nominal x with an explicit user limit

For a nominal x coordinate axis with an explicit user limit already converted
into axis units, finalization disables the x grid and applies that user limit
rather than replacing it with categorical default bounds.

## C4 - Nominal y with an explicit user limit

For a nominal y coordinate axis with an explicit user limit already converted
into axis units, finalization disables the y grid, applies the user limit, and
inverts it when the limit order is not already inverted.

## C5 - Non-nominal axes

For non-nominal coordinate axes, the nominal-axis finalization policy does not
disable the grid, does not impose categorical default limits, and does not
invert y axes.

## C6 - Empty nominal axes

For a nominal coordinate axis with no categories (`N <= 0`) and no user limit,
the formalized V1 behavior disables the grid but does not impose categorical
default limits. The public issue does not specify this boundary case.

## C7 - Iteration over subplots and axes

The nested finalization loops are modeled by applying the one-axis transition to
each subplot axis independently. After each iteration, processed nominal axes
satisfy C1-C4 and processed non-nominal axes satisfy C5; unprocessed axes are
unchanged until their own iteration.
