# FVK Notes

## Decision

I kept the V1 source unchanged.

F-001 is the reported bug: equivalent default URLconf forms could construct
multiple `URLResolver` instances. PO-1 and PO-2 show that V1 discharges this by
normalizing `None` to `settings.ROOT_URLCONF` before the memoized helper call.

F-002 is the compatibility risk created by moving the cache from the public
function to a private helper. PO-4 shows that V1 discharges it by forwarding
`get_resolver.cache_clear` to `_get_cached_resolver.cache_clear`, preserving
`clear_url_caches()`.

F-003 checks that the fix is not too broad. PO-3 shows explicit non-default
URLconfs still pass through unchanged and remain independently cached.

F-004 is a domain boundary, not a source-change requirement. PO-6 limits the
proof to the documented `ROOT_URLCONF` string/hashable-object domain; explicit
unhashable URLconfs were already incompatible with the LRU-cached public path.

F-005 is the honesty gate. No K tooling, Python, or Django tests were run. The
proof artifacts contain the commands and expected result for a later
machine-checking environment.

## Files Added

`fvk/SPEC.md` records the intent spec, evidence ledger, formal English, spec
audit, and compatibility audit.

`fvk/FINDINGS.md` records the defect, compatibility risk, over-fix check, domain
boundary, and proof caveat.

`fvk/PROOF_OBLIGATIONS.md` names the obligations used to confirm V1.

`fvk/PROOF.md` gives the constructed proof and exact K commands.

`fvk/ITERATION_GUIDANCE.md` explains why V1 stands and what regression tests
would be useful outside this no-test-edit benchmark.

`fvk/mini-resolver-cache.k` and `fvk/get-resolver-spec.k` are the FVK K core
artifacts required by the method documentation.
