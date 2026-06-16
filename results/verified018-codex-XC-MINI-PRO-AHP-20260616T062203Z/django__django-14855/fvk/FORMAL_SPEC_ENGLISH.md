# FORMAL SPEC ENGLISH

Status: constructed, not machine-checked.

FS1. If the active admin site has a related model change route, then
`getAdminUrl(active_site, app, model, pk, obj, routes)` renders an anchor whose
URL is built from the active site's route prefix.

FS2. If the active admin site is `"admin"` and the default admin route exists,
then `getAdminUrl()` renders the default admin anchor.

FS3. If the active admin site lacks the related model change route, then
`getAdminUrl()` renders plain object text.

FS4. The legacy helper that ignores the active site and reverses against the
default site renders the default URL even when a different active custom route
exists.
