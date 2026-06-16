# Baseline Notes

## Root cause

Python doc field type text is converted into cross-reference nodes by
`PyXrefMixin.make_xrefs()` in `sphinx/domains/python.py`.  That method already
splits type expressions on brackets, parentheses, commas, ellipses, and the word
`or`, so `str or int` and `Union[str, int]` are linked as separate type names.
It did not recognize the pipe operator as a delimiter, so `bytes | str` was
handled as one target named `bytes | str` instead of two targets with literal
pipe punctuation between them.

## Files changed

`repo/sphinx/domains/python.py`

Extended the existing delimiter regular expression in `PyXrefMixin.make_xrefs()`
to include `|` with optional surrounding whitespace.  This keeps the existing
type-field parsing path intact while allowing pipe-separated union members to be
linked individually.  Because `PyTypedField`, `PyField`, and napoleon's keyword
field patch use this mixin, the change applies to Python parameter, variable,
return, and keyword type fields that pass plain text type expressions through
this method.

## Assumptions and alternatives

I assumed the requested behavior is for Python-domain type field parsing, because
the issue example uses `:param:` and `:type:` docstring fields and the Python
domain already contains the analogous `or` and `Union[...]` splitting logic.

I considered changing the generic `TypedField` implementation, but rejected that
because other domains such as C, C++, and JavaScript can use `|` with
domain-specific meanings.  Keeping the change in the Python-domain override
avoids altering non-Python field semantics.

I also considered replacing the regex splitter with a full Python annotation
parser.  That would be a larger behavioral change and would risk affecting the
existing permissive parsing of field-list type text.  Extending the existing
delimiter list is the minimal change that matches the established implementation.

No tests were run, per the task instruction not to run tests or code.
