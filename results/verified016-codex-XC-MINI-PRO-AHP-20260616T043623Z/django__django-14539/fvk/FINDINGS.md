# FINDINGS: django__django-14539

Status: constructed, not machine-checked. Findings are from public intent,
source inspection, and proof-obligation construction only.

## F-001: Original source split duplicated part of an escaped sequence

- Classification: code bug, resolved by the source change.
- Evidence: prompt I-001 and I-002.
- Input: `urlize('Search for google.com/?q=1&lt! and see.')`
- Pre-fix observed behavior from the issue:
  `google.com/?q=1&lt</a>lt!`
- Expected behavior from the issue:
  `google.com/?q=1&lt</a>!`
- Cause: the old code used `len(stripped)`, measured in unescaped characters, as
  an absolute source index into `middle`.
- Resolution: V2 tracks how many unescaped trailing punctuation characters must
  be moved and transfers the corresponding source suffix.
- Proof obligations: O-001, O-002, O-003, O-004.

## F-002: V1 fixed literal punctuation after an entity but still broke encoded punctuation

- Classification: code bug found by FVK audit, resolved by V2.
- Evidence: I-003 says trailing punctuation should be outside the link; I-004
  says entity source must not be broken.
- Input class: a recognized URL whose final visible character is trailing
  punctuation encoded as an HTML entity, for example
  `Search for google.com/&#33; and see.`
- V1 observed by static source reasoning:
  `middle == "google.com/&#33"` and `trail == ";"`.
- Expected by the source-span spec:
  `middle == "google.com/"` and `trail == "&#33;"`.
- Cause: V1 removed the same number of source characters as unescaped
  punctuation characters, which is incorrect when one visible punctuation
  character is represented by a multi-character entity source span.
- Resolution: V2 checks whether the trailing source suffix beginning at the last
  `&` decodes entirely to punctuation; if so, it moves that whole source span to
  `trail`.
- Proof obligations: O-004, O-005, O-006.

## F-003: Frame condition for non-punctuation entities

- Classification: regression risk, addressed by V2.
- Evidence: I-004 and I-005.
- Input class: escaped URL text followed by literal punctuation, for example
  `google.com/?q=1&lt!`, `google.com/?q=1&lt;!`, and `google.com/?x=&amp;!`.
- Expected: the entity-like or valid entity source that decodes to
  non-punctuation stays inside `middle`; only the literal `!` moves to `trail`.
- Resolution: V2 moves a whole entity only when its unescaped value consists
  entirely of trailing punctuation characters. `&lt!`, `&lt;!`, and `&amp;!`
  do not satisfy that test as whole suffixes, so the literal punctuation path is
  used.
- Proof obligations: O-004, O-006.

## F-004: No execution or machine proof was performed

- Classification: residual verification risk.
- Evidence: task forbids tests, Python execution, and K tooling.
- Impact: the proof is constructed, not machine-checked. Test removal is not
  recommended without later running the emitted K commands and the Django test
  suite in an environment where execution is allowed.
- Proof obligations: O-009.
