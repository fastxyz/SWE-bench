# FVK Notes

## Summary

The FVK audit did not confirm V1 unchanged. It found that V1 fixed the reported
literal-punctuation case but still violated the same source-span obligation when
the trailing punctuation itself was represented by an HTML entity. I revised the
source to V2 and documented the proof obligations and constructed proof under
`fvk/`.

## Code decisions

### D-001: Replace V1 count-only slicing with source-span trimming

- Files changed: `repo/django/utils/html.py`.
- Finding: `fvk/FINDINGS.md` F-002.
- Proof obligations: `fvk/PROOF_OBLIGATIONS.md` O-004 and O-005.
- Decision: V1 removed the same number of source characters as unescaped
  punctuation characters. That was sufficient for `&lt!`, but it broke
  entity-encoded punctuation such as `&#33;` by leaving `&#33` in `middle` and
  moving only `;` to `trail`.
- V2 change: inside `trim_punctuation()`, the new loop first checks whether the
  source suffix beginning at the last `&` unescapes entirely to trailing
  punctuation. If it does, V2 moves that whole suffix to `trail`.

### D-002: Preserve non-punctuation entities inside the link

- Files changed: `repo/django/utils/html.py`.
- Findings: F-001 and F-003.
- Proof obligations: O-001, O-003, O-004, and O-006.
- Decision: The reported `&lt!` case requires keeping `&lt` in the link text and
  moving only `!`. Valid non-punctuation entities such as `&lt;` and `&amp;`
  have the same preservation requirement.
- V2 change: the entity path is used only when the whole suffix unescapes to
  punctuation. Mixed suffixes such as `&lt!`, `&lt;!`, and `&amp;!` fall through
  to the literal punctuation path, so only the literal punctuation moves.

### D-003: Keep existing URL recognition, href quoting, autoescape, and template APIs unchanged

- Files changed: none beyond the helper in `repo/django/utils/html.py`.
- Finding: F-003.
- Proof obligation: O-006.
- Decision: The issue and public tests show that URL recognition and
  `smart_urlquote(html.unescape(middle))` already produce the intended href once
  `middle` and `trail` are split correctly. The template filter delegates to the
  utility and needed no signature or call change.

### D-004: Add FVK artifacts and formal core without executing tooling

- Files changed: `fvk/SPEC.md`, `fvk/FINDINGS.md`,
  `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`,
  `fvk/ITERATION_GUIDANCE.md`, `fvk/mini-urlize.k`, and
  `fvk/urlize-trim-spec.k`.
- Finding: F-004.
- Proof obligation: O-009.
- Decision: The task forbids tests, Python execution, and K tooling. The
  artifacts therefore record constructed, not machine-checked, proof reasoning
  and commands to run later rather than executing them.

## Assumptions

- `html.unescape()` is the source of truth for deciding the visible punctuation
  suffix because the existing code already uses it for entity-aware trimming and
  href construction.
- A trailing source suffix that unescapes entirely to characters in
  `TRAILING_PUNCTUATION_CHARS` represents trailing punctuation and should move
  as a whole source span.
- A suffix that unescapes to mixed punctuation and non-punctuation should not be
  treated as one punctuation entity; V2 conservatively trims literal trailing
  punctuation in that case.

## Not performed

No tests, Python snippets, or K commands were run. No test files were modified.
