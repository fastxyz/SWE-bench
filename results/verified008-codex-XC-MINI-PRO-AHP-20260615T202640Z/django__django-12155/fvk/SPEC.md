# FVK Specification

Status: constructed, not machine-checked.

## Target

Target function:

`repo/django/contrib/admindocs/utils.py::trim_docstring(docstring)`

Relevant consumer:

`repo/django/contrib/admindocs/utils.py::parse_docstring()` calls
`trim_docstring()` before splitting title/body/metadata. `parse_rst()` later
wraps the resulting text in a `default-role` directive block.

## Public Intent Ledger

The ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E4: the issue requires first-line-summary docstrings to be supported, and
  identifies inclusion of the first line in the margin calculation as the
  defect.
- E5-E6: the public hints reject a naive skip-first-line `min()` because it can
  raise `ValueError`, and identify `inspect.cleandoc()` as the PEP 257
  implementation.
- E7-E8: the helper already claims PEP 257-style cleanup and public tests cover
  existing leading-empty-line behavior.
- E9-E10: admindocs consumers require a string result that is safe to insert
  into the `parse_rst()` directive wrapper.

## Domain

Inputs in scope:

- `None`;
- strings that are empty or all whitespace;
- non-empty Python docstring text, including both leading-empty-line docstrings
  and docstrings whose summary begins on the first line.

Inputs outside this audit:

- truthy non-string objects without string methods. Existing callsites pass
  docstrings or `None`; no public evidence requires widening this helper.

## Contract

For all in-scope `docstring` values:

1. If `docstring` is `None` or `docstring.strip()` is empty, return `""`.
2. Otherwise return `inspect.cleandoc(docstring)`.
3. The returned value satisfies PEP 257 cleanup:
   - the first physical line is left-trimmed;
   - the common indentation margin for non-empty following lines is computed
     from `lines[1:]`, not from `lines[0]`;
   - if no non-empty following line exists, the margin defaults to `0`;
   - surrounding blank lines in the cleaned docstring are removed.
4. For a first-line-summary docstring with indented continuation/body lines,
   continuation/body lines are dedented by their common margin before being
   passed to `parse_rst()`.
5. For Django-style docstrings with an empty first physical line, public
   `test_trim_docstring()` behavior remains within the PEP 257 contract.
6. The public helper signature and return type remain unchanged.

## Formal Core

The K artifacts are:

- `fvk/mini-python-string.k`: a small symbolic fragment for this helper. It
  models `None`, strings, truth/blank checks, `strip`, `cleandoc`, and function
  return.
- `fvk/trim-docstring-spec.k`: K claims for the empty guard, the non-empty
  `cleandoc` path, PEP 257 margin behavior, directive-safety property, and API
  frame condition.

The model treats `cleandoc` as a primitive standard-library operation with the
PEP 257 property from E6 and E7. That is a trusted-base boundary of this FVK
run, not a production-code concern.

## Proof Scope

The proof is partial correctness: if the helper returns, the return value meets
the contract. There are no loops or recursive functions in the audited helper,
so there are no loop circularities or termination variants to discharge.

The exact machine-check commands are recorded in `fvk/PROOF.md`. They were not
run, per the task restriction.
