# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, Django, or test commands were run.

## Claims proved by construction

The proof targets `_get_edited_object_pks(request, prefix)` as modeled in
`fvk/mini-admin-post.k` and `fvk/admin-options-spec.k`.

Claim C1, literal regex equivalence: for every in-domain key, prefix, and
primary-key name, matching the V1 escaped regex is equivalent to the literal
admin primary-key field-name predicate.

Claim C2, selection soundness and completeness: scanning the POST items with
the C1 predicate returns exactly the values whose keys satisfy that predicate.

Claim C3, order preservation: because the implementation is a single list
comprehension over `request.POST.items()`, the relative order of selected values
is the same as the POST item iteration order.

Claim C4, compatibility frame: no public symbol, signature, return shape, or
caller protocol changes.

## Proof sketch

1. From O2, `re.escape(P)` and `re.escape(K)` produce regex fragments that denote
   literal `P` and literal `K`. This is the key step missing in the pre-fix code.
2. The static regex pieces `-\d+-` still denote a hyphen, one or more decimal
   digits, and a hyphen. Composing this with step 1 gives O3.
3. `_get_edited_object_pks()` iterates all `(key, value)` pairs from
   `request.POST.items()` once and includes `value` exactly when
   `pk_pattern.match(key)` is true. Substituting O3 for the match predicate gives
   O4 and O5.
4. A list comprehension preserves the iteration order of included elements, so
   O6 follows without any additional state invariant.
5. The patch changes only the expression used to build `pk_pattern`; the helper
   parameters, return expression, caller, and queryset validation code are
   unchanged. O7 follows by source inspection.
6. The repository search found no sibling `re.compile/search/match(...format(...))`
   occurrence in `repo/django`, discharging O8 for the allowed source tree.

## Counterexample removed

For `prefix = "a+b"` and `pk_name = "id"`, the legacy regex
`a+b-\d+-id$` gives `+` regex meaning. It therefore fails to denote the literal
key `a+b-0-id`. V1 builds `a\+b-\d+-id$`, so `+` is literal and the generated
formset key is selected.

## Machine-check commands not executed

The FVK command artifacts for a future machine check are:

```sh
kompile fvk/mini-admin-post.k --backend haskell
kast --backend haskell fvk/admin-options-spec.k
kprove fvk/admin-options-spec.k
```

Expected result after adapting this mini model to an installed K toolchain:
`kprove` discharges the claims to `#Top`.

## Residual risk

This is a partial-correctness proof over a mini model, not a full Python/Django
semantics proof. It relies on the standard meaning of Python `re.escape()` and
the adequacy of the abstraction that escaped regex fragments match literal
strings. No test redundancy recommendations are made because the benchmark
forbids modifying or running tests, and the proof was not machine-checked.

