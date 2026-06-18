# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases every nontrivial claim in `srepr-containers-spec.k`.

1. `(LIST-REGRESSION)`: Printing a list containing symbols `x` and `y` reaches `[Symbol('x'), Symbol('y')]`. This preserves the issue's stated correct list behavior.
2. `(TUPLE-REGRESSION)`: Printing a two-element tuple containing symbols `x` and `y` reaches `(Symbol('x'), Symbol('y'))`. This preserves the issue's stated correct tuple behavior.
3. `(SET-ISSUE-XY)`: Printing a set containing `x` and `y` reaches `{Symbol('x'), Symbol('y')}` in deterministic printer order, not `{x, y}`.
4. `(SET-ISSUE-YX)`: Printing the same set members in the opposite source order reaches the same deterministic `{Symbol('x'), Symbol('y')}` spelling.
5. `(DICT-ISSUE-XY)`: Printing a dict with key `x` and value `y` reaches `{Symbol('x'): Symbol('y')}`, not `{x: y}`.
6. `(SET-GENERAL)`: Printing any nonempty modeled set reaches a set literal whose body is the recursive representation of each member after abstract `default_sort_key` ordering.
7. `(DICT-GENERAL)`: Printing any modeled dict reaches a dict literal whose body recursively represents every sorted key and its associated value.
8. `(EMPTY-SET)`: Printing the empty set reaches `set()`.
9. `(EMPTY-DICT)`: Printing the empty dict reaches `{}`.
10. `(FROZENSET)`: Printing a nonempty frozenset reaches `frozenset(<set literal>)`, with the inner set literal recursively representing members.
11. `(SYMPY-DICT)`: Printing a SymPy `Dict` reaches `Dict(<dict literal>)`, preserving the wrapper type while recursively representing contents.
12. `(REPR-SEQ-CIRCULARITY)`: The recursive sequence helper prints the head element recursively, inserts `, `, and then recursively prints the tail.
13. `(REPR-PAIRS-CIRCULARITY)`: The recursive pair helper prints each key and value recursively, inserts `: ` within a pair, `, ` between pairs, and then recurs on the remaining pairs.

Side conditions and frame conditions:

- The model assumes finite acyclic containers.
- The exact implementation of `default_sort_key` is abstracted by `sortVals` and `sortPairs`.
- The proof is partial correctness only and has not been run through `kprove`.
