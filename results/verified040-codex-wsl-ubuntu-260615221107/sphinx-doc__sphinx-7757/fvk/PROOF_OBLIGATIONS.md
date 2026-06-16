# Proof Obligations

Status: constructed for audit; not machine-checked.

## PO-001: Align Defaults Across Combined Positional Parameters

Statement:

For a parsed Python signature with positional-only list `P`, ordinary
positional list `A`, and AST defaults list `D`, where
`len(D) <= len(P) + len(A)`, the implementation must left-pad `D` with
`Parameter.empty` until it has length `len(P) + len(A)`.

Proven by:

- `fvk/signature-from-str-spec.k`, `CLAIM-ALIGN-GENERAL`
- V1 source lines in `signature_from_str()`:
  `defaults = list(args.defaults)` followed by inserting `None` until
  `len(defaults) == len(posonlyargs) + len(args.args)`

Status: discharged by constructed proof.

## PO-002: Assign Padded Defaults To Positional-Only Parameters

Statement:

For each positional-only parameter index `i`, the created
`inspect.Parameter` must receive `ast_unparse(defaults[i])` if that padded slot
has a default, otherwise `Parameter.empty`.

Proven by:

- `fvk/signature-from-str-spec.k`, `CLAIM-ALIGN-GENERAL`
- V1 positional-only loop:
  `default = ast_unparse(defaults[i]) or Parameter.empty`

Status: discharged by constructed proof.

## PO-003: Assign Padded Defaults To Ordinary Positional Parameters

Statement:

For each ordinary positional parameter index `j`, the created
`inspect.Parameter` must receive `ast_unparse(defaults[len(P) + j])` if that
padded slot has a default, otherwise `Parameter.empty`.

Proven by:

- `fvk/signature-from-str-spec.k`, `CLAIM-ALIGN-GENERAL`
- V1 ordinary positional loop:
  `default = ast_unparse(defaults[i + len(posonlyargs)]) or Parameter.empty`

Status: discharged by constructed proof.

## PO-004: Issue Example

Statement:

For `(a, b=0, /, c=1)`, the parsed lists are `P=[a,b]`, `A=[c]`, and
`D=[0,1]`; padding gives `[empty,0,1]`; the result must have `b.default == '0'`
and `c.default == '1'`.

Proven by:

- `fvk/signature-from-str-spec.k`, concrete issue claim
- PO-001, PO-002, and PO-003

Status: discharged by constructed proof.

## PO-005: Rendering Shows Non-Empty Defaults

Statement:

If `_parse_arglist()` receives an `inspect.Parameter` with
`default != Parameter.empty`, it must emit a default value node for that
parameter.

Proven by:

- Source inspection of `_parse_arglist()` in `repo/sphinx/domains/python.py`
- The branch `if param.default is not param.empty:` appends the default inline
  node.

Status: discharged by source-level proof.

## PO-006: No-Positional-Only Regression

Statement:

When `len(P) == 0`, the new alignment must reduce to the old behavior for
ordinary positional parameters: pad `D` to `len(A)` and index ordinary argument
`j` at `defaults[j]`.

Proven by:

- `fvk/signature-from-str-spec.k`, no-positional-only regression claim
- Algebraic substitution `len(P) = 0` in PO-003

Status: discharged by constructed proof.

## PO-007: Frame Unrelated Parameter Forms

Statement:

Varargs, keyword-only arguments, kwargs, annotations, return annotations, and
parser error behavior must be unchanged.

Proven by:

- V1 diff touches only positional default alignment.
- Existing source blocks for varargs, keyword-only arguments, kwargs,
  annotations, and return annotation are unchanged.

Status: discharged by static diff proof.

## PO-008: Public API Compatibility

Statement:

`signature_from_str()` and `_parse_arglist()` must keep their public signatures
and return shapes.

Proven by:

- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- V1 diff does not change function definitions or callsites.

Status: discharged by compatibility audit.
