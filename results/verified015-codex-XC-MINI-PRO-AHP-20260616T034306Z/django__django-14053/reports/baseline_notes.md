# Baseline Notes

## Root Cause

`HashedFilesMixin.post_process()` performs an initial pass over all collected
files and then repeats processing for files whose contents can contain
replaceable references, such as CSS files. Before this change, the method yielded
the result of every pass directly to callers. That exposed internal intermediate
hash names for adjustable files and yielded the same original path multiple
times, even when later passes were only checking that substitutions had
stabilized.

`collectstatic` treats each yielded successful result as one post-processed file,
so these duplicate yields inflated the reported post-processing count. Subclasses
or wrappers consuming the generator could also perform duplicate work on the same
original file.

## Changed Files

`repo/django/contrib/staticfiles/storage.py`

Adjusted `HashedFilesMixin.post_process()` so successful results for adjustable
files are stored during the internal multi-pass loop and yielded only once after
the final stable hashed name is known. Non-adjustable files are still yielded
from the initial pass because they are processed only once.

The method still yields exception results immediately. This preserves the
existing collectstatic failure path where the failing original path is reported
as soon as `_post_process()` detects an error. If the maximum number of
post-processing passes is exceeded, the method yields the existing `All`
`RuntimeError` result and stops without yielding partial adjustable-file results.

`reports/baseline_notes.md`

Added this report as required by the benchmark task.

## Assumptions

The intended public contract is that each original file should be yielded at
most once per `post_process()` run, with adjustable files represented by their
final hashed name rather than by intermediate names generated while references
settle.

The internal multi-pass behavior remains necessary for nested references and
should not be removed. The change only affects which successful results are
reported to callers.

I did not run tests or any code because the task explicitly says this session has
no execution environment and forbids running tests or code.

## Alternatives Considered

One option was to yield only the first result for each adjustable file. I
rejected that because the first pass can produce an intermediate hash before
nested references have stabilized, which is the implementation detail the issue
asks not to expose.

Another option was to yield every unique hashed filename. I rejected that because
the issue is about reporting work per original collected file, and intermediate
hashed files are not separate original inputs to `collectstatic`.

A broader refactor of `_post_process()` was unnecessary. The duplicate-yield
problem is in the outer generator policy, not in the lower-level pass that saves
files and updates `hashed_files`.
