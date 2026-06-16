# FVK Specification

Status: constructed, not machine-checked. The exact commands that would machine-check the
formal core are listed in `PROOF.md`; they were not executed in this benchmark session.

## Target

`repo/lucene/analysis/opennlp/src/java/org/apache/lucene/analysis/opennlp/OpenNLPSentenceBreakIterator.java`

Audited units:

- `preceding(int pos)`, specifically the branch that initializes `currentSentence` and
  calls `moveToSentenceAt(pos, 0, sentenceStarts.length - 1)`.
- `moveToSentenceAt(int pos, int minSentence, int maxSentence)`, specifically the
  recursive binary-search invariant needed to make `sentenceStarts[currentSentence + 1]`
  safe.

## Public Intent Ledger

The public intent ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`.

- E-001: the issue-reported exception must be removed for in-domain `preceding` calls.
- E-002: `preceding` should use `(sentenceStarts.length - 1) / 2` as the initial midpoint.
- E-003: the length-two sentence-start array is a required boundary case.
- E-004: `following` is supporting implementation evidence for the same lower-middle
  search seed.
- E-005: existing public API and return behavior are preserved; no signature or return
  contract is intentionally changed.

## Model

The K model is intentionally minimal and property-complete for the reported defect. It
does not model OpenNLP sentence detection, `CharacterIterator`, or concrete returned
offsets. It models the axis that distinguishes the failing and passing implementations:
whether a recursive search frame can read `sentenceStarts[currentSentence + 1]` when that
index is outside the array.

Files:

- `mini-java-break-iterator.k`: abstract mini-Java search semantics for V1 and the
  pre-fix midpoint.
- `opennlp-sentence-break-iterator-spec.k`: claims for the pre-fix counterexample, V1
  safety, and the helper invariant.

## Preconditions

P-001: `sentenceStarts.length = N >= 0`.

P-002: The modeled `preceding` search branch is reached only after the Java guards have
accepted `pos` as in-bounds and not before the first sentence start. This mirrors the
source branch that reaches `moveToSentenceAt`.

P-003: For the helper invariant, a search frame has
`0 <= minSentence <= currentSentence <= maxSentence < N`, and if
`minSentence < maxSentence` then `currentSentence < maxSentence`.

P-004: The proof abstracts over the actual `pos` branch choice. The helper is verified
for all left, right, and already-at-target branches that respect P-003, which is stronger
than verifying one concrete `pos` value.

## Postconditions

Q-001: V1 `preceding` does not reach the modeled `arrayIndexOutOfBounds` outcome for any
`N >= 1` on the search branch.

Q-002: In the explicit boundary case `N = 2`, V1 initializes `currentSentence` to `0`,
so the first non-base helper frame can safely inspect `currentSentence + 1 == 1`.

Q-003: The pre-fix expression `N / 2` has a concrete modeled counterexample at `N = 2`:
it initializes `currentSentence` to `1`, and the non-base helper frame can try to inspect
`currentSentence + 1 == 2`, outside valid indices `[0, 1]`.

Q-004: V1 preserves public compatibility: no method signature, visibility, field, class
hierarchy, or caller protocol changed.

