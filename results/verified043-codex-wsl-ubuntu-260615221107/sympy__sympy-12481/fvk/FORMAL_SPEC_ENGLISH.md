# Formal Spec English

Status: English paraphrase of `permutation-constructor-spec.k`, constructed but not machine-checked.

FE1. `CONSTRUCT-CYCLES-NONDISJOINT`: For any list-of-lists cyclic input `CS` whose individual cycles are valid, including lists where an element appears in more than one cycle, `construct(cycles(CS), SZ)` returns the permutation produced by folding the cycles from left to right and then applying the optional size extension. The claim has no disjointness precondition.

FE2. `ISSUE-IDENTITY`: `construct(cycles([cycle(0, 1), cycle(0, 1)]), noSize)` returns `perm([0, 1])`.

FE3. `ARRAY-DUPLICATES-REJECTED`: For array-form input `array(A)`, if `A` has duplicate entries, construction reaches `error(repeatedArray)`.

FE4. `CYCLE-FOLD`: The cycle fold starts with the identity cycle map and, for each cycle in list order, replaces the accumulator with `composeCycle(accumulator, nextCycle)`. This is the formal version of the constructor loop `for ci in args: c = c(*ci)`.

FE5. `VALID-CYCLE-SIDE-CONDITION`: The only validity side condition for cyclic list input is per-cycle validity: elements inside a single cycle are unique and non-negative. Cross-cycle repetition is explicitly outside that side condition.

FE6. `SIZE-FRAME`: After either array or cyclic construction has produced an array form, a positive `size` larger than the array length extends the array with fixed points. The FVK proof treats this as framed behavior because V2 did not change that branch.

FE7. `API-FRAME`: The constructor signature, return type, and public call protocol are unchanged.
