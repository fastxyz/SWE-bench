# Spec Audit

Status: constructed, not machine-checked.

## ORDERED-BY-STYLE-MODULE

Formal English: sort generated import lines by `(style_rank, module_token)`,
where plain imports have rank `0` and from-imports have rank `1`.

Intent match: pass.

Reason: I-2 requires plain imports before from-imports. Keeping module-token sort
as the secondary component is the smallest change that preserves the existing
writer behavior not contradicted by public intent.

## ISSUE-WITNESS

Formal English: the issue's datetime/django/time example sorts to
datetime/time/django.

Intent match: pass.

Reason: I-3 states exactly this desired output.

## Frame Condition

Formal English: the sort operation only reorders the import lines.

Intent match: pass.

Reason: I-4 supports a small local tweak and rejects full formatter behavior.

## Side Condition

Formal English: inputs are generated import lines.

Intent match: pass.

Reason: I-5 and the preexisting `split()[1]` implementation establish that this
sort point receives generated import strings, not arbitrary user strings.

## Non-Claims

Full isort grouping: pass as non-claim, because I-4 rejects broad formatter
logic.

Equal-key full-line tie ordering: pass as non-claim, because no public evidence
requires it.
