# Findings

Status: constructed, not machine-checked.

## F-001: V1 removes the reported undefined `sourcesContent` crash

Input:

- `opts.inputSourceMap` is present.
- `TraceMap(opts.inputSourceMap).resolvedSources` has at least one source.
- `TraceMap(opts.inputSourceMap).sourcesContent` is `undefined`.

Observed in pre-fix code:

- The constructor attempted `this._inputMap.sourcesContent[i]`, so `i = 0` raised `Cannot read properties of undefined (reading '0')`.

Expected:

- Source map generation should proceed without copying unavailable source contents.

V1 status:

- Resolved. The `if (sourcesContent)` guard prevents entering the copy loop when contents are absent.

Related obligations: PO-001, PO-004.

## F-002: V1 preserves provided input source contents

Input:

- `resolvedSources = [s0, s1, ...]`.
- `sourcesContent = [c0, c1, ...]`.

Observed in V1:

- For every index within both arrays, V1 calls `setSourceContent(map, resolvedSources[i], sourcesContent[i])`.

Expected:

- Existing source-content copy behavior should remain intact for input maps that include contents.

V1 status:

- Resolved. The guard does not alter the present-content path.

Related obligations: PO-002.

## F-003: V1 correctly avoids fallback content synthesis

Input:

- Input map sources point to original files, but the input map omits `sourcesContent`.
- The `code` argument is the currently transformed code.

Observed alternative rejected:

- Filling missing source contents from `code` would attach transformed code to original source names.

Expected:

- Missing input source contents should remain missing.

V1 status:

- Resolved. The absent-content path performs no `setSourceContent` update.

Related obligations: PO-004.

## F-004: Residual domain limit for malformed sparse arrays

Input:

- A JavaScript caller provides a present `sourcesContent` array with sparse holes or explicit `undefined` entries.

Observed:

- V1's domain proof treats present entries as valid source-content values and does not separately sanitize holes inside an existing array.

Expected:

- The public issue does not specify this malformed-input behavior.

V1 status:

- No production change justified by public intent. This is a residual hardening opportunity, not a blocker for the reported valid omitted-field case.

Related obligations: PO-002 domain, PO-006.

## Proof-derived findings from `/verify`

No proof-derived code bug was found. The constructed proof obligations identify the same necessary guard that V1 already implements. The only residual item is F-004, which is outside the public issue's stated domain and does not justify expanding the patch.
