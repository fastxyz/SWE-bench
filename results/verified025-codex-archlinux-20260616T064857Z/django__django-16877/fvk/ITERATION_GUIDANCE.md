# Iteration Guidance

Status: constructed, not machine-checked.

## Code outcome

Keep the V1 functional implementation in
`repo/django/template/defaultfilters.py`.

Reason: F-001 discharges PO-1 through PO-4. The code registers `escapeseq` and
maps `conditional_escape()` over every sequence element before downstream
filters such as `join` run.

## V2 improvement

Add public docs for the new built-in filter.

Reason: F-002 and PO-6 identified a public documentation gap. V2 adds
`.. templatefilter:: escapeseq` in `repo/docs/ref/templates/builtins.txt`.

## Rejected changes

Do not replace `conditional_escape()` with `escape()`.

Reason: F-003 and PO-3 require `escape` filter semantics, not `force_escape`
semantics. `conditional_escape()` is the existing helper used by the `escape`
template filter.

Do not change `join`.

Reason: PO-4 and PO-5 localize the bug to the absence of a pre-join sequence
escape filter. Changing `join` would alter existing public behavior beyond the
issue intent.

Do not add special non-iterable handling to `escapeseq`.

Reason: F-004 records the domain as finite sequences, matching the prompt and
the neighboring `safeseq` filter.

## Future validation

When an execution environment is available, add or run tests for:

- `escapeseq` is registered as a built-in template filter;
- `{{ some_list|escapeseq|join:"," }}` with `autoescape off` escapes unsafe
  items;
- already-safe items are not double escaped;
- item order and cardinality are preserved;
- `join` separator behavior is unchanged.

If K is available, run the commands in `PROOF.md` and require `kprove` to return
`#Top` before treating the proof as machine-checked.
