# Intent Spec

Status: constructed from public intent only; not machine-checked.

## Required behavior

1. Django must expose a new built-in template filter named `escapeseq`.

2. For any finite template sequence `xs`, `escapeseq(xs)` must return a
   sequence with the same length and order as `xs`.

3. Each result element must be the result of applying the existing template
   `escape` semantics to the corresponding input element.

4. Since Django's `escape` filter is conditional rather than forceful, already
   safe values must not be escaped a second time.

5. In the issue's named pipeline,
   `{{ some_list|escapeseq|join:"," }}` inside `autoescape off`, each item of
   `some_list` must be escaped before `join` concatenates the sequence.

6. The new filter must not change existing `join`, `escape`, `safe`, or
   `safeseq` behavior. Separator handling remains `join`'s existing behavior.

7. As a public built-in template filter, `escapeseq` should be documented with
   the other built-in template filters.

## Domain assumptions

1. The sequence is finite and iterable, matching the existing `safeseq` and
   `join` sequence-filter domain.

2. Sequence elements are values accepted by `django.utils.html.conditional_escape`.

3. The FVK proof treats the exact HTML replacement table implemented by
   `conditional_escape()` and `escape()` as a trusted existing Django dependency;
   this audit verifies that the new filter applies that dependency to every
   sequence element in order.
