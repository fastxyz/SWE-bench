# FVK Iteration Guidance

## Code Decision

Do not keep V1 unchanged. The FVK audit found two concrete issues:

- F-001: V1 introduced a base `Documenter` virtual hook. V2 moves inherited
  fallback to `AttributeDocumenter.add_content()`.
- F-002: V1 could attach a base comment to a subclass attribute that overrides
  the base member. V2 adds MRO owner gating.

After those revisions, no additional source change is justified by the public
intent and proof obligations.

## Tests to Add Later

Do not edit tests in this benchmark task. For a normal development pass, add or
confirm tests for:

- `autoclass` with `:inherited-members:` includes a base class data attribute
  documented by a `#:` comment.
- The generated inherited attribute content includes the base comment text.
- Explicit `autoattribute:: Subclass.attr` renders the base comment when the
  attribute is inherited.
- The same behavior works when the base class is defined in another module.
- A subclass override without its own comment does not inherit the base comment.
- Multiple inheritance uses the first MRO owner, not a later base with a comment.
- Existing direct instance comment behavior remains unchanged.

## Tests to Keep

Keep integration/end-to-end autodoc tests, public API compatibility tests, and
any tests around inherited instance-only attributes. The proof does not cover
those as redundant.

## Conditional Test Redundancy

No test should be removed from this project as part of this task. If the K sketch
is replaced with runnable K and `kprove` returns `#Top`, simple unit tests that
only re-check the in-domain inherited class/data attribute cases may become
redundant. That recommendation is conditional on machine checking and normal CI.

## Future Questions

If the project later wants inherited instance-only comment members under
`:inherited-members:`, ask explicitly:

"Should `Base.__init__` comment-only `self.attr` entries be synthesized into
subclasses under `:inherited-members:`, and how should `:inherited-members: Base`
cutoff filtering apply to such instance-only comments?"

