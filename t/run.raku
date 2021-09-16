use Test;

plan 1;

is-deeply @*ARGS, [<foo bar>], 'did we get the right parameters';

# vim: expandtab shiftwidth=4
