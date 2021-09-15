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

=head2 include

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

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
