# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F1: V1 fixes the reported regex-literal bug

Evidence: E1, E2, E3; proof obligations O1, O2, O3, O4, O5.

Concrete case:

```text
prefix = "a+b"
pk_name = "id"
POST items = [
  ("a+b-0-id", "selected"),
  ("ab-0-id", "wrong")
]
```

Legacy behavior from the unescaped pattern `a+b-\d+-id$` treats `+` as a regex
quantifier, so it does not denote the literal prefix `a+b` and can denote other
keys. Expected behavior is to return `["selected"]`. V1 compiles
`re.escape("a+b")` into the regex fragment for literal `a+b`, so only the
literal formset key is selected.

Classification: code bug addressed by V1. No additional source change required.

## F2: No sibling regex-format occurrence found in allowed source

Evidence: E6; proof obligation O8.

Search over `repo/django/**/*.py` for `re.compile/search/match(...format(...))`
found only the patched admin helper. This does not prove no possible future
regex interpolation bug exists, but it discharges the issue's request to check
for the same usage pattern in the allowed source tree.

Classification: audit coverage finding. No additional source change required.

## F3: Public compatibility is preserved

Evidence: E5; proof obligation O7.

The patch changes no public or private method signature and introduces no new
virtual dispatch arguments. `_get_edited_object_pks()` remains a private helper
with one internal caller. Return type and order remain a list of POST values in
request iteration order.

Classification: compatibility check passed.

## F4: Proof is constructed, not machine-checked

Evidence: FVK verify honesty gate; proof obligations O1-O8.

The K artifacts and proof sketch were written but no `kompile`, `kast`,
`kprove`, tests, Python, or Django code were executed, per the task
instructions. The proof therefore supports code review and iteration decisions
but is not a machine-checked theorem.

Classification: proof status caveat, not a code bug.

