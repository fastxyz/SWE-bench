# Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F-001: V1 fixes the reported project-catalog shadowing

Classification: resolved code bug.

Input:
`language = 'da'`; `repo.locale_dirs` yields `locale`; project catalog contains
`Fig. %s -> Foobar %s`; bundled/system catalog contains `Fig. %s -> figur %s`.

Observed in V0:
The built-in translation wins, yielding `figur 1`.

Expected from public intent:
The project translation wins, yielding `Foobar 1`. The same winner rule applies
to `Listing %s -> Whatever %s`.

V1 result by PO-1 and PO-2:
The yielded project locale directory is first in `locale.init()` order, so its
catalog is the primary translator. Built-in catalogs are fallbacks and cannot
shadow a project entry.

Recommended code action:
No additional source edit; keep V1.

## F-002: V1 preserves fallback for messages missing from project catalogs

Classification: confirmed frame condition.

Input:
A yielded project locale directory exists, but its `sphinx.mo` does not contain
message `M`; the system or bundled catalog contains `M`.

Expected from public intent:
The rest of the internal messages should remain localized through existing
built-in catalogs.

V1 result by PO-3:
`locale.init()` keeps built-in catalogs as fallbacks after project catalogs, so
missing project messages fall through.

Recommended code action:
No additional source edit.

## F-003: V1 preserves no-project behavior and built-in fallback order

Classification: confirmed compatibility/frame condition.

Input:
`repo.locale_dirs` yields no directories for the configured language.

Expected:
Behavior should match V0 because the issue only requires project override
precedence when a project catalog is present.

V1 result by PO-4:
The order becomes `[None, package_dir/locale]`, identical to V0's built-in
order.

Recommended code action:
No additional source edit.

## F-004: Direct locale APIs and extension catalogs are unchanged

Classification: compatibility confirmation.

Input:
Extensions calling `app.add_message_catalog()` or direct callers using
`locale.init()` with their own directory list.

Expected:
No API or direct helper semantic change from this bug fix.

V1 result by PO-6:
Only `_init_i18n()` local list construction changed.

Recommended code action:
No additional source edit.

## F-005: Proof is constructed but not machine-checked

Classification: proof process caveat.

Input:
The FVK `.k` model and claims in `fvk/`.

Observed:
The benchmark forbids running `kompile`, `kast`, or `kprove`.

Expected:
Artifacts must include exact commands and be labeled constructed, not
machine-checked.

Recommended action:
Keep tests until the emitted commands are run in an environment with K tooling.
This is not a code bug.
