# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

Keep the V1 production code unchanged.

Reason:

- F-01 shows the reported first-signature-only bug is fixed.
- F-02 shows V1 does not over-scan docstring bodies.
- F-03 shows single-signature compatibility is preserved.
- F-04 shows the strip-only compatibility risk is handled by not caching plural
  signatures in `_find_signature()`.
- PO-1 through PO-9 are satisfied by the current source structure.

## Suggested public tests

Do not modify tests in this benchmark.  For a normal development branch, add or
confirm coverage for:

1. A method docstring with two or more consecutive leading overload signatures
   produces two or more directive signatures.
2. The extracted overload lines are removed from the docstring body.
3. A signature-looking line after prose remains in the body.
4. A single leading signature still behaves as before.
5. `DocstringStripSignatureMixin` strips signatures without emitting one.

## Documentation follow-up

F-05 notes that user docs still describe "the first line".  A normal project PR
could update that wording to say "the first line, or consecutive leading lines
for overloaded functions/methods".  This benchmark phase did not require that
documentation change for the source-code fix.

## Machine-check follow-up

Run the commands from `PROOF.md` in an environment with K installed.  Keep all
tests until `kprove` returns `#Top`.

## Open assumptions

- Docstring lists and line lists are finite.
- `py_ext_sig_re` remains the definition of a recognizable docstring signature.
- Event callbacks process each formatted overload signature independently via
  the existing `Documenter.format_signature()` path.
