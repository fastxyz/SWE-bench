# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public behavior

Symbol: `django.contrib.admin.checks.BaseModelAdminChecks._check_readonly_fields_item`.

Change: the `admin.E035` message for invalid `readonly_fields` entries now says
the indexed option path "refers to" the invalid field value before describing why
the value is invalid.

Compatibility status: intentional public behavior change. The issue requests
this change because the old message was less informative than neighboring admin
checks.

## API and dispatch shape

The function signature is unchanged. No new arguments are passed through virtual
dispatch, no return type shape changes, and no producer/consumer protocol changes
were introduced. The return remains a list of `checks.Error` objects or an empty
list.

## Public docs

The checks reference documentation for `admin.E035` was updated to match the new
message shape.

## Public tests

Existing public tests under `repo/tests/admin_checks/tests.py` assert the old
message. Per the benchmark instructions, test files were not edited. Per the FVK
intent-evidence rules, those expectations are SUSPECT legacy evidence because
they encode the behavior reported as buggy.
