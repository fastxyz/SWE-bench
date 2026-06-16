# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent, source inspection, and constructed proof obligations only.

## F-001: Legacy early return failed already-NFKD accented text

Classification: code bug fixed by V1.

Evidence: E1, E2, E3.

Concrete input:

- `s = chr(110) + chr(771)` (`LATIN SMALL LETTER N` followed by `COMBINING TILDE`).

Observed before V1:

- `unicodedata.normalize('NFKD', s) == s`, so the old `normalized == s` branch returned `s` unchanged.

Expected:

- `chr(110)`, because the combining tilde must be filtered after NFKD normalization.

Proof obligations:

- O-2 requires unconditional NFKD normalization.
- O-3 requires unconditional combining-character filtering after normalization.
- O-4 specifically covers the already-NFKD case.

Current status:

- Discharged by the current source: `strip_accents_unicode` now returns `''.join([c for c in normalized if not unicodedata.combining(c)])` without an early return.

## F-002: V1 satisfies the public value contract on the audited in-domain behavior

Classification: confirmation, not a new code bug.

Evidence: E1 through E7.

Reason:

- The source computes `normalized = unicodedata.normalize('NFKD', s)` and then filters every code point in `normalized` by `not unicodedata.combining(c)`.
- This is exactly the postcondition in O-3 and covers both precomposed and already-decomposed accented forms through O-6.

Current status:

- No further production code change is justified by the FVK audit.

## F-003: The removed optimization is not a preserved public behavior

Classification: rejected alternative.

Evidence: E3, E4, E5, E6.

Concrete tradeoff:

- Preserving `if normalized == s: return s` would keep a value/object fast path for already-normalized input, but it also preserves the reported bug for normalized strings that contain combining marks.

Expected:

- Value semantics must prefer O-3/O-4 over this optimization.

Current status:

- Do not reintroduce an early return based only on `normalized == s`. A future optimization would need a stronger guard that proves no combining marks remain.

## F-004: Domain is documented strings only

Classification: explicit precondition, not a code bug for this issue.

Evidence: E5 and the parameter documentation `s : string`.

Concrete input outside the domain:

- Non-string inputs such as `None`.

Expected:

- No new behavior is specified by this issue. The helper may continue to rely on `unicodedata.normalize` to enforce string-like input.

Proof obligations:

- O-1 limits the formal claim to Python `str`.

Current status:

- No production code change.

## F-005: Test changes are intentionally omitted

Classification: test gap caused by benchmark constraints.

Evidence: E2 and the user instruction not to modify test files.

Recommended test outside this task:

- Assert `strip_accents_unicode(chr(110) + chr(771)) == chr(110)`.
- Optionally assert a vectorizer configured with `strip_accents='unicode'` handles the same decomposed input during preprocessing.

Proof obligations:

- O-8 records that tests are not modified in this repair.

Current status:

- No test files changed.

## F-006: FVK completeness requires formal-core and adequacy artifacts

Classification: methodology requirement, not a code bug.

Evidence: FVK `AGENTS.md`, `formalize.md`, and `verify.md` require `.k` artifacts, an intent spec, an evidence ledger, a formal-English paraphrase, a spec audit, and a compatibility audit.

Expected:

- The audit should not stop at prose-only `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.

Proof obligations:

- O-9 records the constructed-not-machine-checked honesty gate.
- O-10 records the artifact-completeness obligation.

Current status:

- Discharged by adding the requested artifacts plus `mini-python-unicode.k`, `strip-accents-unicode-spec.k`, and the adequacy/compatibility markdown files.
