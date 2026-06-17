# Formal Spec English

Status: constructed, not machine-checked.

K-001: `isProtocolRelativeURL(U)` returns true when `U`, after dropping any leading C0 control or space characters, starts with two authority separators. Each separator may be `/` or `\`.

K-002: `prepare(U)` returns `rejectInvalid` for every `U` where `isProtocolRelativeURL(U)` is true.

K-003: `prepare(U)` returns `parseWithFallback` for representative non-authority relative inputs where `isProtocolRelativeURL(U)` is false, including an input beginning with an ordinary non-separator character and an input beginning with one separator followed by a non-separator.

K-004: The proof model is intentionally local to the Node HTTP adapter decision after `buildFullPath`; it does not prove browser adapter behavior, redirect behavior, proxy behavior, transport creation, or termination/performance.

