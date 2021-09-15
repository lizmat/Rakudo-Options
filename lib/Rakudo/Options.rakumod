# This only runs on Rakudo, and as such uses its naughty bits.
use nqp;

my $options;

# This appears to be needed to make sure the module will precompile
# because apparently the precompilation process runs the INIT phasers
# but maybe not in the right order?
BEGIN $options := nqp::hash;

INIT $options := nqp::ifnull(
  nqp::atkey(nqp::getlexdyn('%*COMPILING'),'%?OPTIONS'),
  nqp::hash
);

# Debugging helper when module is called directly
sub MAIN() {
    with nqp::hllize($options) -> %hash {
        say "$_.key(): { (try .value.raku) // .value.^name }"
          for %hash;
    }
}

my sub multiple(str $letter) {
    nqp::if(
      nqp::existskey($options,$letter),
      nqp::p6bindattrinvres(
        nqp::create(List),List,'$!reified',
        nqp::stmts(
          (my $L := nqp::atkey($options,$letter)),
          nqp::if(nqp::islist($L),$L,nqp::list($L))
        )
      ),
      Empty
    )
}

my sub key-or-value(str $name, $value) {
    $value.defined
      ?? "--$name=$value"
      !! nqp::existskey($options,$name)
        ?? "--$name=" ~ nqp::atkey($options,$name)
        !! Empty
}

my sub flatten(str $letter, @values) {
    @values
      ?? @values.map({ "-$letter$_" }).List
      !! Empty
}

class Rakudo::Options:ver<0.0.1>:auth<zef:lizmat> {
    has @.includes is built(:bind) = multiple('I');
    has @.modules  is built(:bind) = multiple('M');
    has $.ll-exception = nqp::existskey($options,'ll-exception');
    has $.stagestats   = nqp::existskey($options,'stagestats');
    has $.n            = nqp::existskey($options,'n');
    has $.p            = nqp::existskey($options,'p');
    has $.e            = nqp::hllize(nqp::atkey($options,'e'));
    has $.executable;
    has $.program;
    has $.profile;
    has $.optimize;
    has $.encoding;
    has $.target;
    has $.I is built(False);
    has $.M is built(False);

    method TWEAK(--> Nil) {
        $!ll-exception := $!ll-exception ?? '--ll-exception' !! Empty;
        $!stagestats   := $!stagestats   ?? '--stagestats'   !! Empty;
        $!n := $!n ?? '-n' !! Empty;
        $!p := $!p ?? '-p' !! Empty;

        without $!program {
            $!program := $!e.defined
              ?? ('-e', $!e)
              !! $*PROGRAM-NAME;
        }
        $!e          := Empty                 without $!e;
        $!executable := $*EXECUTABLE.absolute without $!executable;

        $!profile := nqp::istype($!profile,Bool)
          ?? $!profile
            ?? '--profile'
            !! Empty
          !! $!profile.defined
            ?? "--profile=$!profile"
            !! nqp::existskey($options,'profile')
              ?? nqp::atkey($options,'profile')
                ?? "--profile=" ~ nqp::atkey($options,'profile')
                !! '--profile'
              !! Empty;

        $!encoding := $!encoding.defined
          ?? "--encoding=$!encoding"
          !! nqp::existskey($options,'encoding')
            ?? nqp::iseq_s(nqp::atkey($options,'encoding'),'utf8')
              ?? Empty
              !! "--encoding=" ~ nqp::atkey($options,'encoding')
            !! Empty;

        $!optimize := key-or-value('optimize', $!optimize);
        $!target   := key-or-value('target',   $!target);

        $!I := flatten('I',@!includes);
        $!M := flatten('M',@!modules);
    }

    multi method run(Rakudo::Options:D:) {
        self.run(@*ARGS, |%_)
    }
    multi method run(Rakudo::Options:D: *@ARGS) {
        run $!executable, $!ll-exception, $!stagestats, $!n, $!p,
            $!profile, $!optimize, $!encoding, $!target, $!I, $!M,
            $!program, @ARGS, |%_
    }

    multi method run-with-environment-variable(Rakudo::Options:D:
      Pair:D $var
    ) {
        self.run-with-environment-variable($var, @*ARGS, |%_)
    }

    multi method run-with-environment-variable(Rakudo::Options:D:
      Pair:D $var,
      *@ARGS
    ) {
        if %*ENV.EXISTS-KEY($var.key) {
            Nil
        }
        else {
            my %env = %*ENV, ($_ with %_<env>), $var;
            run $!executable, $!ll-exception, $!stagestats, $!n, $!p,
                $!profile, $!optimize, $!encoding, $!target, $!I, $!M,
                $!program, @ARGS, |%_, :%env
        }
    }
}

INIT PROCESS::<$RAKUDO-OPTIONS> := Rakudo::Options.new;

=begin pod

=head1 NAME

Rakudo::Options - Rakudo Command Line Options

=head1 SYNOPSIS

=begin code :lang<raku>

use Rakudo::Options;

say "running with --ll-exception" if $*RAKUDO-OPTIONS.ll-exception;

say "running as a one liner" if $*RAKUDO-OPTIONS.e;

Rakudo::Options.new(program => "script").run;

if $*RAKUDO-OPTIONS.run-with-environment-variable(
  (MVM_SPESH_LOG => "log")
) -> $proc {
    say "Produced spesh log in '{"log".IO.absolute}'";
}

=end code

=head1 DESCRIPTION

Rakudo::Options is a multi-faceted tool, intended for Rakudo tool
builders.  It provides an API to the command line functions of the
currently running Rakudo process for introspection in a dynamic
variable C<$*RAKUDO-OPTIONS>.

