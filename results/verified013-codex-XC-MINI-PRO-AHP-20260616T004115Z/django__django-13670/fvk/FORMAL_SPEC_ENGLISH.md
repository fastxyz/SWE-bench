# Formal Spec English

Status: constructed, not machine-checked.

## Claim Y-TWO-DIGIT

For any integer year `Y` between 1 and 9999 inclusive, evaluating the modeled
`DateFormat.y()` expression reaches a value with exactly two digit positions.
Those positions are the tens and ones digits of `Y % 100`.

Plainly: `DateFormat.y()` returns the same result as formatting `Y % 100` as a
zero-padded two-digit decimal value.

## Frame Claim

The proof concerns only the `y` token expression. The source diff does not
change the public signature, `Formatter.format()` dispatch, `DateFormat.Y()`,
or any unrelated date/time formatter method.
