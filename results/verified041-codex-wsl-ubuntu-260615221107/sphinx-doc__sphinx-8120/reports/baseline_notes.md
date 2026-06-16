# Baseline Notes

## Root cause

Sphinx initialized its internal message catalog with locale directories in this
order:

1. the system gettext location (`None`)
2. Sphinx's bundled locale directory
3. project-configured `locale_dirs`

`sphinx.locale.init()` merges catalogs using gettext fallbacks. The first loaded
catalog is queried first, and later catalogs are only used for missing messages.
As a result, `locale/<language>/LC_MESSAGES/sphinx.mo` from a project could fill
missing entries, but it could not override messages already present in Sphinx's
bundled catalog. That matches the reported Danish case: the generated project
catalog existed, but entries such as `Fig. %s` and `Listing %s` were shadowed by
the bundled `da` catalog.

## Files changed

`repo/sphinx/application.py`

Changed `_init_i18n()` so project locale directories are passed to
`locale.init()` before the existing system and bundled fallback locations. This
preserves fallback behavior for messages absent from a project catalog while
allowing intentionally supplied project `sphinx.mo` entries to override built-in
translations.

`reports/baseline_notes.md`

Added this required explanation of the root cause, changed files, assumptions,
and rejected alternatives.

## Assumptions and alternatives considered

I assumed `locale_dirs` should have override precedence for the `sphinx` text
domain because the configuration documentation describes it as the place to add
internal message catalogs, and the issue explicitly expects intentional project
catalog entries to replace packaged translations while falling back for the rest.

I considered changing `sphinx.locale.init()` so later catalogs override earlier
ones. I rejected that because the helper already treats the order it receives as
primary-then-fallback, and changing it would affect extensions and direct callers
more broadly than this bug requires.

I also considered changing only documentation to describe the existing behavior.
I rejected that because the existing behavior makes project-provided internal
message catalogs unable to override packaged translations for normal non-English
languages, which is the surprising behavior reported in the issue.

No tests or project code were run, per the benchmark instructions.
