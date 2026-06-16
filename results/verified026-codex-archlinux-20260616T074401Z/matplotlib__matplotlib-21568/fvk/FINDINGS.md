# FVK Findings

Status: constructed, not machine-checked. These findings come from public
intent, source inspection, and constructed proof obligations only.

## F1: Pre-V1 TeX math chunks lost date/time separation

Classification: code bug fixed by V1.

Input: `text = "2020-01-01 00:00"`.

Observed before V1, by symbolic inspection of the old helper:
`$\mathdefault{2020{-}01{-}01 00:00}$`. The space remains a regular character
inside TeX math mode, where TeX ignores it. The colons also remain math
punctuation.

Expected from E1-E4: the separator family is protected, producing the relevant
numeric math chunk as `$\mathdefault{2020{-}01{-}01\;00{:}00}$`.

V1 action: `repo/lib/matplotlib/dates.py` now rewrites `:` to `{:}` and spaces
to `\;` before adding the outer `\mathdefault` wrapper.

Related proof obligations: PO1, PO2, PO3.

## F2: Existing public test expectations are stale for this bug

Classification: SUSPECT legacy-test evidence, not a code bug in V1.

Input examples from public tests:

- `Jan$\mathdefault{ %02d 1990}$`
- `$\mathdefault{%02d:00:00}$`
- `$\mathdefault{04:00}$`

Observed expectation: raw spaces and raw colons are present inside
`\mathdefault` math chunks.

Expected from E1-E4: spaces and colons in date/time separators are protected as
`\;` and `{:}`. These public tests document pre-fix behavior for the string
contract but conflict with the bug report on the separator issue, so they cannot
veto V1.

Related proof obligations: PO2, PO3, PO7.

## F3: The exact one-block monkey-patch form is not required

Classification: resolved ambiguity; V1 source stands.

Input: `text = "Jan-01"`.

Workaround output shape from the issue comment:
`$\mathdefault{Jan{-}01}$`.

V1 output shape by symbolic inspection:
`Jan$\mathdefault{{-}01}$`.

Both forms protect the dash. The public issue requires corrected spacing in TeX
date labels, not a public API promise that all alphabetic text must be moved
inside one math block. Existing public tests provide non-conflicting evidence
that alphabetic date fragments were intentionally split out of `\mathdefault`.
Keeping that behavior is the narrower compatible fix.

Related proof obligations: PO4, PO7.

## F4: Formatter coverage is complete for built-in TeX date formatting

Classification: confirmation; no source change required.

Input class: built-in `DateFormatter`, `AutoDateFormatter` string formats, and
`ConciseDateFormatter` label/offset formats with `usetex=True`.

Observed in source: these paths call `_wrap_in_tex` for formatted strings.

Expected from E8: the helper-level separator fix reaches the public built-in
date formatter behavior described by the issue. User-supplied callable
`AutoDateFormatter.scaled` entries remain outside this guarantee, consistent
with the docstring.

Related proof obligations: PO5, PO6.

## F5: Residual proof and rendering risk

Classification: proof capability and integration boundary.

The constructed proof models the Python regex and `str.replace` pipeline as
deterministic string functions and proves the wrapper pipeline against that
model. It does not machine-check real Python semantics or TeX rendering metrics,
and no K commands were run. This does not block the V1 source conclusion because
the separator transformation is directly derived from public intent and source
inspection, but test deletion must remain conditioned on a real machine check
and normal project test execution outside this constrained session.

Related proof obligations: PO8.
