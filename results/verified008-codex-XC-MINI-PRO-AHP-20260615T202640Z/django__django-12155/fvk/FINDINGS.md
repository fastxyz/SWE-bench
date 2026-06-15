# FVK Findings

Status: audit findings from `/formalize` and `/verify`, constructed but not
machine-checked.

## F-001: Legacy Implementation Retained Indentation for First-Line Summaries

Classification: code bug in pre-V1 implementation, resolved by V1.

Input:

```python
def test():
    """test tests something.
    More detail.
    """
```

Observed before V1:

The first line had indentation `0`, so the old common-margin calculation over
all non-empty lines produced margin `0`. The continuation/body line kept its
function-body indentation.

Expected:

The first line must be left-trimmed, and later lines must be dedented by the
common margin computed from lines after the first line.

Evidence: E1-E4. Proof obligations: PO-2 and PO-4.

V1 status:

Resolved. V1 delegates non-empty docstrings to `inspect.cleandoc()`, the PEP
257 cleanup function identified by the public hint.

## F-002: Naive Skip-First-Line Patch Can Raise on Empty Tail

Classification: corner case in an alternative implementation, avoided by V1.

Input:

```python
def test():
    """test tests something."""
```

Observed for the rejected alternative:

`min(... for line in lines[1:] if line.lstrip())` can evaluate an empty
sequence and raise `ValueError`.

Expected:

Single-line docstrings and docstrings with no non-empty following lines should
clean successfully.

Evidence: E5. Proof obligation: PO-3.

V1 status:

Resolved. V1 has no local `min()` over `lines[1:]`; the empty input family is
handled by the guard and by `inspect.cleandoc()`.

## F-003: Existing Leading-Empty-Line Behavior Must Be Preserved

Classification: compatibility condition, satisfied by V1.

Input:

The public `TestUtils.__doc__` fixture in `repo/tests/admin_docs/test_utils.py`
starts with an empty first physical line and contains indented reST body text.

Observed risk:

A targeted first-line-summary workaround could accidentally change the existing
admindocs cleanup behavior for Django-style docstrings.

Expected:

The cleaned text remains within the PEP 257 output expected by the public test.

Evidence: E7-E8. Proof obligation: PO-5.

V1 status:

Satisfied. V1 uses the general PEP 257 cleanup function instead of a bespoke
special case.

## F-004: Public API and Callsite Compatibility

Classification: compatibility condition, satisfied by V1.

Input:

Admindocs callsites pass one `__doc__` value or method docstring into
`parse_docstring()` or `trim_docstring()` and consume a string.

Observed risk:

Replacing local cleanup with a standard-library function could expose `None` to
`cleandoc()` or alter the call protocol.

Expected:

`None` and blank values return `""`; non-empty values return a string; callsites
do not change.

Evidence: E10. Proof obligations: PO-1 and PO-6.

V1 status:

Satisfied. The existing guard remains before `cleandoc()` is called.

## F-005: Trusted-Base Boundary for `inspect.cleandoc()`

Classification: proof boundary, not a code bug.

Input:

Any non-empty docstring handled by V1.

Observed in this FVK proof:

The mini-K model treats `cleanDoc(S)` as the PEP 257 cleanup operation because
the public hint and the existing function comment identify it that way.

Expected:

A machine-checked proof of the full stack would either inline the standard
library implementation or use a verified standard-library specification.

Evidence: E6-E7. Proof obligations: PO-2, PO-3, PO-5.

V1 status:

Acceptable for this audit. It justifies keeping V1 unchanged, with the proof
labeled constructed, not machine-checked.

## Proof-Derived Findings From `/verify`

No proof-derived production-code defect was found. The adequacy gate passes:
the formal English claims match the intent specification, no claim rests only
on candidate behavior, and the compatibility audit has no unhandled public
callsite.

Residual verification risk:

The K proof was not run, and `inspect.cleandoc()` is modeled by its public PEP
257 contract rather than by an inlined standard-library implementation.
