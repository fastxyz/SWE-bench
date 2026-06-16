requires "mini-migration-imports.k"

module MIGRATION-IMPORTS-SPEC
  imports MINI-MIGRATION-IMPORTS
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "Place all import module statements before from module import
  //   objects in each section." => style rank 0 for PlainImport and 1 for
  //   FromImport, sorted as the primary key.
  // - from_prompt: desired example datetime/time/django => ISSUE-WITNESS.
  // - from_code: V1 key is (i.split()[0] == "from", i.split()[1]).
  // - from_default_domain: generated import lines use "import <module>" or
  //   "from <module> import <objects>".
  claim
    <k> sortImports(L:ImportLines) => R:ImportLines </k>
    requires allGeneratedImportLines(L) ==Bool true
    ensures sortedByStyleModule(R) ==Bool true
        andBool permutation(R, L) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "This would mean migration files should instead be generated
  //   like this: import datetime; import time; from django.db import migrations,
  //   models." => concrete expected output.
  claim
    <k>
      sortImports(
        importLine(PlainImport(), "datetime", "import datetime") ;
        importLine(FromImport(), "django.db", "from django.db import migrations, models") ;
        importLine(PlainImport(), "time", "import time") ;
        .ImportLines
      )
      =>
      importLine(PlainImport(), "datetime", "import datetime") ;
      importLine(PlainImport(), "time", "import time") ;
      importLine(FromImport(), "django.db", "from django.db import migrations, models") ;
      .ImportLines
    </k>
    [all-path]
endmodule
