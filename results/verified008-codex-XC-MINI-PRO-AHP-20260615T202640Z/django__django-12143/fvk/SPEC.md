# FVK Specification: django__django-12143

Status: constructed, not machine-checked.

## Target

The audited source unit is `ModelAdmin._get_edited_object_pks()` in
`repo/django/contrib/admin/options.py`. It is used by admin `list_editable`
POST handling through `_get_list_editable_queryset()`.

## Intent-only contract

For a finite ordered POST item sequence, a formset prefix `P`, and a model
primary-key field name `K`, `_get_edited_object_pks(request, P)` returns exactly
the POST values whose keys are generated primary-key field names of this shape:

```text
P + "-" + one_or_more_decimal_digits + "-" + K
```

The dynamic fragments `P` and `K` are literal field-name text. In particular,
regex metacharacters inside `P` must not change which POST keys are selected.
The helper preserves POST item order and does not validate, coerce, or mutate
the selected values.

The proof domain is the admin list-editable formset naming grammar: finite POST
items with string keys and values, a string prefix, and a string primary-key
field name. The index segment follows the existing `\d+` grammar used by the
admin helper; the reported issue concerns the literalness of dynamic fragments,
not a change to index-digit semantics.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Generating a regex like this using string formatting can cause problems when the arguments contain special regex characters." | Dynamic fragments interpolated into the regex must be matched literally. | Encoded as O1/O2/O3. |
| E2 | prompt | "prefix has no such restrictions ... and could contain any number of special regex characters." | The prefix domain includes regex metacharacters such as `.`, `+`, `*`, `[`, `]`, `(`, `)`, `^`, `$`, and `\`. | Encoded as O1/O2. |
| E3 | prompt | "The fix is quite straightforward (use re.escape())." | `re.escape()` is the intended mechanism for literalizing the regex fragments. | Encoded as O2. |
| E4 | code | `pk_key = '%s-%s' % (self.add_prefix(i), self.model._meta.pk.name)` in `BaseModelFormSet._construct_form()`. | Primary-key POST keys are formset prefix, index, and primary-key name joined by hyphens. | Encoded as O3. |
| E5 | code | `_get_edited_object_pks()` returns `[value for key, value in request.POST.items() if pk_pattern.match(key)]`. | Returned values come from matching POST items and preserve iteration order. | Encoded as O4/O5/O6. |
| E6 | code search | The only `re.compile(...format(...))` occurrence under `repo/django` is this helper. | No sibling source pattern with the same issue was found in the allowed source tree. | Finding F2. |

## Formal model summary

The formal core is in:

- `fvk/mini-admin-post.k`: a mini model of scanning ordered POST entries and
  matching an escaped admin primary-key regex against keys.
- `fvk/admin-options-spec.k`: reachability-style claims for literal regex
  equivalence, selection soundness, selection completeness, and order
  preservation.

The K artifacts intentionally abstract Python's full regex engine to the
property under audit: after `escapeRegex(P)`, the regex fragment denotes the
literal string `P`. This abstraction passes the discriminator test for the
reported defect: a passing key `a+b-0-id` and a failing key `ab-0-id` remain
distinguishable when `P = "a+b"`.

## Frame conditions

The V1 patch does not change the helper signature, its caller, the queryset
validation path, the selected value order, or the existing index grammar. It
changes only whether dynamic regex fragments are interpreted as regex syntax or
literal text.

