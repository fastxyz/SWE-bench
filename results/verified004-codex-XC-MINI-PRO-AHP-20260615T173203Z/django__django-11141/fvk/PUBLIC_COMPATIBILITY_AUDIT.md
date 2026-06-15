# Public Compatibility Audit

Status: constructed from public evidence; not machine-checked.

## Changed public symbols

No public symbol signature changed.

## Audited consumers

`MigrationLoader.load_disk()`

Compatibility status: unchanged method signature. The method still writes to
`self.disk_migrations`, `self.unmigrated_apps`, and `self.migrated_apps`.

`django.core.management.commands.migrate`

Compatibility status: compatible. This command reads
`executor.loader.migrated_apps` to decide whether an app has migrations and
`executor.loader.unmigrated_apps` for `run_syncdb`. The fix changes only the
classification of namespace migration packages, which is the intended public
behavior.

`django.core.management.commands.showmigrations`,
`django.core.management.commands.squashmigrations`, and
`django.core.management.commands.sqlmigrate`

Compatibility status: compatible. These commands read `migrated_apps` and the
migration graph through the same loader API. No signature or return-shape change
is required.

`django.db.migrations.executor.MigrationExecutor`

Compatibility status: compatible. Project state still receives
`real_apps=list(self.loader.unmigrated_apps)`. Namespace migration packages move
out of `real_apps`, matching the intent that they are migrated apps.

## Compatibility findings

No unhandled callsite, override, or producer/consumer shape change was found.
