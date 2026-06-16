# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and symbolic reasoning only.

## F1 - V1 fixed the reported recursive-ignore miss

Classification: code bug fixed by V1 and retained in V2.

Input:

```text
tree:
  ./.a/foo.py
  ./bar.py
command:
  pylint --recursive=y --ignore=.a .
```

Pre-fix observed behavior from the issue: both `bar.py` and `.a/foo.py` were
linted.

Expected behavior from public intent: `.a/foo.py` is not discovered because its
containing directory basename `.a` is in `--ignore`.

V2 status: `_is_ignored_file()` checks the basename against `self.config.ignore`,
and `_discover_files()` prunes ignored child directories before `os.walk()`
descends into them.

Proof obligations: O1, O2, O3.

## F2 - V1 left a prefix-based package-subtree proof obstacle

Classification: code bug found by FVK audit and fixed in V2.

Input:

```text
tree:
  ./pkg/__init__.py
  ./pkg2/__init__.py
command:
  pylint --recursive=y .
```

V1 observed by source reasoning: after `./pkg` is discovered as a package,
`skip_subtrees = ["./pkg"]`. When `os.walk()` later reaches sibling root
`./pkg2`, the check `root.startswith("./pkg")` is true, so `./pkg2` can be
skipped even though it is not a subtree of `./pkg`.

Expected behavior: both sibling package roots are yielded exactly once, because
both are unignored package directories under the requested recursive root.

V2 status: removed prefix-state subtree skipping. When a package root is yielded,
V2 clears that root's `directories` list so `os.walk()` does not descend into the
package subtree. No sibling-prefix comparison is needed, so `pkg2` is not
suppressed by `pkg`.

Proof obligations: O5.

## F3 - Default `ignore-patterns` evidence is contradictory

Classification: underspecified/ambiguous intent; no source change.

Input:

```text
tree:
  ./.a/foo.py
  ./bar.py
command:
  pylint --recursive=y .
```

Issue prose says `.a/foo.py` should be ignored even with no explicit ignore
setting because the default `ignore-patterns` is `"^\."`. The same issue quotes
help text saying the current default is `^\.#`, and `repo/pylint/lint/base_options.py`
also sets `re.compile(r"^\.#")`.

Expected behavior cannot be cleanly derived from public evidence for this
checkout. The FVK spec therefore does not change the default. It proves that
recursive discovery honors the configured ignore patterns, whatever they are.

Proof obligations: O1 plus adequacy note A1.

## F4 - `ignore-paths=.a` needs normalized discovered-path matching

Classification: code bug fixed by V1 and retained in V2.

Input:

```text
tree:
  ./.a/foo.py
  ./bar.py
command:
  pylint --recursive=y --ignore-paths=.a .
```

Observed by source reasoning: paths discovered from root `.` can be spelled
`./.a` or `./.a/foo.py`. Matching only that raw spelling against a path regex
intended for `.a` can miss the ignored path.

Expected behavior from the problem statement: `.a/foo.py` is ignored by
`--ignore-paths=.a`.

V2 status: `_is_ignored_file()` checks both the raw discovered path and
`os.path.normpath(path)`, so `./.a` is also considered as `.a` for path-pattern
matching.

Proof obligations: O1, O2, O3.

## Proof-derived findings from verify

- The constructed proof is partial correctness only. Termination of `os.walk()`
  over finite filesystems is assumed as a default-domain condition, not proved.
- The K model abstracts Python regex matching as a Boolean predicate
  `ignored(Path, IgnoreConfig)`. The proof therefore verifies that discovery
  consults and propagates the predicate correctly; it does not prove Python's
  `re.Pattern.match()` implementation.
- No test-redundancy removals are recommended. The proof was not machine-checked,
  and the task forbids editing tests.
