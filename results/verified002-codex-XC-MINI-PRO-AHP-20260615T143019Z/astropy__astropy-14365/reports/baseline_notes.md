# Baseline Notes

## Root cause

The QDP ASCII reader classifies each input line in `astropy/io/ascii/qdp.py`
with `_line_type()`. Its command pattern only matched uppercase `READ SERR`
and `READ TERR` directives:

```python
READ [TS]ERR
```

QDP commands are case-insensitive, so a valid line such as `read serr 1 2`
failed command classification and fell through to `ValueError:
Unrecognized QDP line`.

## Changed files

- `repo/astropy/io/ascii/qdp.py`
  - Made the `READ SERR` / `READ TERR` command portion of the line classifier
    case-insensitive with a scoped regex flag.
  - Added a lowercase command example to the `_line_type()` docstring to
    document the intended behavior.

## Assumptions

- The issue is limited to command recognition. The downstream parser already
  stores the error command keyword with `command[1].lower()`, so once lowercase
  command lines are recognized, existing `serr` / `terr` handling should work.
- QDP command arguments remain whitespace-separated column numbers. The issue
  did not indicate any change to the accepted command grammar beyond command
  keyword casing.
- The writer can continue emitting uppercase `READ SERR` and `READ TERR`; the
  requested behavior concerns reading hand-written QDP files.

## Alternatives considered and rejected

- Compile the entire line-type regex with `re.IGNORECASE`. This would also make
  non-command tokens such as `NO` case-insensitive, which is broader than the
  reported bug requires.
- Lowercase the full input line before matching. That could alter comment text
  or other content if reused later and is unnecessary for command recognition.
- Add or modify test files. The benchmark explicitly forbids changing tests, so
  the fix is limited to source code and this report.

## Verification

No tests or project code were run because the benchmark instructions explicitly
state that this session has no execution environment and forbid running tests or
any code.
