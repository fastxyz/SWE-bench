# Iteration Guidance

Status: constructed, not machine-checked.

## Applied In V2

- Widened V1's protocol-relative guard from literal leading `//` to the full authority-form prefix modeled in O-001: leading C0/space characters followed by two `/` or `\` separators.
- Mirrored the same predicate in `repo/dist/node/axios.cjs` to satisfy O-005.

## Why V1 Did Not Stand Unchanged

F-001 showed that V1's `^\s*//` regex did not cover every authority-form prefix in the proof obligation. Because the issue's root cause is the fallback parser supplying a protocol to an authority-form input, the guard must cover the parser-normalized prefix class, not only the exact string in the issue example.

## Remaining Work

- No further source changes are justified by the current FVK findings.
- Do not modify tests in this benchmark.
- In a normal development environment, run the recorded K commands and the project test suite, then add public tests for the authority-form variants listed in `PROOF.md`.

