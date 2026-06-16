# SPEC

Status: constructed, not machine-checked.  No tests, Python code, or K tooling
were executed.

## Scope

The audited unit is the Python-domain type cross-reference splitter:
`PyXrefMixin.make_xrefs()` in `repo/sphinx/domains/python.py`.  The observable
under specification is the sequence of nodes returned for Python type field text:
type atoms become pending cross-reference nodes, and delimiter text remains
literal text/emphasis.

This spec covers type field content that reaches `make_xrefs()` as a single text
node from Python info fields, including:

- `:type name: ...` and inline `:param type name: ...`;
- `:vartype name: ...` and inline `:var type name: ...`;
- `:rtype: ...`;
- napoleon keyword type fields, because they use `PyTypedField`.

Directive option annotations such as `.. py:attribute:: x` with `:type:` are not
the changed path; they already use `_parse_annotation()`, whose AST unparser
handles `ast.BitOr`.

## Public Intent Ledger

IE-1, prompt, encoded:
The issue title requests "Support union types specification using |" and the
example uses `:type text: bytes | str`.  Obligation: a pipe-separated type field
must be treated as multiple acceptable types, not as one target containing a
pipe.

IE-2, project docs and prompt hints, encoded:
The docs say multiple types in a type field are linked when separated by the
word `or`, and show `:type`, `:vartype`, and `:rtype` examples.  Obligation:
the pipe change must preserve existing `or`, container punctuation, and return
type behavior.

IE-3, prompt, encoded:
The issue asks for parameters, attributes, and variables.  Obligation: the
Python-domain field classes used for parameters, variables, and returns must all
reach the same splitter, or the already-existing annotation parser must cover
the attribute option path.

IE-4, implementation compatibility, encoded:
Only Python-domain type field parsing is implicated.  Other domains also use
`TypedField` and may assign language-specific meaning to `|`.  Obligation: do
not alter generic doc field parsing or non-Python domain delimiters.

IE-5, public in-repo compatibility evidence, encoded:
Existing public fixtures include `:type moo: |test|` as a substitution-style
field.  Obligation: non-text field content must remain untouched by the new
pipe delimiter.

## Intent Specification

For every in-scope Python type field text made of nonempty type atoms separated
by existing delimiters or by a pipe delimiter:

1. Every type atom is emitted through the existing Python cross-reference path.
2. Every delimiter is preserved as literal output, including its spelling and
   surrounding whitespace.
3. The pipe delimiter family is `|` with optional surrounding whitespace.
4. Existing delimiter families remain accepted: brackets, parentheses, commas,
   the word `or`, and ellipsis.
5. Non-text type content is passed through unchanged.
6. No non-Python domain behavior changes.

## Formal Model

The formal core is in:

- `fvk/mini-python-xrefs.k`
- `fvk/python-xrefs-spec.k`

The model abstracts a type expression after delimiter recognition as a list of
segments:

- `atom(T)` means a nonempty type-name target;
- `delim(D)` means delimiter text recognized by the delimiter regex.

The modeled function is:

```text
makeXrefs(.Segments) = .XNodes
makeXrefs(atom(T) ; rest) = xref(T) ; makeXrefs(rest)
makeXrefs(delim(D) ; rest) = literal(D) ; makeXrefs(rest)
```

This abstraction is property-complete for this defect: it distinguishes the
failing pre-fix behavior `xref("bytes | str")` from the intended behavior
`xref("bytes"), literal(" | "), xref("str")`.

## Adequacy Audit

Claim `PIPE-UNION`: `bytes | str` maps to `xref("bytes")`, literal pipe text,
and `xref("str")`.  Status: pass against IE-1.

Claim `OR-FRAME`: `str or int or None` maps to three xrefs with literal `or`
delimiters.  Status: pass against IE-2.

Claim `PUNCT-FRAME`: `Tuple[str, ...]` maps to type xrefs and preserved
punctuation/ellipsis delimiters.  Status: pass against IE-2.

Compatibility claim: all changes stay in `PyXrefMixin.make_xrefs()` and do not
change `TypedField`, C, C++, JavaScript, or docutils parsing.  Status: pass
against IE-4.

Substitution frame claim: the generic transformer only calls `make_xrefs()` for
single `nodes.Text` type content; non-text content is appended unchanged.  Status:
pass against IE-5.
