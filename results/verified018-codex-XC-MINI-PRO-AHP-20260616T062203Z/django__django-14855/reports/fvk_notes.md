# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the original source bug in F1 and
discharged it through PO-1. The remaining findings are frame, compatibility, or
proof-status findings; none justifies another source edit.

## Source-code decisions

`repo/django/contrib/admin/helpers.py` was not edited in this FVK pass.

Reason: F1 states the pre-fix bug precisely: readonly relation links in a custom
admin site were reversed without the active admin-site namespace. PO-1 requires
the helper to call `reverse()` with the owning `ModelAdmin.admin_site.name`.
V1 already does that with
`current_app=self.model_admin.admin_site.name`, and the constructed proof in
`fvk/PROOF.md` shows the active-site route is then selected.

I did not add a defensive `model_admin is None` branch. F4 and PO-4 show that the
admin rendering call chain passes `model_admin` into `AdminReadonlyField`, and
`AdminReadonlyField.__init__()` already dereferences `model_admin` before
`get_admin_url()` can run. A new fallback would not be tied to the reported
intent and would broaden the change unnecessarily.

I did not add a registry pre-check before reversing the related URL. F3 and PO-3
show the existing `NoReverseMatch` fallback is the intended behavior when the
owning admin site lacks the related change URL. Keeping reversal scoped to the
owning site also prevents accidental links to another admin instance.

I did not replace the `admin:` URL name with a concrete
`<site-name>:` namespace. PO-1 is satisfied by Django's existing pattern:
`reverse('admin:...', current_app=admin_site.name)`. F4 and PO-4 support keeping
that local convention because neighboring admin code already uses `current_app`
for `AdminSite`-owned reversals.

I did not edit relation dispatch, HTML formatting, escaping, many-to-many
rendering, empty-value rendering, or read-only widget rendering. F4, PO-4, and
PO-5 classify these as frame conditions, and the V1 diff is limited to the
single `reverse()` call inside `get_admin_url()`.

## FVK artifacts

I wrote the required five artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the FVK formal and adequacy support files required by the kit:

- `fvk/mini-django-admin-url.k`
- `fvk/readonly-admin-url-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Verification limits

F5 and PO-6 require the proof to be labeled constructed, not machine-checked.
The task forbids running Python, tests, `kompile`, `kast`, or `kprove`, so I did
not execute them. The commands a maintainer could run later are recorded in
`fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.

No tests were added, modified, removed, or classified as redundant. Test files
are fixed and hidden for this task, and PO-6 blocks any test-removal conclusion
without a successful machine check.
