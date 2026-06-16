# FORMAL_SPEC_ENGLISH

Status: constructed, not machine-checked.

`POINT-VALIDATEEVAL-PASS`: For any finite coordinate list, if no coordinate is
numeric with a nonzero imaginary part when `im` is evaluated in evaluated mode,
then the internal validation walk finishes with outcome `ok` and restores the
old evaluation flag.

`POINT-VALIDATEEVAL-ERROR`: For any finite coordinate list, if at least one
coordinate is numeric with a nonzero imaginary part when `im` is evaluated in
evaluated mode, then the internal validation walk finishes with outcome
`imaginaryError` and restores the old evaluation flag.

`POINT-VALIDATE-PASS`: Calling the top-level validation first forces evaluated
mode for the probe, then satisfies `POINT-VALIDATEEVAL-PASS`, and finally
restores the caller's old evaluation flag.

`POINT-VALIDATE-ERROR`: Calling the top-level validation first forces evaluated
mode for the probe, then satisfies `POINT-VALIDATEEVAL-ERROR`, and finally
restores the caller's old evaluation flag.

`POINT-SYMBOLIC-FRAME`: A coordinate whose `is_number` predicate is false does
not make the imaginary-coordinate guard raise.
