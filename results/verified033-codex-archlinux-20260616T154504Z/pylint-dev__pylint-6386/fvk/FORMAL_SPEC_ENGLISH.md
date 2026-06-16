# Formal Spec English

Status: constructed, not machine-checked.

## C1: SHORT-VERBOSE

Starting preprocessing with `-v` followed by arbitrary remaining arguments advances to preprocessing those remaining arguments, with `Run.verbose` changed from `False` to `True` and with no output argument produced for `-v` itself.

## C2: SHORT-VERBOSE-AFTER-FILE

Starting preprocessing with an ordinary file argument followed by `-v` terminates with the file argument preserved in the output list and `Run.verbose` changed from `False` to `True`.

## C3: SHORT-VERBOSE-VALUE-ERROR

Starting preprocessing with an inline value form of the short verbose option, represented as `-v=VALUE`, terminates in the preprocessing error state for "`-v` does not expect a value."

## C4: SEPARATOR-FRAME

Starting preprocessing with the argument separator `--` followed by `-v` and arbitrary remaining arguments terminates with the separator, `-v`, and the remaining arguments preserved in output, and `Run.verbose` unchanged.

## C5: VERBOSE-NARGS-ZERO

The verbose option descriptor evaluates to argparse `nargs = 0`, so argparse parses and renders the option as a flag.
