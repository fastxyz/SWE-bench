# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Absent source contents are safe

Evidence: E1, E2, E3.

Precondition:

- `opts.inputSourceMap` is present.
- `TraceMap(opts.inputSourceMap).resolvedSources` is any finite source list.
- `TraceMap(opts.inputSourceMap).sourcesContent` is nullish/absent.

Obligation:

- The constructor must not read `sourcesContent[0]` or any other index.
- The input-map copy step must leave generated-map source contents unchanged.
- `_inputMap` must still be initialized for later source-position tracing.

Formal claim: `COPY-NO-CONTENT`.

Status: discharged by constructed proof.

## PO-002: Present source contents are preserved

Evidence: E4.

Precondition:

- `sourcesContent` is a finite array.
- `resolvedSources` is a finite array.

Obligation:

- For every index `i` where both arrays have an entry, call `setSourceContent(map, resolvedSources[i], sourcesContent[i])`.
- Do not call `setSourceContent` for indices beyond `sourcesContent.length`.

Formal claim: `COPY-SOME-CONTENT`.

Status: discharged by constructed proof.

## PO-003: Non-copy behavior is framed

Evidence: E5, E6.

Obligation:

- V1 must not alter `_inputMap` creation.
- V1 must not alter `mark()` lookup behavior.
- V1 must not alter direct string-code content insertion when no input map is present.
- V1 must not alter object-code content insertion.

Status: discharged by static frame review; outside the `.k` slice but covered by unchanged code.

## PO-004: No synthesized source contents

Evidence: E7 and source-map chaining semantics.

Obligation:

- If an input map omits source contents, Babel must not substitute the currently transformed code as content for the input map's original sources.

Status: discharged by PO-001; `noContent` performs no generated-map content update.

## PO-005: Public compatibility

Evidence: E8.

Obligation:

- Do not change public constructor parameters, methods, result shape, or call protocol.

Status: discharged by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-006: Bounded loop progress

Evidence: source loop structure.

Obligation:

- The copy loop advances `i` monotonically from `0` toward `resolvedSources.length`.
- On finite arrays, the loop reaches the bound and terminates.

Status: reasoned as a finite-list structural recursion in `COPY-SOME-CONTENT`; machine-check still pending.
