# Public Evidence Ledger

## E1 - Reported bug

- Source: prompt / issue.
- Quote: "I have 2 view only permissions... my user with view only permissions can now add or remove these items at will!"
- Obligation: target-view-only and parent-view-only users must not be able to add/remove auto-created m2m through inline rows.
- Status: encoded in `SPEC.md`, `admin-inline-permissions-spec.k` claims `(VIEW-ONLY-WRITE-FALSE)` and `(VIEW-ONLY-POST-PRESERVES)`.

## E2 - Reproduction shape

- Source: prompt / issue.
- Quote: `model = Report.photos.through` with `admin.TabularInline`.
- Obligation: the audited unit is the auto-created intermediary model path in `InlineModelAdmin`.
- Status: encoded in `SPEC.md` and scoped K semantics.

## E3 - Correct behavior comparison

- Source: prompt / public hint.
- Quote: "When the M2M is handled as a normal field, rather than an inline, the behaviour is correct."
- Obligation: the inline path must not be more permissive than view-only m2m field handling.
- Status: encoded as write preservation when target `change` is absent.

## E4 - Admin inline hook contract

- Source: public docs in `repo/docs/ref/contrib/admin/index.txt`.
- Quote: `InlineModelAdmin.has_add_permission()` should return true iff adding an inline object is permitted; equivalent text exists for change and delete.
- Obligation: the fix must make these hooks return false for target-view-only auto-created m2m through inlines.
- Status: encoded in write-permission claims and compatibility audit.

## E5 - Existing public tests for #8060

- Source: in-repo public tests in `repo/tests/admin_inlines/tests.py`.
- Quote: comments state "No change permission on books, so no inline" and "We have change perm on books, so we can add/change/delete inlines."
- Obligation: for auto-created m2m through models, target `change` permission is the established write gate; target `add` alone is not enough.
- Status: encoded in `(TARGET-CHANGE-WRITE-TRUE)` and rejected alternatives in `FINDINGS.md`.

## E6 - Auto-created intermediary lacks own permissions

- Source: implementation comments in `repo/django/contrib/admin/options.py`.
- Quote: "auto-created intermediate model... doesn't have its own individual permissions."
- Obligation: the code must resolve permissions through the related target model rather than through the intermediary model.
- Status: encoded in helper specification and provenance comments in the K spec.
