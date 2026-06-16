# PROOF

Status: constructed, not machine-checked. No tests, Python, Ruff, Cargo, `kompile`, or `kprove` were run.

## Exact Commands Not Run

```sh
kompile fvk/mini-pie800-fixer.k --backend haskell
kast --backend haskell fvk/unnecessary-spread-spec.k
kprove fvk/unnecessary-spread-spec.k
```

Expected machine-check result after installing/running K: `kprove` discharges all claims to `#Top`.

## Proof Sketch

### Non-empty parenthesized and unparenthesized spreads

Let the spread item have the token shape:

```text
** L^p { E [,] } R^p S
```

where `L` is `(`, `R` is `)`, `p >= 0`, `E` is the non-empty inner dict entry text, and `S` is the outer item separator or outer dict close.

By PO1, `unnecessary_spread_fix` finds `**`, the actual `{`, and `p`. The leading edit deletes exactly `** L^p {`.

By PO2, `trailing_edits` starts after the last inner value, optionally deletes the inner trailing comma, deletes the inner `}`, and then deletes exactly `p` closing `R` tokens. It returns `None` instead of a partial edit if those closing tokens are not found.

By PO3, the entry text `E` is never part of a deletion range, so it remains. The remaining shape is:

```text
E S
```

For the issue input, `E` is `"count": 1 if include_count else {}` and `S` is the outer comma, so the result is syntactically valid:

```text
"count": 1 if include_count else {},
```

### Empty spread, only item

The empty item has token shape:

```text
** L^p { } R^p [,]
```

`trailing_edits` computes the spread end after `}` and all `R^p`. `empty_spread_edit` deletes from the spread start through that spread end and, via `trailing_comma_end`, includes an immediate optional trailing comma. The containing dict is left with no item text between its braces.

### Empty spread, first or middle item

The empty item has token shape:

```text
** L^p { } R^p , NEXT
```

For both first and middle positions, `empty_spread_edit` deletes from the spread start through the following separator up to `NEXT`. If a previous item exists, its preceding separator remains; if no previous item exists, no leading separator remains. The result contains a single valid separator structure around `NEXT`.

### Empty spread, last item

The empty item has token shape:

```text
PREV , ** L^p { } R^p [,]
```

For a last item with a previous item, `empty_spread_edit` deletes from the last comma between `prev_end` and the spread start through the spread end. If an outer trailing comma follows the spread, it remains as the previous item's trailing comma, which is syntactically valid.

## Adequacy

The proof obligations cover the whole intended behavior space for this fixer family: non-empty dict spreads, parenthesized wrappers, empty dict spreads, and empty item positions in the outer dict. The abstraction does not model the full Rust tokenizer or Python parser, but it keeps the defect axis visible: unmatched wrapper parentheses and invalid comma separators.

## Test Recommendations

No tests were run and no test files were changed. Recommended tests to add or keep in the hidden/fixed suite:

- reported parenthesized non-empty spread with an `if` expression containing `{}`;
- non-empty spread with wrapper parentheses and a parenthesized last value;
- empty spread as only, first, middle, and last dict item;
- parenthesized empty spread in those same positions;
- existing non-empty comment-preservation fixture.

Do not remove any test based on this constructed proof until the K commands above are actually run and discharge to `#Top`.
