# Formal Spec In English

Status: constructed, not machine-checked.

The supporting formal claims are written in `fvk/sympy-string-spec.k`.

## C1: String construction argument shape

For any codegen String-like class `C` and Python string `s`,
constructing `C(s)` yields an object whose public text is `s` and whose
positional Basic arguments are exactly one SymPy `Str(s)` wrapper.

## C2: Positional reconstruction

For any object produced by C1, calling its class with its positional arguments
normalizes `Str(s)` back to the public text `s`, producing an object equal to
the original under `Token.__eq__`.

## C3: Keyword reconstruction frame

For the same object, `kwargs()` still returns `{"text": s}`, so
`expr.func(**expr.kwargs()) == expr` remains true.

## C4: Invalid text preservation

Public construction with a non-string, non-`Str` text argument remains invalid
and raises the same TypeError path as before.

## C5: Codegen atom traversal frame

In default atom traversal over codegen tokens, a `String` object is treated as a
leaf atom and the internal `Str(s)` reconstruction wrapper is skipped.

## C6: Public API compatibility

No public constructor signature, public attribute name, return shape for
`kwargs()`, string printer behavior, or codegen constructor helper protocol is
changed.
