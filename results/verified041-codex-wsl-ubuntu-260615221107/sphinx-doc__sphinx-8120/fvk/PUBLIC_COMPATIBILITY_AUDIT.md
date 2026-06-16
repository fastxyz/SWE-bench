# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

`Sphinx._init_i18n()` changed only its local construction of `locale_dirs`.
The method is internal and its signature did not change.

## Public callsites and APIs

- `sphinx.locale.init()` signature and internal precedence semantics are
  unchanged. It still treats the list it receives as primary catalog followed
  by fallbacks.
- `Sphinx.add_message_catalog()` is unchanged and still calls
  `locale.init([locale_dir], self.config.language, catalog)`.
- Console translation initialization through `init_console()` is unchanged.
- Document catalog translation in `sphinx.transforms.i18n` is unchanged.
- HTML JavaScript translation lookup already checks user `locale_dirs` before
  built-in JS resources; V1 aligns the Python message path with that existing
  precedence shape.

## Result

No public API, virtual dispatch signature, producer/consumer data shape, or
extension override contract changed. Compatibility status: PASS.
