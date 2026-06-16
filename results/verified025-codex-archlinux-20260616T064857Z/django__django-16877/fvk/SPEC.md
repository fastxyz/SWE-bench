# FVK Spec

Status: constructed, not machine-checked.

## Scope

Target unit: `django.template.defaultfilters.escapeseq`.

Issue-level observable: the template pipeline
`{{ some_list|escapeseq|join:"," }}` when autoescape is off.

Out of scope for this patch: redefining `join` separator escaping, changing
`escape`/`force_escape` semantics, changing `safeseq`, or proving the internals
of Django's existing `conditional_escape()` helper.

## Intent ledger summary

- E1/E7 require a public filter named `escapeseq` registered with Django's
  built-in template filter library.
- E2 requires every sequence element to be escaped before `join` consumes the
  sequence.
- E3/E5 require a sequence-map shape analogous to `safeseq`: same order, same
  cardinality, per-element transformation.
- E4 requires conditional `escape` semantics, not force escaping of already-safe
  values.
- E6 explains why the transformation must happen before `join` in `autoescape
  off`: that branch concatenates the sequence directly and marks the result safe.
- E8 requires docs coverage for the new public built-in filter.

## Contract

For every finite sequence `xs = [x0, x1, ..., xn]` whose elements are acceptable
inputs to `conditional_escape()`:

```text
escapeseq(xs) = [
    conditional_escape(x0),
    conditional_escape(x1),
    ...,
    conditional_escape(xn),
]
```

The result has the same length and order as `xs`.

For each element `xi`:

- if `xi` has `__html__()`, the result element is `xi.__html__()`;
- otherwise, the result element is `escape(str(xi))`.

For the issue pipeline under `autoescape off`:

```text
join(escapeseq(xs), sep, autoescape=False)
    = mark_safe(sep.join([conditional_escape(x) for x in xs]))
```

Because each transformed element is already escaped or already safe, the joined
payload contains escaped item content before `join` marks the aggregate string
safe. The separator remains governed by existing `join` behavior.

## Formal model

The K model represents template values as either:

- `raw(S)`: an unsafe string-like value whose payload must be HTML escaped;
- `safe(S)`: a value that already provides safe HTML.

The model abstracts Django's existing HTML replacement table as
`htmlEscape(S)`. This is a trusted dependency of the proof because the patch is
about applying existing escape semantics to every item, not changing the escape
algorithm itself.

The central spec functions are:

- `conditionalEscape(raw(S)) = safe(htmlEscape(S))`;
- `conditionalEscape(safe(S)) = safe(S)`;
- `escapeSeq(.Items) = .Items`;
- `escapeSeq(I ; REST) = conditionalEscape(I) ; escapeSeq(REST)`.

The formal claims are in `fvk/escapeseq-spec.k`.

## Adequacy verdict

The formal claims cover the full issue intent:

- public filter registration is checked as a source obligation;
- per-item transformation is modeled for arbitrary finite sequences;
- order and cardinality are preserved by structural recursion over the list;
- already-safe values are not double escaped;
- the named `autoescape off` `join` composition is modeled.

No functional source-code problem remained after the audit. The public docs gap
was outside the V1 function body but inside the public built-in filter surface,
so it was fixed in `repo/docs/ref/templates/builtins.txt`.
