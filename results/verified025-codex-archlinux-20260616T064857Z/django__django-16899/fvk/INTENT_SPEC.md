# Intent Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change to Django's admin check for
`ModelAdmin.readonly_fields`, specifically `_check_readonly_fields_item()` and
the caller-provided indexed label from `_check_readonly_fields()`.

## Intent-only obligations

I-01. For an invalid `readonly_fields` entry, the `admin.E035` message must
include the indexed option path such as `readonly_fields[0]`.

I-02. For an invalid `readonly_fields` entry, the same `admin.E035` message must
include the offending configured value, called the field name in the issue.

I-03. The new wording should match the established style of neighboring admin
checks: "The value of '<option[index]>' refers to '<field name>', which ...".

I-04. The change must preserve the existing success cases: callable entries,
attributes on the `ModelAdmin`, attributes on the model class, and model fields
found by `_meta.get_field()` remain valid and produce no error.

I-05. The change must preserve existing error identity and ownership metadata:
invalid entries still produce a `checks.Error` with id `admin.E035` and
`obj=obj.__class__`.

I-06. Public documentation of `admin.E035` should describe the new message shape
once the behavior changes.

I-07. Public tests that assert the old message without the field value are
SUSPECT legacy evidence because the issue identifies that exact omission as the
bug.
