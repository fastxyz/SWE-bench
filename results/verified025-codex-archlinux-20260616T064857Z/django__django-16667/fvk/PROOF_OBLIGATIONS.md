# Proof Obligations

Status: constructed, not machine-checked.

## PO-001 - Overflow complete triples return pseudo-ISO

- Evidence: E-001, E-002, E-003.
- Finding: F-001.
- Statement: for any request-string complete triple `(y, m, d)`, if `datetime.date(int(y), int(m), int(d))` raises `OverflowError`, `value_from_datadict()` returns `"%s-%s-%s" % (y or 0, m or 0, d or 0)` and no `OverflowError` escapes.
- Discharge: V1 changes `except ValueError:` to `except (ValueError, OverflowError):` around the existing date construction and pseudo-ISO return.

## PO-002 - Existing ValueError complete-triple behavior is preserved

- Evidence: E-004, E-005.
- Finding: F-002.
- Statement: complete triples that raise `ValueError` still return the existing pseudo-ISO string with zero substitution for blank components.
- Discharge: the handler body and all-present condition are unchanged; only `OverflowError` is added to the caught exception tuple.

## PO-003 - Valid complete triples remain formatted dates

- Evidence: E-005.
- Finding: F-003.
- Statement: complete triples that convert to a valid Python date still return `date_value.strftime(input_format)` using the sanitized first date input format.
- Discharge: the `try` body, `input_format` computation, and successful return path are unchanged.

## PO-004 - All-empty components still return None

- Evidence: E-005.
- Finding: F-003.
- Statement: when `y == m == d == ""`, the method returns `None` before attempting integer conversion or date construction.
- Discharge: the guard and return expression are unchanged and still precede the complete-triple branch.

## PO-005 - Missing-component fallback remains data.get(name)

- Evidence: E-005.
- Finding: F-003.
- Statement: when at least one component is missing and the all-empty branch does not apply, the method returns `data.get(name)`.
- Discharge: the final fallback return is unchanged.

## PO-006 - Public API and caller compatibility are preserved

- Evidence: E-006.
- Findings: F-002, F-003.
- Statement: the method signature, public class, dispatch protocol, and return categories remain compatible with existing callers.
- Discharge: V1 edits only the exception tuple in a private local `try` block. No signature, attribute, callsite, or return-shape change is introduced.

## PO-007 - Verification honesty gate

- Evidence: FVK verify documentation.
- Finding: F-004.
- Statement: the proof is constructed and commands are emitted, but no claim is represented as machine-checked in this benchmark.
- Discharge: `fvk/PROOF.md` includes exact `kompile`, `kast`, and `kprove` commands and labels the result as constructed, not machine-checked.

