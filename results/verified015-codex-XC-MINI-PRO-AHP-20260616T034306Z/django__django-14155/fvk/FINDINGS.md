# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue text, local source/docs, and static reasoning only.

## F-001 - Legacy behavior reported by the issue is a real display bug

- Input: a URL pattern whose callback is `functools.partial(empty_view, template_name="template.html")`, resolved into `ResolverMatch(callback, (), {}, url_name="partial", route="partial/")`.
- Observed before V1: repr's `func=` field was derived from the partial object's class and displayed `functools.partial`; repr's `kwargs=` field was `{}`.
- Expected: repr identifies `empty_view` and exposes `template_name="template.html"`.
- Classification: code bug fixed by V1.
- Evidence: E1, E2, E3.
- Related obligations: PO-1, PO-2.

## F-002 - V1 preserves the documented dispatch triple

- Input: the same partial callback plus URL-resolved `args` and `kwargs`.
- Observed in V1 source: `self.func`, `self.args`, and `self.kwargs` are assigned before display metadata is computed and `__getitem__()` still returns those attributes.
- Expected: public `resolve()` tuple unpacking and request dispatch continue to use the original callback and URL-parsed args/kwargs.
- Classification: compatibility confirmation.
- Evidence: E4, E5, E8.
- Related obligations: PO-4.

## F-003 - Nested partials are handled rather than left as a sibling gap

- Input: `partial(partial(empty_view, template_name="template.html"), template_name="nested_partial.html")`.
- Observed in V1 source: `ResolverMatch.__init__()` loops while `view_func` is a `functools.partial`, accumulating inner positional args before outer positional args and letting outer keywords override inner keywords.
- Expected: repr reaches `empty_view` and shows the effective nested partial arguments.
- Classification: compatibility and completeness confirmation for the public nested-partial source shape.
- Evidence: E6 and Python partial composition as a named default-domain assumption.
- Related obligations: PO-2.

## F-004 - Direct manual construction with non-tuple args is outside the audited resolve-domain

- Input: a manually-created `ResolverMatch(partial(view, "x"), ["url"], {})`.
- Observed in V1 source: repr metadata construction assumes resolver-shaped tuple positional args when concatenating partial args with URL args.
- Expected in audited domain: Django's URL resolvers supply tuple args.
- Classification: out-of-scope compatibility note, not a V2 blocker.
- Evidence: E7; docs describe `ResolverMatch` as returned by `resolve()`, not as a broad manual-construction API.
- Related obligations: PO-4 domain clause.

## F-005 - Proof and tests were not executed by design

- Input: FVK verification commands and Django tests.
- Observed: no tests, Python code, `kompile`, `kast`, or `kprove` were run.
- Expected: commands are written into artifacts for later execution; test removal is not recommended without machine checking.
- Classification: honesty-gate note.
- Evidence: FVK `verify.md` and the user's no-execution constraint.
- Related obligations: PO-6.
