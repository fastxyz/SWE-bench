# Formal Spec English

Status: paraphrase of `fvk/migration-serializer-spec.k`.

1. `(SERIALIZE-MODELS-MODEL)` says that the abstract value representing
   `django.db.models.Model` serializes to the text `models.Model` and the import
   set containing `from django.db import models`.

2. `(SERIALIZE-NONE-TYPE)` says that the abstract value representing
   `type(None)` serializes to `type(None)` and an empty import set.

3. `(SERIALIZE-CUSTOM-TYPE)` says that any custom type with module `M` and
   qualified name `Q` serializes to `M.Q` and the import set containing
   `import M`.

4. `(SERIALIZE-REPORTED-BASES)` says that a two-item bases tuple containing
   `app.models.MyMixin` and `models.Model` serializes to
   `(app.models.MyMixin, models.Model)` and carries both imports:
   `import app.models` and `from django.db import models`.

5. `(RENDER-WITH-MODELS)` says that an aggregate import set containing
   `from django.db import models` renders the Django import line
   `from django.db import migrations, models`.

6. `(RENDER-WITHOUT-MODELS)` says that an aggregate import set without
   `from django.db import models` renders the Django import line
   `from django.db import migrations`.

7. The claims do not alter public signatures, return pair shape, test files, or
   unrelated serializer branches.
