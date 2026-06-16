# Formal Spec English

Status: constructed for FVK audit, not machine-checked.

## Claim MERGE-ATTRS-OVERRIDE-COPY

Starting with a non-empty attrs list whose first attrs object is `attr(ID0, M0)`, running `mergeAttrs(..., override)` returns an attrs object `attr(N, M0)` where `N` is the allocator's fresh result id and `N != ID0`. In plain language: override returns a new attrs mapping with the same contents as the first source attrs mapping, rather than returning the first mapping object itself.

## Claim MERGE-ATTRS-DROP

Running `mergeAttrs(non_empty_attrs, drop)` returns a fresh empty attrs mapping. In plain language: drop discards all input attrs and does not alias a source attrs mapping.

## Claim MERGE-ATTRS-EMPTY

Running `mergeAttrs(emptyAttrs, mode)` returns `none`. In plain language: the helper's existing no-input convention is unchanged.

## Claim MERGE-ATTRS-NO-CONFLICTS

When the input attrs list is compatible for `no_conflicts`, running `mergeAttrs(attrs, noConflicts)` returns a fresh attrs mapping whose contents are the compatible union of the inputs. In plain language: no-conflicts preserves its existing combine behavior while allocating a result mapping.

## Claim MERGE-ATTRS-IDENTICAL

When all attrs are identical, running `mergeAttrs(attrs, identical)` returns a fresh attrs mapping with the first attrs contents. In plain language: identical preserves its existing equality requirement while allocating a result mapping.

## Claim MERGE-ATTRS-BAD-MODE

Running `mergeAttrs(non_empty_attrs, badMode)` returns a `valueError` result in the mini semantics. In plain language: unknown combine modes still error.
