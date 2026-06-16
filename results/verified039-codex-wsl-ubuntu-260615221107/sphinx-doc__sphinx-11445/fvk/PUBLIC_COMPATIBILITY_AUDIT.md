# PUBLIC COMPATIBILITY AUDIT

Status: constructed, not machine-checked.

## Changed Symbols

`sphinx.util.rst.prepend_prolog(content, prolog)`

- Signature unchanged.
- Return behavior unchanged: mutates `content` in place and returns `None`.
- Public callers unchanged. `RSTParser.decorate()` still calls
  `prepend_prolog(content, self.config.rst_prolog)`.
- Existing ordinary prolog insertion and docinfo insertion behavior are covered
  by PO-005 and C-NO-DOCINFO.

`sphinx.util.rst._is_section_title(content, pos)`

- New private helper.
- No public caller or override contract.
- No compatibility obligation beyond matching the local section-title predicate.

## Unchanged Symbols

`sphinx.util.rst.append_epilog()` was not modified.

`sphinx.parsers.RSTParser.decorate()` was not modified.

## Result

No public API, virtual dispatch, subclass override, producer/consumer protocol,
or storage format incompatibility was found.

