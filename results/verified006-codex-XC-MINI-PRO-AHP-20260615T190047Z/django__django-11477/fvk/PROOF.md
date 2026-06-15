# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or Django code were executed.

## Claims Proved In The Model

The proof targets the model in `fvk/mini-python.k` and `fvk/url-reverse-spec.k`.

- `ARGS-DROP-NONE`: positional normalization removes exactly `None` entries.
- `KWARGS-DROP-NONE`: keyword normalization removes exactly entries whose value is `None`.
- `OPTIONAL-KWARGS`: `{'arg1': 1, 'arg2': None}` normalizes to `{'arg1': 1}`.
- `OPTIONAL-ARGS`: `[1, None]` normalizes to `[1]`.
- `EMPTY-STRING-PRESERVED`: `['']` remains `['']`.

## Proof Sketch

For `ARGS-DROP-NONE`, proceed by structural induction over the positional value list.

- Base case: `.Values` rewrites to `.Values`.
- Step case `None VS`: the semantic rule rewrites to `dropNoneArgs(VS)`, and the induction hypothesis removes `None` entries from the tail.
- Step case `V VS` with `V =/=K None`: the semantic rule keeps `V` and recurses on `VS`, preserving order of all non-`None` values.

For `KWARGS-DROP-NONE`, proceed by structural induction over finite keyword-map entries.

- Base case: `.Map` rewrites to `.Map`.
- Step case `K |-> None`: the rule omits the binding and recurses on the rest of the map.
- Step case `K |-> V` with `V =/=K None`: the rule keeps `K |-> V` and recurses on the rest of the map.

The optional-candidate obligations instantiate these normalization claims:

- Keyword case: `arg1 |-> int(1), arg2 |-> None` rewrites to `arg1 |-> int(1)`. The shorter optional candidate has params `{arg1}` and therefore no longer sees `arg2` as an extra supplied key.
- Positional case: `int(1), None` rewrites to `int(1)`. A candidate with one positional parameter is eligible.

The empty-string frame condition follows because `str("") =/=K None`; the `None` rule does not fire for the empty string.

The mixed-arguments frame condition follows directly from source ordering in `repo/django/urls/resolvers.py`: the `ValueError` check remains before the new normalization statements.

## Relation To Django Source

V1 adds exactly this normalization to `_reverse_with_prefix()`:

```python
args = tuple(arg for arg in args if arg is not None)
kwargs = {k: v for k, v in kwargs.items() if v is not None}
```

The subsequent Django code still performs the same length/key/default checks, converter calls, regex candidate validation, quoting, and escaping.

## Machine-Check Commands

These commands are intentionally not executed in this workspace:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/url-reverse-spec.k
kprove fvk/url-reverse-spec.k
```

Expected outcome after a real machine check: `kprove` discharges the listed claims to `#Top`.

## Test Recommendation

Do not delete any tests based on this constructed proof. If machine-checked later, focused unit tests that assert the exact in-domain normalization points above may be redundant, but integration tests for `translate_url()`, `set_language`, template rendering, regex matching, and quoting should remain because the proof abstracts those layers.

Recommended tests to add or keep in the fixed suite:

- `reverse()` with `kwargs={'arg1': 1, 'arg2': None}` for an optional named capture returns the shorter URL.
- `reverse()` with positional args `[1, None]` for an optional capture returns the shorter URL.
- `translate_url()` preserves query and fragment while omitting the absent optional component.
- `{% url %}` with an empty-string argument still behaves as a supplied argument, not as omitted.

