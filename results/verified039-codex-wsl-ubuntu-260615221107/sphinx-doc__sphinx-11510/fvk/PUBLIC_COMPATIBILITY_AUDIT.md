# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

| Symbol | Public surface | Compatibility result |
| --- | --- | --- |
| `sphinx.directives.other.Include.run` | Existing directive method; signature unchanged. | Compatible. Return type and delegation to `BaseInclude.run()` preserved. |
| `sphinx.directives.other._emit_source_read_on_include` | New private helper. | No public API compatibility obligation. |
| `sphinx.ext.duration.on_source_read` | Public extension event handler by import, but event callback signature unchanged. | Compatible. It now treats later include-triggered `source-read` events as part of the same document read instead of resetting the start time. |

## Public callsites and listeners

- `Include.run()` is registered as the implementation of the `include`
  directive in `setup()`; the directive name and options remain delegated to
  docutils.
- `sphinx.ext.duration` and `sphinx.ext.intersphinx` are in-tree listeners for
  `source-read`. `duration` required a small compatibility fix, recorded as
  F-002. No source change was made for `intersphinx.install_dispatcher`; the
  constructed proof does not model dispatcher stacking, so role resolution with
  intersphinx enabled remains an integration-test obligation.

## Tests

No tests were edited. New public tests are recommended in
`ITERATION_GUIDANCE.md`, but the benchmark instructions reserve tests for the
hidden suite.
