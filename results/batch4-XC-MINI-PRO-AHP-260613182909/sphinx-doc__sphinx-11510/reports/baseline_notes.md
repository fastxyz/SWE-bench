# Baseline notes — sphinx-doc__sphinx-11510

## Issue

A `source-read` handler (e.g. one that turns `&REPLACE_ME;` into `REPLACED`)
transforms a file when it is built as a *standalone* document, but the same
transformation is missing from the copy of that file that is inlined into a
parent document via the `.. include::` directive. In the reproducer, `index.rst`
includes `something-to-include.rst`; the parent's own `&REPLACE_ME;` (read through
the normal path) is replaced, but the `&REPLACE_ME;` coming from the *included*
file survives into `index.html` untouched.

## State of the code at the base commit

The base commit (`6cb783c`) **already contains** the machinery for emitting
`source-read` on included files — `Include.run()` in
`sphinx/directives/other.py` installs a `_insert_input` wrapper around
docutils' `StateMachine.insert_input()`, gated on there being a `source-read`
listener — together with the matching `CHANGES` entry and the `appapi.rst`
documentation. So the defect is not a missing feature but a bug in this existing
implementation that makes it fail for exactly the scenario the issue describes.

## Root cause

Before emitting the event, `_insert_input` did this **unconditionally**:

```python
text = "\n".join(include_lines[:-2])                      # drop last two lines
...
include_lines = text.splitlines() + include_lines[-2:]    # re-attach them
```

The slice assumes docutils *always* appends two end-of-file marker lines (an
empty line and a `.. end of ...` comment) to the included content. That
assumption is not reliable across the supported docutils range
(`docutils>=0.18.1,<0.21`): in the code path the reproducer hits, the content
arrives **without** those markers, so `include_lines[:-2]` strips the last two
lines of *real content* instead.

Those two stripped lines are then re-attached **unmodified** via
`+ include_lines[-2:]`, so they are never passed to the `source-read` handler.
The included file in the reproducer is

```
Testing
=======

&REPLACE_ME;
```

i.e. `['Testing', '=======', '', '&REPLACE_ME;']`. The event therefore only
receives `['Testing', '=======']`; `&REPLACE_ME;` lives in the dropped final two
lines, is reinserted verbatim, and ends up untransformed in `index.html` — which
is precisely the reported symptom (parent's own `&REPLACE_ME;` replaced, the
included one not).

## Fix

File changed: `sphinx/directives/other.py` (`Include.run._insert_input`).

The marker stripping is made **conditional**. The last two lines are treated as
docutils markers only when they actually look like them — an empty line followed
by a line that begins with `.. end of ` (which matches the documented
end-of-inclusion / end-of-inserted-text comment regardless of its exact
wording). Otherwise the **entire** included content is sent through the event so
that no source line is ever silently dropped:

```python
if (len(include_lines) >= 2
        and include_lines[-2] == ''
        and include_lines[-1].startswith('.. end of ')):
    content_lines, markers = include_lines[:-2], include_lines[-2:]
else:
    content_lines, markers = include_lines, []
text = "\n".join(content_lines)
...
include_lines = text.splitlines() + markers
```

Behaviour:

* **Markers absent** (the failing case): the whole content, including the
  trailing `&REPLACE_ME;`, reaches `source-read`; the replacement now appears in
  the parent's output.
* **Markers present**: identical to before — markers are kept out of the event
  and re-attached afterwards. So the change is a strict improvement: it does not
  alter the already-working path, it only repairs the path where the markers do
  not exist.

`docname` is left as `self.env.path2doc(source)`, which matches the documented
contract in `doc/extdev/appapi.rst` ("*docname* set to the name of the included
document (or `None` when it is not a document of the project)"). The listener
gate and the `<...>` / `:literal:` / `:code:` / `:parser:` behaviour are
unchanged, so non-using builds and literal/code includes are unaffected.

## Assumptions

* When docutils *does* append the trailing markers, the comment line starts with
  `.. end of ` (covering both `.. end of inserted text` and
  `.. end of inclusion from "..."`). If a future/other docutils used a different
  wording, the detection would simply fall through to the "no markers" branch:
  the marker comment would then be passed through as inert text (it renders as a
  comment), so the change still degrades safely and never drops content.
* Real included content does not normally end with a blank line followed by a
  `.. end of ...` comment, so the heuristic does not mis-fire on genuine content.
* Only the rST-source path of the include directive reaches `insert_input`, and
  the patch remains gated on a `source-read` listener being registered.

## Alternatives considered and rejected

* **Leave the code unchanged** (the previous report's conclusion that the
  unconditional `[:-2]` is always safe). Rejected: it relies on docutils always
  emitting exactly two trailing marker lines, which does not hold on the path the
  reproducer exercises, so the last lines of an included file are dropped from
  the event and the reported bug persists.
* **Unconditionally drop the slice** (`text = "\n".join(include_lines)` /
  `include_lines = text.splitlines()`, i.e. the community monkey-patch from the
  issue). This also fixes the bug, but when the markers *are* present it would
  start exposing the internal `.. end of ...` comment to user handlers, changing
  the established behaviour. The conditional form fixes the bug while preserving
  the existing marker-hiding behaviour, and is behaviourally identical to this
  option in the failing (no-markers) case.
* **Change the event docname to `self.env.docname`** (the parent document).
  Rejected: the documentation explicitly says the docname is that of the
  *included* document and is `None` for non-project files — exactly
  `path2doc(source)`.
* **Switch `text.splitlines()` to `text.split("\n")`** for byte-exact
  round-tripping of trailing blank lines. Rejected as out of scope; it does not
  affect the reported bug and `splitlines()` is the established behaviour here.
* **Update `CHANGES`/docs.** Not needed: the existing `#11510` changelog entry
  and the `source-read` documentation already describe the intended behaviour;
  this change makes the implementation actually deliver it.
