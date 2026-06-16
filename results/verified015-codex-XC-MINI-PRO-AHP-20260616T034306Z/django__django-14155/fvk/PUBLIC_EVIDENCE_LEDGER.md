# Public Evidence Ledger

## E1 - Problem statement: partial repr must reveal underlying function

- Source: `benchmark/PROBLEM.md`
- Quote: "ResolverMatch.__repr__() doesn't handle functools.partial() nicely."
- Obligation: For partial callbacks, repr cannot identify the callback only as `functools.partial`.
- Status: Encoded by PO-1 and K claims `PARTIAL-REPR` / `NESTED-PARTIAL-REPR`.

## E2 - Problem statement: partial repr must reveal bound arguments

- Source: `benchmark/PROBLEM.md`
- Quote: "it doesn't reveal the underlying function or arguments provided."
- Obligation: Repr must include partial-bound positional and keyword arguments.
- Status: Encoded by PO-2 and K claims `PARTIAL-REPR` / `NESTED-PARTIAL-REPR`.

## E3 - Problem hint: unwrap partials in ResolverMatch initialization

- Source: `benchmark/PROBLEM.md`
- Quote: "we can simply unwrap functools.partial objects in ResolverMatch.__init__()."
- Obligation: The repair belongs in `ResolverMatch.__init__()` metadata construction, not only in an ad hoc repr branch.
- Status: Encoded by the implementation and PO-1/PO-2.

## E4 - Django docs: `func`, `args`, `kwargs` are public runtime attributes

- Source: `repo/docs/ref/urlresolvers.txt`
- Quote: "`ResolverMatch.func` The view function that would be used to serve the URL"; "`ResolverMatch.args` The arguments that would be passed to the view function, as parsed from the URL"; "`ResolverMatch.kwargs` The keyword arguments that would be passed to the view function, as parsed from the URL."
- Obligation: The V2 fix must preserve public attributes used for dispatch and inspection.
- Status: Encoded by PO-4 and K claim `FRAME-PUBLIC-TRIPLE`.

## E5 - Django docs: tuple unpacking is public compatibility

- Source: `repo/docs/ref/urlresolvers.txt`
- Quote: "`func, args, kwargs = resolve('/some/path/')`"
- Obligation: `ResolverMatch.__getitem__()` must continue returning the original public triple.
- Status: Encoded by PO-4 and K claim `FRAME-PUBLIC-TRIPLE`.

## E6 - Django tests: nested partial URL patterns exist in public source

- Source: `repo/tests/urlpatterns_reverse/views.py`
- Quote: `empty_view_nested_partial = partial(empty_view_partial, template_name="nested_partial.html")`
- Obligation: Nested partials are a public source shape that should not regress.
- Status: Encoded by PO-3 and K claim `NESTED-PARTIAL-REPR`.

## E7 - Implementation: resolver-produced args are tuples

- Source: `repo/django/urls/resolvers.py`
- Quote: `args = () if kwargs else match.groups()` and `return path[match.end():], (), kwargs`
- Obligation: The proof domain for URL-created matches can assume tuple args.
- Status: Recorded as domain evidence; not used to alter manual-constructor behavior.

## E8 - Implementation: request dispatch unpacks `ResolverMatch`

- Source: `repo/django/core/handlers/base.py`
- Quote: `callback, callback_args, callback_kwargs = self.resolve_request(request)`
- Obligation: The fix must not make repr correctness depend on mutating the dispatch triple.
- Status: Encoded by PO-4 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

