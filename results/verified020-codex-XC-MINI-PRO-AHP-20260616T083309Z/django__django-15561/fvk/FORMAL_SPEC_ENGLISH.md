# Formal Spec in English

1. `BASE-CHOICES-STILL-ALTERS`: if two fields are identical in quoted column,
   path, args, and database-relevant kwargs but have different choices, the base
   decision returns true.
2. `SQLITE-CHOICES-NOOP`: if two fields are identical in quoted column, path,
   args, and database-relevant kwargs but have different choices, the SQLite
   decision returns false.
3. `SQLITE-SCHEMA-ATTR-STILL-ALTERS`: if two SQLite fields differ in a
   database-relevant deconstruction kwarg, the SQLite decision returns true.
4. `SQLITE-COLUMN-STILL-ALTERS`: if two SQLite fields differ in quoted column,
   the SQLite decision returns true.
5. Static frame condition: public method signatures, SQL templates, migration
   operation APIs, and tests are unchanged.
