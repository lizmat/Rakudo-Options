use Test;
use Rakudo::Options;

plan 1;

my $ro = Rakudo::Options.new(
  program => $*PROGRAM.sibling('run.raku')
);

my $output = $ro.run(<foo bar>, :out).out.slurp;

is $output, "1..1\nok 1 - did we get the right parameters\n",
  'did we get the right output';

# vim: expandtab shiftwidth=4
