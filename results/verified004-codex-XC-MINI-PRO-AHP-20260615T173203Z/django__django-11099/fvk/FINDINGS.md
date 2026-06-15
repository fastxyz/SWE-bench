# FVK Findings

Status: V1 audited. Findings are derived from public intent, source inspection, and constructed proof obligations. No code or tests were executed.

## F-001: Resolved legacy bug, trailing LF accepted by `$`

Classification: code bug in pre-V1 implementation, resolved by V1.

Input: `ASCIIUsernameValidator()("joe\n")` and `UnicodeUsernameValidator()("joe\n")`.

Observed before V1 by Python regex semantics: `r'^[\w.@+-]+$'` can match `joe` before the final `\n`, so `RegexValidator.search(str(value))` sees a match and accepts the value.

Expected from E-001 and E-002: invalid username; newline is not in the allowed character set.

V1 status: `r'\A[\w.@+-]+\Z'` rejects the same input because `\Z` requires the true end of string and `\n` is not consumed by the allowed character class. Covered by PO-002, PO-003, `ASCII_REJECT_TRAILING_LF`, and `UNICODE_REJECT_TRAILING_LF`.

## F-002: No remaining intent divergence in the audited validator language

Classification: no additional code bug found.

Input classes checked by the spec:

- non-empty all-allowed ASCII username -> accepted by ASCII validator;
- non-empty all-allowed Unicode username -> accepted by Unicode validator;
- empty string -> rejected by both validators because the regex uses `+`;
- any string containing LF, CR, space, apostrophe, zero-width space, non-breaking space, en dash, or another disallowed character category -> rejected by the relevant validator;
- otherwise valid username plus final LF -> rejected by both validators.

Expected: exactly the documented character-family behavior and the issue's newline rejection.

V1 status: the regex change satisfies these classes while preserving flags. Covered by PO-001 through PO-005.

## F-003: No public compatibility problem found

Classification: compatibility audit finding.

Public surfaces checked: validator class names, inheritance from `RegexValidator`, messages, flags, default use in `AbstractUser.username_validator`, migration references, docs examples, and public tests that instantiate the validators.

Expected: narrow the accepted language to match public intent without changing the public API.

V1 status: compatible. Only the class-level regex literals changed. Covered by PO-006 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

## Proof-derived findings from `/verify`

PF-001: The constructed proof is not machine-checked.

Classification: proof status, not a code bug.

Evidence: the benchmark forbids running K tooling; FVK MVP requires results be labeled "constructed, not machine-checked" until `kprove` returns `#Top`.

Impact: no tests should be removed based on this run. The proof artifacts include exact commands for later machine checking. Covered by PO-007.

PF-002: No proof obstacle forced a source revision beyond V1.

Classification: confirmation of V1 against the stated proof obligations.

Evidence: the adequacy audit passes every claim against the intent spec; compatibility audit finds no unhandled public callsite or override; the proof obligations close by the direct semantics of absolute anchors and allowed character recursion.

Impact: V2 should keep V1 source unchanged. Covered by PO-001 through PO-006.
