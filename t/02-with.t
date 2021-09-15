use Test;
use Rakudo::Options;

my $foo = "foo".IO;
my $bar = "bar".IO;

# parent process
if $*RAKUDO-OPTIONS.run-with-environment-variable(
  (MVM_SPESH_LOG => $foo)
) {
    plan 4;
    ok $foo.e, 'did we create a spesh log file';
    ok $foo.slurp.starts-with('Received Logs'),
      'does it look like a spesh log';

    ok $bar.e, 'did we create a file in the child';
    is $bar.slurp, 'this is bar', 'did it look ok';

    # clean up
    $foo.unlink;
    $bar.unlink;
}

# child process
else {
    $bar.spurt('this is bar');
}

# vim: expandtab shiftwidth=4
