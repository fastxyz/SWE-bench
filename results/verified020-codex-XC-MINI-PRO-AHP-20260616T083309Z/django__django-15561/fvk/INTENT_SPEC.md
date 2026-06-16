# Intent Spec

This file records intent before accepting candidate implementation behavior.

1. On SQLite, an `AlterField` operation that only adds, removes, or changes
   `choices` should be a no-op and should not generate table-remake SQL.
2. The fix must be SQLite-specific because globally ignoring `choices` may
   break third-party enum-like fields whose database schema depends on choices.
3. Existing ignored non-database field attributes must continue to be ignored.
4. Real schema-affecting changes, including column changes and non-ignored
   deconstruction kwarg changes, must still be classified as alterations.
5. The change should preserve public schema editor method signatures and should
   not modify tests in this task.
