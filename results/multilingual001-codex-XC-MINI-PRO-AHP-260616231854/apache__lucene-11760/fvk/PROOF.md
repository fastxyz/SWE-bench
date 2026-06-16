# Constructed Proof

Status: constructed, not machine-checked. No proof tooling was run.

## Claim Set

The formal claims are in `fvk/no-intervals-spec.k`, over the mini semantics in
`fvk/mini-lucene-iterator.k`.

- C-001 proves PO-001: initial `docID()` returns `-1`.
- C-002 proves PO-002: `nextDoc()` returns `NO_MORE_DOCS` and stores exhaustion.
- C-003 proves PO-003: `advance(target)` returns `NO_MORE_DOCS` and stores exhaustion for
  `target >= 0`.
- C-004 proves PO-004: exhausted `docID()` returns `NO_MORE_DOCS`.
- C-005 proves PO-005: two unpositioned iterators with doc id `-1` satisfy same-doc setup.
- C-006 is a diagnostic contrast for F-002: the pre-fix `NO_MORE_DOCS` vs `-1` pair fails same-doc
  setup.

## Proof Sketch

There are no loops or recursion in the audited state machine, so no circularity is required.
The proof is finite symbolic execution over one integer state cell, `<doc>`.

Initial-state proof:

1. The constructed iterator state is modeled as `<doc> -1 </doc>`.
2. The `docID` rule rewrites the command to the current `<doc>` value without changing state.
3. Therefore `docID` reaches `-1`, discharging PO-001.

Exhaustion proof for `nextDoc()`:

1. Start from `<doc> -1 </doc>`.
2. The `nextDoc` rule rewrites the command to `NO_MORE_DOCS`.
3. The same rule updates `<doc>` to `NO_MORE_DOCS`.
4. A following `docID` command would therefore return `NO_MORE_DOCS`, discharging PO-002 and PO-004.

Exhaustion proof for `advance(target)`:

1. Start from `<doc> -1 </doc>` with `target >= 0`.
2. Because the iterator is empty, there is no matching document at or beyond any target.
3. The `advance` rule rewrites the command to `NO_MORE_DOCS` and updates `<doc>` to
   `NO_MORE_DOCS`.
4. A following `docID` command would therefore return `NO_MORE_DOCS`, discharging PO-003 and PO-004.

Conjunction setup proof:

1. `ConjunctionDISI.createConjunction` requires all child iterators to have equal current doc ids.
2. A normal unpositioned `DocIdSetIterator` has current doc id `-1`.
3. PO-001 proves a fresh V1 `NO_INTERVALS` iterator also has current doc id `-1`.
4. The `sameDoc(-1, -1)` claim rewrites to `true`, so V1 satisfies the setup condition.
5. The diagnostic `sameDoc(NO_MORE_DOCS, -1)` claim rewrites to `false`, matching the pre-fix
   failure mechanism.

## Machine-Check Commands

These commands are emitted for a future environment. They were not run here.

```sh
kompile fvk/mini-lucene-iterator.k --backend haskell
kast --backend haskell fvk/no-intervals-spec.k
kprove fvk/no-intervals-spec.k
```

Expected result after successful machine checking: `kprove` reduces all claims to `#Top`.

## Residual Risk

The proof is over a mini state-machine semantics, not a full Java semantics. Its adequacy rests on
the direct correspondence between the V1 Java code and the three modeled methods: `docID()`,
`nextDoc()`, and `advance(int)`.

Partial-vs-total correctness is not material here because there are no loops. The main honesty
limitation is that the K proof was constructed but not machine-checked.

## Test Guidance

Do not remove tests based on this unexecuted proof. Useful tests to keep or add in a normal
development environment would assert:

- a fresh `NO_INTERVALS` iterator reports `docID() == -1`;
- `nextDoc()` and `advance(0)` return `NO_MORE_DOCS` and leave `docID() == NO_MORE_DOCS`;
- a conjunction involving an empty analyzed interval query and another interval source does not
  throw during construction because of mismatched initial doc ids.
