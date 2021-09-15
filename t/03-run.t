use Test;
use Rakudo::Options;

Rakudo::Options.new(
  program => $*PROGRAM.sibling('run.raku')
).run;

# vim: expandtab shiftwidth=4
