# Findings

Status: constructed, not machine-checked.

## F-001: Functional V1 code satisfies the issue pipeline

Classification: confirmed behavior.

Input -> observed vs expected:

```text
some_list = [raw("<b>"), safe("<i>")]
template = {{ some_list|escapeseq|join:"," }} with autoescape off

Observed from V1 source:
escapeseq(some_list)
  = [safe(htmlEscape("<b>")), safe("<i>")]
join(..., autoescape=False)
  = safe(htmlEscape("<b>") + "," + "<i>")

Expected from prompt:
each item is escaped before join
```

Trace: PO-2, PO-3, and PO-4.

Decision: keep the V1 functional implementation unchanged.

## F-002: V1 lacked public docs for the new built-in filter

Classification: public documentation gap, fixed in V2.

Input -> observed vs expected:

```text
public docs lookup for built-in filter `escapeseq`

Observed in V1:
no `.. templatefilter:: escapeseq` entry in docs/ref/templates/builtins.txt

Expected:
new public built-in filters are documented with the built-in filters
```

Trace: ledger E8 and PO-6.

Decision: add a targeted `escapeseq` docs entry next to `escape`.

## F-003: Exact HTML replacement behavior is delegated to existing Django code

Classification: trusted dependency / proof scope boundary.

Input -> observed vs expected:

```text
item = raw("<&>")

Observed in V1 source:
escapeseq calls conditional_escape(item)

Expected from issue:
the item is escaped according to Django's existing `escape` semantics
```

Trace: PO-3.

Decision: do not reimplement or alter the HTML escaping table in
`escapeseq`; using `conditional_escape()` is the correct dependency boundary.

## F-004: Non-iterable behavior is not newly specified

Classification: domain assumption / no code change.

Input -> observed vs expected:

```text
value = non-iterable object

Observed from V1 source:
list comprehension raises the normal iteration error, matching the lack of
special handling in `safeseq`

Expected from prompt:
behavior is specified for a sequence/list, not for non-iterable values
```

Trace: domain assumptions and PO-2.

Decision: do not add a broad exception-swallowing fallback to `escapeseq`.

## F-005: Proof artifacts are constructed only

Classification: process honesty gate.

Input -> observed vs expected:

```text
K toolchain execution

Observed:
not run, per benchmark instructions

Expected:
artifacts include commands and are labeled constructed, not machine-checked
```

Trace: PO-7.

Decision: keep all test-removal and machine-verification claims conditional on
future execution of the emitted commands.
