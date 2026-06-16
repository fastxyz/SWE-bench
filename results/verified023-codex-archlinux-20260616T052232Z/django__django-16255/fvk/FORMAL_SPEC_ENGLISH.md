# Formal Spec English

Status: paraphrase of `fvk/sitemap-lastmod-spec.k`; constructed, not machine-checked.

## Claim NO-LASTMOD

Starting in a state where `lastmod` is missing, executing `getLatestLastmod` terminates with result `none`. This models `not hasattr(self, "lastmod") -> None`.

## Claim ATTRIBUTE-LASTMOD

Starting in a state where `lastmod` is a constant non-callable value `V`, executing `getLatestLastmod` terminates with result `V`. This models the documented attribute branch.

## Claim CALLABLE-EMPTY-LASTMOD

Starting in a state where `lastmod` is callable and the callable result list is empty, executing `getLatestLastmod` terminates with result `none`. This is the reported bug case and models `max([], default=None) -> None`.

## Claim CALLABLE-LASTMOD

Starting in a state where `lastmod` is callable and its finite result list is `VS`, executing `getLatestLastmod` terminates with `fromMax(maxDefault(VS, none))`. For comparable datetime-like values, this is the latest value. For the empty list, it is `none`. For modeled comparison `TypeError`, it is `none`.

## Claim CALLABLE-NONEMPTY-COMPARABLE

Starting in a state where callable `lastmod` produces at least one comparable timestamp value, executing `getLatestLastmod` terminates with the maximum timestamp in that list.

## Claim CALLABLE-TYPEERROR

Starting in a state where callable `lastmod` produces modeled incomparable values, executing `getLatestLastmod` terminates with `none`, preserving the existing `except TypeError: return None` behavior.

## Frame/Compatibility Claims

The formal model contains no signature, argument-shape, or virtual-dispatch change. The source patch changes only the empty iterable behavior of `max()` in the existing callable branch.
