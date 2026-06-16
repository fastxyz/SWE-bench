# Public Evidence Ledger

Status: constructed from public inputs, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | Problem statement | "it should be possible to add a file `locale/<language>/LC_MESSAGES/sphinx.mo` to the source dir ... and through that change translations or add additional translation" | Project `locale_dirs` catalogs are intended contributors to internal `sphinx` messages. | Encoded in SPEC SO-1 and K claim `PROJECT-OVERRIDES`. |
| E-2 | Problem statement | "`locale/da/LC_MESSAGES/sphinx.mo` is created ... but the translations are not used. The translations from the official `da` translation is used." | Existing built-in translations must not shadow a project catalog entry for the same message. | Encoded in SPEC SO-1; V0 recorded as failing behavior in FINDINGS F-001. |
| E-3 | Problem statement | Expected labels should be `Foobar 1` and `Whatever 1`. | Concrete override examples for `Fig. %s` and `Listing %s`. | Encoded as representative messages in SPEC SO-1 and FINDINGS F-001. |
| E-4 | Public hint | "`locale_dirs` ... is only used if failed to look the message up from the system's message catalog" and "better to override the system values with the intentionally provided `sphinx.mo` file." | Project catalogs must precede built-in/system catalogs in the lookup order. | Encoded in SPEC SO-1 and PROOF_OBLIGATIONS PO-1. |
| E-5 | Documentation | `locale_dirs` are "Directories in which to search for additional message catalogs" and internal messages use `./locale/{language}/LC_MESSAGES/sphinx.mo`. | Project catalogs must be included for the `sphinx` text domain, not only document catalogs. | Encoded in SPEC SO-1. |
| E-6 | Existing source | `locale.init()` loads catalogs in the order supplied and uses `translator.add_fallback(trans)` for later catalogs. | Directory order is a winner/precedence property: the first catalog containing a message wins. | Used as implementation evidence in PROOF_OBLIGATIONS PO-2. |
| E-7 | Existing source | HTML translation JS candidates search `self.config.locale_dirs` before bundled/system JS files. | Adjacent internal-message resource loading already gives user locale resources priority. | Supporting evidence for SPEC SO-1; not an independent API requirement. |
| E-8 | Existing source | V0 passed `[None, path.join(package_dir, 'locale')] + list(repo.locale_dirs)`. | Built-in fallback order was system gettext location before bundled package locale. | Preserved by SPEC SO-3 and PROOF_OBLIGATIONS PO-5. |
| E-9 | Existing source | `add_message_catalog()` still calls `locale.init([locale_dir], ...)` and no signature changed. | Extension catalog API behavior should remain unchanged. | Encoded in PUBLIC_COMPATIBILITY_AUDIT and PROOF_OBLIGATIONS PO-6. |
