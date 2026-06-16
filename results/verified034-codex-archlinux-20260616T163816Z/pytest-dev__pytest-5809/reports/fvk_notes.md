# FVK Notes

## Decisions

1. V1 stands unchanged. This follows from F-001 and PO-001: the issue requires
   `lexer=text`, and V1 assigns the literal `"text"` in `create_new_paste`.

2. I kept the Python 2 path on the same `text` lexer rather than restoring
   `lexer=python`. PO-001 is content- and runtime-independent, and F-001 identifies
   Python source classification as the defect for arbitrary pytest output.

3. I did not edit public tests. F-002 and PO-005 mark the old lexer assertion as
   SUSPECT, but the benchmark explicitly forbids modifying tests.

4. I did not change pastebin callsites. F-003 and PO-004 show both supported modes
   already flow through `create_new_paste`, so the helper-level V1 change covers
   them without additional code.

5. I did not add retry logic, HTTP fallback behavior, or response parsing changes.
   F-004 records those as outside the proof boundary: the public issue localizes the
   failure to the lexer field and identifies `text` as the successful alternative.

6. I did not run tests, Python, or K tooling. The proof artifacts include the
   commands that should be run later, and every proof result is labeled
   constructed, not machine-checked, as required by the FVK honesty gate.
