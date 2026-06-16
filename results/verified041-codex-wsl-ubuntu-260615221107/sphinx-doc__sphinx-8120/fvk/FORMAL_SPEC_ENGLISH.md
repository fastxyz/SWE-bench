# Formal Spec English

Status: constructed from the K claims, not machine-checked.

K claim `PROJECT-OVERRIDES`:
After initializing with a yielded project locale directory followed by the
existing built-in fallback locations, resolving a message that exists in the
project catalog returns the project catalog value. This remains true even when
system or bundled catalogs also contain the same message.

K claim `PROJECT-ORDER`:
When two project locale directories are yielded in configuration order and both
contain the message, resolving that message returns the value from the earlier
project directory.

K claim `BUILTIN-FALLBACK`:
When the yielded project locale directory does not contain the message but the
system gettext location does, resolving that message returns the system value
and does not consult the bundled package value for that message.

K claim `PACKAGE-FALLBACK`:
When the yielded project locale directory and system gettext location do not
contain the message but the bundled package catalog does, resolving that message
returns the bundled package value.

K claim `NO-PROJECT-PRESERVES-OLD-BUILTINS`:
When no project locale directories are yielded, the initialized lookup order is
the pre-existing built-in order: system gettext location first, then bundled
package locale.
