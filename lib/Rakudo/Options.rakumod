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
sub MAIN() {  # UNCOVERABLE
    with nqp::hllize($options) -> %hash {  # UNCOVERABLE
        say "$_.key(): { (try .value.raku) // .value.^name }"  # UNCOVERABLE
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

class Rakudo::Options:ver<0.0.5>:auth<zef:lizmat> {
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

    submethod TWEAK(--> Nil) {
        $!ll-exception := $!ll-exception ?? '--ll-exception' !! Empty;
        $!stagestats   := $!stagestats   ?? '--stagestats'   !! Empty;
        $!n := $!n ?? '-n' !! Empty;
        $!p := $!p ?? '-p' !! Empty;

        without $!program {
            $!program := $!e.defined
              ?? ('-e', $!e)
              !! $*PROGRAM.absolute;
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

    method run-parameters(Rakudo::Options:D:) {
        Slip.new($!executable, $!ll-exception, $!stagestats, $!n, $!p,
          $!profile, $!optimize, $!encoding, $!target, $!I, $!M, $!program
        );
    }

    proto method run(|) {*}
    multi method run(Rakudo::Options:D:) {
        self.run(@*ARGS, |%_)
    }
    multi method run(Rakudo::Options:D: *@ARGS) {
        run self.run-parameters, @ARGS, |%_
    }

    proto method run-with-environment-variable(|) {*}
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
            run self.run-parameters, @ARGS, |%_, :%env
        }
    }
}

INIT PROCESS::<$RAKUDO-OPTIONS> := Rakudo::Options.new;

# vim: expandtab shiftwidth=4
