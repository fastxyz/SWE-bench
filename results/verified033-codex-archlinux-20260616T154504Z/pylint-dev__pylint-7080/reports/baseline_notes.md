## Root cause

`ignore-paths` patterns are normalized when they are parsed so that a user can
write either Posix or Windows separators. Recursive discovery can still hand
module expansion a candidate path with mixed separators, especially on Windows
when the input argument uses a trailing forward slash such as `src/`. A path like
`src/gen\about.py` does not match the all-Posix `^src/gen/.*$` alternative or the
all-Windows alternative, so the file is linted even though the configured pattern
should ignore it.

There was a second related gap for package directories: expansion checked the
directory argument before resolving it to `__init__.py`. A pattern intended to
ignore files under a directory, such as `^src/gen/.*$`, can match the resolved
package file while not matching the bare package directory.

## Changed files

`repo/pylint/lint/expand_modules.py`

- Added path-aware ignore matching that first preserves the existing raw regex
  behavior, then retries against a normalized Posix-style path.
- Routed `ignore-paths` checks through that path-aware helper.
- Reused `_is_ignored_file` for discovered submodules so basename, basename
  regex, and path regex ignore handling stay consistent.
- Added a check after resolving a module or package to its real file path, so
  ignored package `__init__.py` files are skipped before a module description is
  emitted.

## Assumptions and rejected alternatives

I assumed `ignore-paths` should continue to accept both Windows and Posix-style
patterns as documented, and that anchored relative patterns like `^src/gen/.*$`
should match recursively discovered files when the command is run from the
project root.

I considered changing recursive discovery in `pylinter.py` to filter every
yielded file directly. I rejected that as the primary fix because module
expansion is the central place that already applies ignore rules to files,
packages, and module names. Fixing expansion handles recursive discovery without
duplicating the ignore semantics in another layer.

I also considered changing the option parser to generate regexes that match
mixed path separators. I rejected that because the parser already normalizes
user input; the missed case is the runtime candidate path. Normalizing the
candidate before matching is more targeted and avoids expanding every configured
regex into additional variants.
