# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims

The formal core is:

1. `fvk/mini-posify.k`: Mini-SymPy semantics for the `posifySymbol` replacement
   step over symbol names and assumption maps.
2. `fvk/posify-spec.k`: two reachability claims:
   - unknown-positive symbols become same-name dummies whose assumption map is
     `setPositive(A)`;
   - known-positive or known-not-positive symbols are returned unchanged.

The proof establishes partial correctness of the replacement construction:
if `posify` returns, replacement dummies preserve the original non-`positive`
assumptions and add `positive=True`.

## Constructed Proof Sketch

### Unknown-positive branch

Start with a symbol `s` satisfying `s.is_positive is None`. In V1, control enters
the replacement branch:

```python
assumptions = s.assumptions0
assumptions['positive'] = True
reps[s] = Dummy(s.name, **assumptions)
```

By the definition of `Symbol.assumptions0`, `assumptions` is a dict containing
the non-`None` facts known for `s`. Assigning `assumptions['positive'] = True`
updates only the `positive` key. Therefore every prior key/value pair whose key
is not `positive` remains in the dict, and `positive` is present with value
`True`.

The subsequent `Dummy(s.name, **assumptions)` call receives:

1. the same name as `s`;
2. every retained non-`positive` assumption from `s.assumptions0`;
3. `positive=True`.

This discharges PO2, PO3, and the same-name half of PO4. In the Mini-SymPy K
model, this is exactly the `setPositive(A)` transition in the first claim.

The replacement map entry is `reps[s] = d`, where `d` is that dummy. The final
return reverses this map as `{r: s for s, r in reps.items()}`, so the caller sees
`d: s`. This discharges the reverse-map half of PO4.

### Known positivity branch

If `s.is_positive is not None`, V1 does not enter the branch. No entry for `s` is
added to `reps`, and the later substitution has no replacement for `s`.

This preserves the existing behavior for symbols whose positivity is already
known, discharging PO1, PO6, and the public compatibility portion of PO7. In the
Mini-SymPy K model, this is the second claim.

### Expression and iterable composition

For a non-iterable expression, V1 builds the per-symbol `reps` dictionary and
then evaluates `eq = eq.subs(reps)`. Since the only changed operation is the
constructor arguments for each replacement dummy, the expression-level behavior
inherits the per-symbol proof.

For iterable input, the existing code gathers all symbols, recursively calls
`posify(s)` to obtain the same per-symbol replacements, applies one shared
symbol-to-dummy map to every element, and returns the reverse map. V1 does not
change that control/data flow, so PO5 follows from PO1-PO4 plus unchanged
iterable logic.

## Verification Conditions

1. VC1: `assumptions0` produces a fresh mapping of known facts, not an alias that
   mutates the original symbol. This follows from
   `return dict((key, value) for key, value in self._assumptions.items() if value is not None)`.
2. VC2: setting `assumptions['positive'] = True` preserves all other keys in
   that dict. This is ordinary map-update extensionality.
3. VC3: `Dummy(s.name, **assumptions)` receives all entries of the updated dict.
   This is Python keyword expansion semantics.
4. VC4: reversing `reps` gives replacement-to-original mappings. This is
   ordinary finite-map comprehension behavior.
5. VC5: the guard prevents applying positive narrowing when positivity is
   already decided. This follows from the unchanged `if s.is_positive is None`.

No loop circularities are needed.

## Findings Summary

F1 and F2 are the real pre-V1 bugs: finite and other known assumptions were
dropped. V1 resolves them by using `s.assumptions0` as the source map and
overwriting only `positive`.

F3 and F4 are compatibility risks. Both are confirmed safe by static inspection:
the positivity guard, same-name dummy construction, return-map direction, and
iterable mapping shape are unchanged.

F5 is the proof-honesty finding: the proof is constructed only.

## Commands To Machine-Check Later

These commands were not run in this benchmark environment:

```sh
kompile fvk/mini-posify.k --backend haskell
kast --backend haskell fvk/posify-spec.k
kprove fvk/posify-spec.k
```

Expected result after any needed K syntax adjustment for the local K version:
`kprove` should reduce the claims to `#Top`.

## Test Redundancy Recommendation

No tests were modified. Because the proof was not machine-checked, no test
should be removed on the basis of this FVK run.

Recommended tests to add or keep in the project's fixed test suite:

1. `posify(Symbol('x', finite=True))[0].is_finite is True`.
2. `posify(Symbol('x', integer=True))[0].is_integer is True`.
3. A restoration assertion showing the returned map still substitutes the
   transformed result back to the original symbol.
4. Existing positive, negative, iterable, and noncommutative `posify` tests.

These are recommendations only; benchmark instructions forbid modifying tests.

## Residual Risk

The proof abstracts over full SymPy expression substitution and the complete old
assumptions engine. That abstraction is property-complete for this issue because
the defect is precisely the replacement dummy's assumption map, and the model
keeps that map observable.

The trusted base is the adequacy of the Mini-SymPy fragment, SymPy's
`assumptions0` contract, Python keyword expansion semantics, and the
reachability proof method. The proof remains constructed, not machine-checked.
