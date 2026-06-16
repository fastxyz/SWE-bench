# Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-001: Original boolean conversion bug

- Classification: code bug fixed by V1/V2.
- Input: `:private-members: _one` with all member generation active.
- Pre-fix observed behavior: the option was converted by `bool_option`, so the `_one` argument was discarded and the filter treated the option as truthy for every private member.
- Expected behavior: `_one` is selected and other private members are not included solely because `private-members` is present.
- Evidence: `PROOF_OBLIGATIONS.md` PO-1, PO-3, PO-7.
- Resolution: `private-members` now uses `members_option`; private filtering checks `ALL` versus named membership.

## F-002: V1 documentation mismatch

- Classification: documentation/public contract gap fixed in V2.
- Input: a user reading `doc/usage/extensions/autodoc.rst` after V1.
- V1 observed behavior: docs still called `private-members` a flag option and did not mention explicit list arguments.
- Expected behavior: docs should say `private-members` can take an explicit list of private member names.
- Evidence: `PROOF_OBLIGATIONS.md` PO-12; `SPEC.md` I10.
- Resolution: `repo/doc/usage/extensions/autodoc.rst` now says the option can take an explicit list and shows a `private-members` default-options value.

## F-003: Machine check unavailable by instruction

- Classification: proof status limitation, not a code bug.
- Input: FVK commands `kompile`, `kast`, and `kprove`.
- Observed: commands were not run because the task forbids Python, tests, and K tooling execution.
- Expected for full FVK confidence: run the emitted commands and require `kprove` to return `#Top`.
- Evidence: `PROOF.md` Reproduce The Machine Check.
- Resolution: artifacts are labeled "constructed, not machine-checked"; no test removal is recommended until machine-checking is performed.

## Proof-Derived Findings From `/verify`

No blocking proof-derived code bug remains after V2. The constructed proof obligations cover the issue-relevant behavior space: option parsing, merge, all-vs-selected private filtering, exclusion/mock precedence, explicit-member preservation, and docs. The remaining risk is the unexecuted machine check and the trusted adequacy of the mini-autodoc semantics.
