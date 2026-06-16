# Intent Specification

Status: constructed from public evidence, not machine-checked.

## Required behavior

I-1. A project may provide an internal Sphinx message catalog at
`locale/<language>/LC_MESSAGES/sphinx.mo`, discovered through `locale_dirs`.

I-2. For the `sphinx` text domain, an intentionally provided project catalog
entry must override an existing built-in translation for the same message and
language. The issue's concrete examples are `Fig. %s -> Foobar %s` and
`Listing %s -> Whatever %s` for `language = 'da'`.

I-3. A project catalog may be partial. If a message is not present in project
catalogs, Sphinx should still fall back to existing built-in translations so
the rest of the output remains localized.

I-4. Project `locale_dirs` order should remain meaningful: earlier configured
project locale directories have precedence over later configured project
locale directories.

I-5. When no project locale directory supplies the message, V1 should preserve
the pre-existing built-in fallback order. Before the fix, Sphinx passed the
system gettext location (`None`) before `sphinx/locale`; that relative ordering
is not contradicted by the issue and is a frame condition.

I-6. The fix should not change public APIs, public method signatures, test
files, or behavior of extension message catalogs registered through
`add_message_catalog()`.

## Domain assumptions

D-1. The relevant language is configured (`config.language` is not `None`), so
`_init_i18n()` follows the translated-message path.

D-2. The project locale directory exists for the configured language, so
`CatalogRepository.locale_dirs` yields it. This is exactly the issue's
`locale/da/LC_MESSAGES` case.

D-3. `gettext.translation()` and `NullTranslations.add_fallback()` implement
first-hit fallback: a catalog answers its own messages first and delegates to
fallbacks only when a message is missing.
