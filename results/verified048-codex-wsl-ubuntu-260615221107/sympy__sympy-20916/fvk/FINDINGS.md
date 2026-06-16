# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: V1 fixes the reported Unicode Greek trailing-digit bug

Input: first name part `ω0`.

Observed before V1 by source-level reasoning: the old matcher
`^([a-zA-Z]+)([0-9]+)$` could not match `ω`, so `split_super_sub("ω0")` left
the name unsplit. `pretty_symbol` therefore had no subscript component to map
to `₀`.

Expected from intent I1/I2/I3: `ω0` must split as base `ω`, subscript `0`, so
unicode pretty output can render `ω₀`.

V1 result by regex semantics: `[^\W\d_]+` admits `ω` as a Unicode word
character that is not a digit and not underscore; `[0-9]+` admits `0`.
Therefore `_name_with_digits_p` captures `("ω", "0")`, and
`split_super_sub` returns `("ω", [], ["0"])`.

Classification: resolved code bug. Supports keeping V1 unchanged.

Proof obligations: PO-1, PO-2, PO-5.

## F-002: V1 avoids a naive `\w+` multi-digit regression

Input: first name part `x10`.

Expected from public behavior I4: the suffix `10` is one subscript run, so the
split is `("x", [], ["10"])`.

Risk found during audit: a direct greedy `^(\w+)([0-9]+)$` replacement can
capture base `x1` and suffix `0`, because `\w` includes digits.

V1 result by regex semantics: `[^\W\d_]+` excludes digits from the base, so the
base capture is `x` and the suffix capture is `10`.

Classification: regression avoided. Supports rejecting the direct greedy
`\w+` alternative.

Proof obligations: PO-1, PO-3.

## F-003: Names with internal digits or leading underscores remain out of scope

Inputs: first name parts such as `x1y2` or `_x0`.

Intent status: the issue requires Greek letters to behave like Latin letters in
the existing trailing-digit convention. Public evidence does not require
broadening the implicit-subscript rule to names whose base part already
contains digits or underscores.

V1 result by regex semantics: these names do not satisfy `BaseRun + DigitRun`
because `BaseRun` excludes digits and underscore. They are therefore not
implicitly split by the V1 matcher.

Classification: underspecified outside the audited domain; no source change is
justified.

Proof obligations: PO-4.

## F-004: Explicit `_`, `^`, and `__` parsing is preserved

Input family: names such as `x_1`, `x_1^aa`, and `beta_13_2`.

Expected from I5: explicit separator parsing remains as before.

V1 result by source inspection: the scan that separates explicit subscript and
superscript parts is unchanged. The regex applies only after that scan and only
to the first name part.

Classification: compatibility preserved.

Proof obligations: PO-6.

## F-005: Formal proof is constructed, not machine-checked

Input: the FVK artifacts themselves.

Expected from the FVK honesty gate: do not claim machine verification without
running `kompile`/`kprove`.

Observed: no K commands were run because this task forbids K tooling.

Classification: proof-status caveat, not a source-code bug. Keep any test
removal recommendation conditional on a future machine check.

Proof obligations: PO-7.

## Conclusion

No V1 source defect was found. V1 stands unchanged.
