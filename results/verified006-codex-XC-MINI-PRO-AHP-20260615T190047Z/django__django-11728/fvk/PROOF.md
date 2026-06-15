# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were executed.

## Claims proved by construction

- `REPLACE-NAMED-TRAILING`: a named group ending at the final character is
  recorded and replaced.
- `REPLACE-UNNAMED-TRAILING`: an unnamed group ending at the final character is
  recorded and replaced.
- `UNNAMED-OUTERMOST`: unnamed span filtering keeps outermost non-overlapping
  spans, including adjacent spans, while skipping nested spans.
- `UNNAMED-RECONSTRUCT`: reconstruction preserves all non-group text exactly
  once and substitutes `<var>` for each selected span.
- `SIMPLIFY-ISSUE-CASE`: the public issue pattern simplifies through the public
  wrapper to `/entries/<pk>/relationships/<related_field>`.
- `COMPATIBILITY`: public signatures, return types, and wrapper call order are
  unchanged.

## Proof sketch

### Named scanner

The scanner initializes `unmatched_open_brackets` to `1` at a named group start.
For each character after the name header, unescaped `(` increments the count and
unescaped `)` decrements it. V2 performs the zero test after applying that
transition. Therefore the first time the count is zero, the current character is
the closing parenthesis of the whole named group. The recorded span is
`pattern[start:end + idx + 1]`, which includes that parenthesis. If the
parenthesis is the final character, the same iteration records the span; no
later iteration is needed.

### Unnamed scanner

The unnamed scanner has the same balance transition, with indices relative to
`pattern[start + 1:]`. When the outer closing parenthesis is consumed at offset
`idx`, the exclusive end is `start + 1 + idx + 1`. V2 records that end
immediately. This proves the unnamed trailing-group case.

### Outermost filtering

`group_indices` is generated in increasing start order. V2 maintains
`prev_end` as the exclusive end of the last selected outermost span. A candidate
is selected when `prev_end is None or start >= prev_end`. If `start < prev_end`,
the candidate is nested inside the selected span and is skipped. Skipped spans do
not update `prev_end`, so later nested spans inside the same outer group remain
skipped. Adjacent spans satisfy `start == prev_end` and are selected.

### Reconstruction

For selected spans sorted by start and non-overlapping by the filtering proof,
V2 initializes `prev_end = 0`. Each loop appends exactly the untouched segment
`pattern[prev_end:start]`, appends `<var>`, then moves `prev_end` to the
selected span's exclusive end. By induction over the selected spans,
`final_pattern` is the correctly transformed prefix through `prev_end`. Appending
`pattern[prev_end:]` after the loop completes the transformed string. No prefix
can be duplicated because no iteration appends `pattern[:start]`.

### Public wrapper composition

`simplify_regex()` was not edited. It still applies named replacement before
unnamed replacement, then removes `^`, `$`, and `?`, then adds a leading slash
when absent. Combining the scanner proofs with this unchanged composition proves
the issue pattern reaches `/entries/<pk>/relationships/<related_field>`.

## Proof-derived findings

The proof obligations found two V1 residual issues in `replace_unnamed_groups()`:

- F3: multiple selected unnamed groups duplicated the original prefix during
  reconstruction.
- F4: adjacent groups were skipped and later nested groups could be selected
  after an earlier nested skip because `prev_end` was updated for skipped spans.

Both findings are addressed in V2.

## Test guidance

No tests were run and no test files were edited. Recommended public tests to add
after this benchmark phase:

- final named group without slash;
- final unnamed group without slash;
- multiple separated unnamed groups;
- adjacent unnamed groups;
- outer unnamed group containing more than one nested group.

Existing unit tests that assert in-domain point examples would be candidates for
conditional redundancy only after the K commands below are run and return
`#Top`. Until then, keep all tests.

## Machine-check commands not executed

```sh
kompile fvk/mini-regex-groups.k --backend haskell
kast --backend haskell fvk/admindocs-regex-spec.k
kprove fvk/admindocs-regex-spec.k
```

Expected result after a complete machine-checking setup: `kprove` returns
`#Top` for the constructed claims.
