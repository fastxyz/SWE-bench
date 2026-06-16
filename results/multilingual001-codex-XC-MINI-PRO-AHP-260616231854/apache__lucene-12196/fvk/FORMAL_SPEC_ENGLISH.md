# Formal Spec In English

Status: paraphrase of the claims and proof obligations.

Claim C1: If `applySlop` receives a boosted phrase query, it must return a boosted phrase query with
the same phrase payload, the requested slop, and the same boost.

Claim C2: If `applySlop` receives a boosted multi-phrase query, it must return a boosted multi-phrase
query with the same payload, the requested slop, and the same boost.

Claim C3: If `applySlop` receives a boosted non-phrase query, it must preserve the wrapped query and
the boost.

Claim C4: If `applySlop` receives a null query, it must return null.

Claim C5: In the multi-field quoted parser path, applying a field boost before `applySlop` must still
produce a result where the inner phrase-like query has the requested slop and the outer wrapper has
the configured boost.

Frame condition: phrase payload, boost values, public parser signatures, and test files are
preserved.

Honesty condition: the proof is constructed but not machine-checked in this environment.
