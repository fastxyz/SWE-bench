# FVK Spec

Status: constructed, not machine-checked.

## Public Intent Ledger

This spec is derived from the public evidence in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligation is E3: `_reverse_with_prefix()` must discard arguments whose value is exactly `None`, so optional URL captures absent during `resolve()` are absent again during `reverse()`.

## Unit Under Audit

`repo/django/urls/resolvers.py::URLResolver._reverse_with_prefix(lookup_view, _prefix, *args, **kwargs)`.

Relevant callers:

- `repo/django/urls/base.py::reverse()` delegates to `_reverse_with_prefix()`.
- `repo/django/urls/base.py::translate_url()` resolves a path, then passes `match.args` and `match.kwargs` to `reverse()`.
- `repo/django/template/defaulttags.py::URLNode.render()` passes resolved template URL arguments to `reverse()`.

## Contract

Precondition:

- The existing public precondition remains: callers must not provide both positional `args` and keyword `kwargs` to the same reverse call. If they do, `_reverse_with_prefix()` raises `ValueError` before argument normalization.

Normalization:

- Let `args0` be the original positional argument sequence. Define `args1 = [x for x in args0 if x is not None]`, preserving order.
- Let `kwargs0` be the original keyword argument map. Define `kwargs1 = {k: v for (k, v) in kwargs0.items() if v is not None}`, preserving keys and values for all non-`None` entries.
- Empty strings, `0`, `False`, and all other non-`None` values remain present.

Candidate matching:

- Positional candidate matching uses `args1`, so an optional omitted positional component is represented by the shorter argument sequence.
- Keyword candidate matching uses `kwargs1`, so an optional omitted named component does not reject the shorter URL candidate as an extra key.
- The existing default-argument checks and regex candidate validation continue to decide whether the selected non-`None` values can construct a valid URL.

Postcondition:

- No substitution map used to render a candidate URL contains a `None` value supplied by `args0` or `kwargs0`.
- A `None` from an absent optional capture cannot be converted to the literal text `"None"`.
- Existing behavior for non-`None` values is preserved except where candidate selection now correctly treats `None` as omitted.

## Formal Model Scope

The K artifacts model the proof-relevant fragment:

- the `None`-dropping transformation on positional values;
- the `None`-dropping transformation on keyword maps;
- concrete optional-candidate examples corresponding to `kwargs={'arg1': 1, 'arg2': None}` and `args=[1, None]`.

The model abstracts regex compilation, quoting, converter methods, and resolver population. Those are frame conditions: V1 changes only the values that enter the already-existing candidate-selection code.

