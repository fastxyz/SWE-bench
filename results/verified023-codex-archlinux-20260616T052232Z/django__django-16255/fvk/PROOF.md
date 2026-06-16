# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Target Claim

For `Sitemap.get_latest_lastmod()`:

- absent `lastmod` returns `None`;
- non-callable `lastmod` returns the attribute value;
- callable `lastmod` over empty `items()` returns `None`;
- callable `lastmod` over non-empty comparable values returns their maximum;
- callable `lastmod` comparison `TypeError` returns `None`.

## Proof Structure

The function has no loops, so there are no circularity obligations. The proof is a case split over the branch conditions in `get_latest_lastmod()`.

### Case 1: `lastmod` Missing

The source branch `if not hasattr(self, "lastmod"): return None` is modeled by the NO-LASTMOD claim. The mini semantics rewrites `getLatestLastmod` with `<lastmod> missing </lastmod>` directly to `.K` and sets `<result>` to `none`. This discharges PO-2.

### Case 2: `lastmod` Is a Non-Callable Attribute

The source branch `else: return self.lastmod` is modeled by ATTRIBUTE-LASTMOD. The mini semantics rewrites `constant(V)` to result `V`. This preserves documented attribute behavior and discharges PO-3.

### Case 3: `lastmod` Is Callable and `items()` Is Empty

The V1 source evaluates `max([self.lastmod(item) for item in self.items()], default=None)`. For an empty finite item list, the comprehension produces `[]`, and Python's `max(..., default=None)` returns `None` instead of raising `ValueError`. The mini semantics represents this as `maxDefault(.LmValues, none) => ok(none)` and `fromMax(ok(none)) => none`. This discharges PO-4 and closes F-001.

### Case 4: `lastmod` Is Callable and Values Are Non-Empty/Comparable

For non-empty comparable timestamp values, adding a `default` to `max()` does not affect Python's maximum selection. The mini semantics reduces a non-empty list of `dt(Int)` values by repeated `maxInt` until one maximum timestamp remains. This discharges PO-5 and closes F-003.

### Case 5: Callable Comparison Raises `TypeError`

The source still catches `TypeError` and returns `None`. The mini semantics represents an incomparable callable value as `bad`, for which `maxDefault(...) => typeError` and `fromMax(typeError) => none`. This discharges PO-6.

## Adequacy and Compatibility

`SPEC_AUDIT.md` marks every formal claim as matched to intent. `PUBLIC_COMPATIBILITY_AUDIT.md` found no public signature, callsite, or override compatibility issue. This discharges PO-1 and PO-7.

## Machine-Check Commands

These commands are recorded for a later environment with K installed. They were not executed here.

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell sitemap-lastmod-spec.k
kprove sitemap-lastmod-spec.k
```

Expected machine-check result for the constructed claims: all claims reduce to `#Top`.

## Test Recommendation

No tests were modified. If the K claims are machine-checked later, a direct unit test asserting empty callable `lastmod` returns `None` would be subsumed by PO-4. Existing integration tests around template rendering and headers should be kept because this proof audits only `get_latest_lastmod()` and its immediate return contract.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics abstracts full Python object dispatch into lastmod modes and finite value lists.
- Termination of user-provided `items()` and `lastmod()` implementations is outside the partial-correctness scope.
