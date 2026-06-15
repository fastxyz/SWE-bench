# Proof Obligations

Status: constructed, not machine-checked.

## POB-N1: named group closes at end of pattern

For a named group start `(start, end, group_name)`, scan `pattern[end:]` from
left to right with `unmatched_open_brackets = 1`.

Invariant after processing character offset `idx`:

- `unmatched_open_brackets` equals the number of unclosed, unescaped `(` tokens
  inside the current named group span, counting the outer named group.
- If the processed character is an unescaped `)`, the count is decremented
  before the completion test.
- When the count first reaches `0`, the complete span is
  `pattern[start:end + idx + 1]`.

Discharge condition: the code tests for zero after processing the current
character and records the slice through `idx + 1`. Therefore a group whose
closing `)` is final is recorded without needing a later iteration.

## POB-U1: unnamed group closes at end of pattern

For an unnamed group start `start`, scan `pattern[start + 1:]` with
`unmatched_open_brackets = 1`.

Invariant after processing character offset `idx`:

- `unmatched_open_brackets` tracks unclosed unescaped parentheses inside the
  candidate unnamed span.
- If the current character closes the outer span, the count reaches `0` on the
  same iteration.
- The complete end index is `start + 1 + idx + 1`.

Discharge condition: V2 records `(start, start + 1 + idx + 1)` immediately when
the count reaches `0`. Therefore trailing unnamed groups are recorded.

## POB-U2: selected unnamed spans are outermost and non-overlapping

Given `group_indices` sorted by start position and each span represented as
`(start, end)` with `end` exclusive, construct `group_start_end_indices`.

Invariant over the filtering loop:

- `prev_end` is `None` before any selected span.
- After a span is selected, `prev_end` is the exclusive end of the last selected
  outermost span.
- A candidate span is selected exactly when no selected span is active over its
  start position: `prev_end is None or start >= prev_end`.
- Skipped nested spans do not change `prev_end`.

Discharge condition: V2 implements that invariant. Adjacent spans with
`start == prev_end` are selected. Nested spans with `start < prev_end` are
skipped until the outer span ends.

## POB-U3: reconstruction preserves text exactly once

Given sorted, non-overlapping selected spans
`[(s0, e0), ..., (sn, en)]`, construct:

`pattern[0:s0] + '<var>' + pattern[e0:s1] + ... + '<var>' + pattern[en:]`

Loop invariant:

- Before processing span `i`, `final_pattern` contains exactly the transformed
  prefix through `prev_end`.
- `prev_end` is the end of the previous selected span, or `0` before the first
  span.
- Appending `pattern[prev_end:start]` copies only the intervening original text.
- Appending `<var>` accounts for the selected group span.

Discharge condition: V2 uses `prev_end = 0` and appends only the intervening
slice plus `<var>` for each selected span, then appends the suffix.

## POB-S1: `simplify_regex()` composition

The public wrapper must preserve its call order:

1. `replace_named_groups(pattern)`
2. `replace_unnamed_groups(pattern)`
3. cleanup of `^`, `$`, and `?`
4. insertion of leading `/` if absent

Discharge condition: V2 does not edit `simplify_regex()`. Because POB-N1,
POB-U1, POB-U2, and POB-U3 establish the helper behavior, the existing
composition satisfies the issue example and existing public-test cases within
the verified domain.

## C1: compatibility obligation

No public signature, import, return type, or call-order change is permitted.

Discharge condition: V2 changes only internal loop logic in
`django/contrib/admindocs/utils.py`; all signatures and public callsites remain
unchanged.
