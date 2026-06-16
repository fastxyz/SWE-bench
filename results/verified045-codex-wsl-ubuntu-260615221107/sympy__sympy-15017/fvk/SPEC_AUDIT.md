# Spec Audit

Status: pass for the intended scalar length behavior. The proof is constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
|---|---|---|---|
| C1 immutable dense scalar length is 1 | Intent items 1-4 | Pass | Directly covers `sympy.Array(3)` because `Array = ImmutableDenseNDimArray`. |
| C2 mutable dense scalar length is 1 | Intent items 2-4 plus shared `NDimArray.__len__` wording | Pass | Extends the shared contract to the mutable dense constructor with the same root cause. |
| C3 immutable sparse scalar length is 1 | Intent items 2-4 plus shared `NDimArray.__len__` wording | Pass | Needed because sparse arrays cache `_loop_size` separately. |
| C4 mutable sparse scalar length is 1 | Intent items 2-4 plus shared `NDimArray.__len__` wording | Pass | Needed for consistency across all storage/mutability variants. |
| C5 representative nonempty shape keeps product length | Intent item 5 | Pass | Prevents the scalar fix from weakening non-rank-0 behavior. |
| S1 constructor size is `product(shape)` with empty product `1` | Intent items 2-5 | Pass | This is the minimal source-level root cause: `_loop_size` is the value returned by `__len__`. |
| E7 legacy public test expecting length 0 | Conflicts with intent items 2-4 | Suspect | FVK treats this as stale bug-preserving evidence, not as an oracle. |
| F1 no signature/dispatch changes | Compatibility intent | Pass | Public calls keep the same method names and arguments. |