It also allows you to create an adhoc object that allows you to
tweak values of the currently running Rakudo process to run (again).

=head1 DYNAMIC VARIABLE

Loading the C<Rakudo::Options> module, creates the C<$*RAKUDO-OPTIONS>
dynamic variable, which contains the settings of the currently running
Rakudo process (as a C<Rakudo::Options> object).

=head1 BUILD PARAMETERS

The following named arguments can be supplied to a call to C<.new>
to override what the currently running Rakudo process already
provides:

=item e

The Raku code that should be considered to have been specified with C<-e>.

=item encoding

The string of the C<--encoding> flag to be considered specified.

=item executable

String indicating the executable with which the process is supposed to
be running.

=item includes

The C<List> of The names of the directories that should be considered
to have been specified with C<-I>.

=item ll-exception

Whether the C<--ll-exception> flag is considered to be specified.
Expected to be a truthy / falsey value.

=item modules

The C<List> of  names of the modules that should be considered loaded
with C<-M>.

=item n

Whether the C<-n> flag is considered to be specified.  Expected to be
a truthy / falsey value.

=item optimize

The string of the C<--optimize> flag to be considered specified.

=item p

Whether the C<-p> flag is considered to be specified.  Expected to be
a truthy / falsey value.

=item profile

Whether the C<--profile> flag is to be specifiied.  Can be given as a
C<Bool>, or as a string (indicating the type of profile requested).

=item program

A string with the name of the script that is supposed to be running.

=item stagestats

Whether the C<--stagestats> flag is considered to be specified.
Expected to be a truthy / falsey value.

=item target

The string of the C<--target> flag to be considered specified.

=head1 ACCESSORS

Please note that all accessors return C<Empty> if they were not
considered to be specified.  This allows the accessors to also be
used as booleans.

Also note that all of the examples use the C<$*RAKUDO-OPTIONS>
dynamic variable, but that any ad-hoc created C<Rakudo::Options>
can also be used.

Also note that each of these attributes (with the exception of
C<e>, C<includes> and C<modules> can be uses "as is" as parameter
to the C<run> function, or as a parameter to the creation of a
C<Proc::Async> object.

=head2 e

The code that was considered to be specified with C<-e>.  If you
want to transparently run a script, or the C<-e> code, you should
use the C<.program> accessor.

=begin code :lang<raku>

say "running as a one-liner" if $*RAKUDO-OPTIONS;

=end code

=head2 encoding

The command line parameter of the non-UTF8 encoding with which
source-files are considered to be encoded.

=begin code :lang<raku>

if $*RAKUDO-OPTIONS.encoding -> $encoding {
    say "Specified '$encoding' for source files";
}

=end code

=head2 executable

The string of the executable that is considered to be specified.

=begin code :lang<raku>

say "Running with the $*RAKUDO-OPTIONS.executable() executable";

=end code

=head2 I

A C<List> of command line parameters of C<-I> specifications, to
be considered to have been specified.

=begin code :lang<raku>

if $*RAKUDO-OPTIONS.I -> @I {
    say "Arguments: @I";
}

=end code

=head2 includes

A C<List> of strings of the C<-I> specifications to have considered
to have been given.

=begin code :lang<raku>

if $*RAKUDO-OPTIONS.includes -> @includes {
    say "Specified: @includes";
}

=end code

=head2 ll-exception

The command line parameter that indicates whether exceptions should
throw the extended stack trace or not.

=begin code :lang<raku>

say "Will show extended stack trace" if $*RAKUDO-OPTIONS.ll-exception;

=end code

=head2 M

A C<List> of command line parameters of C<-M> specifications, to
be considered to have been specified.

=begin code :lang<raku>

if $*RAKUDO-OPTIONS.M -> @M {
    say "Arguments: @M";
}

=end code

=head2 modules

A C<List> of strings of the C<-M> specifications to have considered
to have been given.

=begin code :lang<raku>

if $*RAKUDO-OPTIONS.modules -> @modules {
    say "Specified: @modules";
}

=end code

=head2 n

The command line parameter that indicates the program should be run
for each line of input.

=begin code :lang<raku>

say "Executing with -n" if $*RAKUDO-OPTIONS.n;

=end code

=head2 p

The command line parameter that indicates the program should be run
for each line of input, and that C<$_> should be printed after each
line of input.

=begin code :lang<raku>

say "Executing with -p" if $*RAKUDO-OPTIONS.p;

=end code

=head2 optimize

The command line parameter that indicates the optimization level.

=begin code :lang<raku>

say "Running with $_" with $*RAKUDO-OPTIONS.optimize;

=end code

=head2 program

The command line parameter that indicates the program to be executed.
Is either a string (in which case it is the name of the script to run)
or a C<List> consisting of C<-e> and the code to executed.

=begin code :lang<raku>

say "Running $*RAKUDO-OPTIONS.program";

=end code

=head2 profile

The command line parameter that indicates whether a profile should
be made, and what type.

=begin code :lang<raku>

say "Creating a profile with $_" with $*RAKUDO-OPTIONS.profile;

=end code

=head2 stagestats

The command line parameter that indicates whether stage statistics
should be shown while compiling.

=begin code :lang<raku>

say "Showed stage statistics while compiling" if $*RAKUDO-OPTIONS.stagestats;

=end code

=head2 target

The command line parameter indicating the target of the compilation.

=begin code :lang<raku>

say "Compiling for target $_" with $*RAKUDO-OPTIONS.target;

=end code

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
