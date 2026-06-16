# Public Evidence Ledger

## E1: Reported Empty Tuple Crash

- Source: prompt / issue in `benchmark/PROBLEM.md`
- Quote: "`IndexError: pop from empty list` for empty tuple type annotation"
- Semantic obligation: boundary case; `Tuple[()]` is in domain and must not
  raise during annotation rendering.
- Status: encoded in `SPEC.md`, `python-annotation-spec.k`, `PO1`, and `F1`.

## E2: Expected Successful Documentation Build

- Source: prompt / issue in `benchmark/PROBLEM.md`
- Quote: "Docs are built and there is `foo` with valid type annotations."
- Semantic obligation: postcondition; rendering produces valid annotation nodes
  rather than an exception or malformed delimiter sequence.
- Status: encoded in `PO1`, `PO2`, and `PO4`.

## E3: Public Hint For Empty Tuple Output Form

- Source: public hint in `benchmark/PROBLEM.md`
- Quote: "generating `Tuple[()]` in docs"
- Semantic obligation: output-form obligation; the empty tuple must be rendered
  as literal punctuation `(` followed by `)` inside the existing subscript
  brackets.
- Status: encoded in `PO1` and `C-TUPLE-EMPTY`.

## E4: Existing Non-empty Tuple Behavior

- Source: public test `repo/tests/test_domain_py.py::test_parse_annotation`
- Quote: `_parse_annotation("Tuple[int, int]")`
- Semantic obligation: frame condition; non-empty tuple slices render as
  comma-separated elements inside the subscript brackets, with no additional
  tuple parentheses.
- Status: encoded in `PO3` and `C-TUPLE-NONEMPTY`.

## E5: Existing List Literal Support

- Source: public test `repo/tests/test_domain_py.py::test_parse_annotation`
- Quote: `_parse_annotation("Callable[[int, int], int]")`
- Semantic obligation: family/boundary obligation; `ast.List` delimiters are an
  intentional supported contributor to annotation output, so the zero-element
  list member must preserve `[]`.
- Status: encoded in `PO2` and `F2`.

## E6: Existing Name Xref Behavior

- Source: public test `repo/tests/test_domain_py.py::test_parse_annotation`
- Quote: `_parse_annotation("int")` with `pending_xref`
- Semantic obligation: frame condition; names remain text during unparsing and
  become Python pending xrefs after unparsing.
- Status: encoded in `PO4`.

## E7: Unsupported Syntax Fallback

- Source: implementation of `_parse_annotation()`
- Quote: `except SyntaxError: return [make_xref(annotation)]`
- Semantic obligation: implementation-derived frame condition with no conflicting
  public intent; unsupported AST nodes remain fallback xrefs.
- Status: encoded in `PO5`.
