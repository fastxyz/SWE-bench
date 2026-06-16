# PROOF OBLIGATIONS

Status: constructed for audit, not machine-checked.

## PO1: Opening wrapper identification

Given `prev_end` and an in-domain spread dict item, `unnecessary_spread_fix` must find:

- the `**` token preceding the spread value;
- the actual opening `{` of the inner dict literal;
- the number `p` of non-trivia `(` tokens between `**` and `{`.

Failure to find either `**` or `{` must produce `None`, not a partial edit.

## PO2: Closing wrapper balance

Given a count `p >= 0`, `trailing_edits` must:

- find the inner dict closing `}`;
- delete it;
- delete exactly `p` following `)` tokens after that `}`;
- return `None` if the matching closing tokens cannot be found.

This directly discharges the reported `)` leftover.

## PO3: Non-empty spread preservation

For non-empty inner dicts, the combined edits must:

- delete only the leading `**`, wrapper opening parentheses, and inner opening `{`;
- preserve all text for the inner dict entries;
- delete an optional trailing comma inside the inner dict before the inner `}`;
- delete the inner `}` and matching wrapper closing parentheses;
- leave the outer dict item separator in place.

The expected result for `**({"count": 1 if include_count else {}}),` is `"count": 1 if include_count else {},`.

## PO4: Empty spread item removal by outer position

For empty inner dicts, the edit must remove the spread as an outer dict item:

- only item: delete `**...{...}...` and an optional trailing comma;
- first item: delete from the spread start through the following comma/trivia up to the next item;
- middle item: delete from the spread start through the following comma/trivia up to the next item;
- last item: delete from the preceding comma through the spread end.

This obligation is the V2 addition over V1.

## PO5: Separator localization

For empty spreads:

- `following_item_start` must find the comma after the empty spread and return the start of the next non-whitespace/non-newline token, preserving comments after the comma.
- `trailing_comma_end` must delete only an immediate optional trailing comma after an only-item empty spread.
- The last-item branch must use the last comma between `prev_end` and the spread start, avoiding earlier punctuation.

## PO6: Non-overlapping edit ranges

The generated edits must be non-overlapping:

- Non-empty spreads use one leading deletion and a later ordered list of closing-token deletions.
- Empty spreads use a single deletion range.

`Fix::safe_edits` sorts non-empty edits by range, and empty edits cannot overlap because there is only one edit.

## PO7: Compatibility

The helper signature change is internal to `unnecessary_spread.rs`. The only call site is updated by passing `index == 0` and `index + 1 == dict.len()`. No public API or cross-module contract changes.

## K Claim Mapping

- `NON-EMPTY-BALANCED` covers PO1, PO2, PO3.
- `EMPTY-ONLY` covers PO4 for only-item empty spreads.
- `EMPTY-FIRST` covers PO4 and PO5 for first-item empty spreads.
- `EMPTY-MIDDLE` covers PO4 and PO5 for middle empty spreads.
- `EMPTY-LAST` covers PO4 and PO5 for last-item empty spreads.
