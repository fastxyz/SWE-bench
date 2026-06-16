# FVK Proof Obligations

Status: constructed, not machine-checked.

## O0: Branch Domain

Statement: The edited branch applies exactly to inline literal nodes that have
class `code` and a non-empty `language` value.

Evidence:

* `roles.code_role()` creates `nodes.literal(..., classes=classes,
  language=language)`.
* The reproducer defines `.. role:: python(code) :language: python`.
* `visit_literal()` enters the highlighted branch only after excluding title,
  keyboard, and non-code / no-language literals.

Discharge: satisfied by static control-flow review of `visit_literal()`.

## O1: Opening Boundary Is Hidden

Statement: The formatter newline immediately after the replacement opening
wrapper must not become a TeX-visible space.

Formal shape:

```text
beginVerbatim(Body) -> \sphinxcode{\sphinxupquote{%
Body...
```

Discharge: V1 changes the replacement string from
`\sphinxcode{\sphinxupquote{` to `\sphinxcode{\sphinxupquote{%`. In TeX, `%`
comments the rest of the physical input line, including the formatter newline,
so it contributes no interword space.

Finding trace: F1, F3.

## O2: Closing Boundary Is Hidden

Statement: The formatter newline between highlighted content and the closing
inline wrapper must not become a TeX-visible space.

Formal shape:

```text
Body%
}}
```

Discharge: after stripping `\end{Verbatim}`, V1 applies
`hlcode = hlcode.rstrip(CR) + '%' + CR`. This removes formatter newline
characters at the end of the highlighted body segment, places `%` immediately
after the body, and then starts the closing braces on the next line. TeX ignores
the line ending after `%` and the closing braces remain active.

Finding trace: F1, F3.

## O3: Highlighted Body Preservation

Statement: The fix must preserve the highlighted token stream `Body`; it may
remove only formatter-introduced wrapper line endings and add TeX comments
outside the body.

Discharge: V1 does not alter `node.astext()`, highlighter selection, lexer
options, or Pygments token output. `rstrip(CR)` removes only newline characters
at the boundary after `\end{Verbatim}` has been stripped; source-intended inline
spaces inside `Body` are retained.

Precondition: `Body` is the inline highlighted content excluding Pygments'
wrapper line endings. This matches the existing writer assumption that the
LaTeX formatter output can be adapted by replacing the opening `Verbatim`
command and stripping the `\end{Verbatim}` trailer.

Finding trace: F3.

## O4: Non-target Frame Preservation

Statement: The change must not alter non-highlighted inline literals, keyboard
literals, title literals, or literal blocks.

Discharge: V1 edits only the branch after:

```python
lang = node.get("language", None)
if 'code' not in node['classes'] or not lang:
    ...
```

`visit_literal_block()` and the earlier title / keyboard / plain literal
branches are unchanged.

Finding trace: F4.

## O5: Public Compatibility

Statement: The patch must not change public APIs, signatures, node attributes,
or extension-facing protocols.

Discharge: the diff changes only string assembly inside `visit_literal()`.
There are no signature changes, no new parameters, no changed return type, and
no changed node shape.

Finding trace: F4.

## O6: Machine-check Honesty

Statement: The proof must be labeled constructed, not machine-checked, and the
commands to check it later must be recorded without executing them now.

Discharge: `fvk/PROOF.md` includes the commands and states they were not run.

Finding trace: F5.
