[![Actions Status](https://github.com/lizmat/Rakudo-Options/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Rakudo-Options/actions) [![Actions Status](https://github.com/lizmat/Rakudo-Options/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Rakudo-Options/actions) [![Actions Status](https://github.com/lizmat/Rakudo-Options/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Rakudo-Options/actions)

NAME
====

Rakudo::Options - Rakudo Command Line Options

SYNOPSIS
========

```raku
use Rakudo::Options;

say "running with --ll-exception" if $*RAKUDO-OPTIONS.ll-exception;

say "running as a one liner" if $*RAKUDO-OPTIONS.e;

Rakudo::Options.new(program => "script").run;

if $*RAKUDO-OPTIONS.run-with-environment-variable(
  (MVM_SPESH_LOG => "log")
) -> $proc {
    say "Produced spesh log in '{"log".IO.absolute}'";
}
```

DESCRIPTION
===========

Rakudo::Options is a multi-faceted tool, intended for Rakudo tool builders. It provides an API to the command line functions of the currently running Rakudo process for introspection in a dynamic variable `$*RAKUDO-OPTIONS`.

It also allows you to create an adhoc object that allows you to tweak values of the currently running Rakudo process to run (again).

DYNAMIC VARIABLE
================

Loading the `Rakudo::Options` module, creates the `$*RAKUDO-OPTIONS` dynamic variable, which contains the settings of the currently running Rakudo process (as a `Rakudo::Options` object).

BUILD PARAMETERS
================

The following named arguments can be supplied to a call to `.new` to override what the currently running Rakudo process already provides:

  * e

The Raku code that should be considered to have been specified with `-e`.

  * encoding

The string of the `--encoding` flag to be considered specified.

  * executable

String or `IO::Path` object indicating the executable with which the process is supposed to be running.

  * includes

The `List` of the names of the directories that should be considered to have been specified with `-I`.

  * ll-exception

Whether the `--ll-exception` flag is considered to be specified. Expected to be a truthy / falsey value.

  * modules

The `List` of names of the modules that should be considered loaded with `-M`.

  * n

Whether the `-n` flag is considered to be specified. Expected to be a truthy / falsey value.

  * optimize

The string of the `--optimize` flag to be considered specified.

  * p

Whether the `-p` flag is considered to be specified. Expected to be a truthy / falsey value.

  * profile

Whether the `--profile` flag is to be specifiied. Can be given as a `Bool`, or as a string (indicating the type of profile requested).

  * program

A string (or an `IO::Path` object) with the name of the script that is supposed to be running.

  * stagestats

Whether the `--stagestats` flag is considered to be specified. Expected to be a truthy / falsey value.

  * target

The string of the `--target` flag to be considered specified.

ACCESSORS
=========

Please note that all accessors return `Empty` if they were not considered to be specified. This allows the accessors to also be used as booleans.

Also note that all of the examples use the `$*RAKUDO-OPTIONS` dynamic variable, but that any ad-hoc created `Rakudo::Options` can also be used.

Also note that each of these attributes (with the exception of `e`, `includes` and `modules`) can be used "as is" as an argument to the `run` function, or as a parameter to the creation of a `Proc::Async` object.

e
-

The code that was considered to be specified with `-e`. If you want to transparently run a script, or the `-e` code, you should use the `.program` accessor.

```raku
say "running as a one-liner" if $*RAKUDO-OPTIONS.e;
```

encoding
--------

The command line parameter of the non-UTF8 encoding with which source-files are considered to be encoded.

```raku
if $*RAKUDO-OPTIONS.encoding -> $encoding {
    say "Specified '$encoding' for source files";
}
```

executable
----------

The string of the executable that is considered to be specified.

```raku
say "Running with the $*RAKUDO-OPTIONS.executable() executable";
```

I
-

A `List` of command line parameters of `-I` specifications, to be considered to have been specified.

```raku
if $*RAKUDO-OPTIONS.I -> @I {
    say "Arguments: @I";
}
```

includes
--------

A `List` of strings of the `-I` specifications to have considered to have been given.

```raku
if $*RAKUDO-OPTIONS.includes -> @includes {
    say "Specified: @includes";
}
```

ll-exception
------------

The command line parameter that indicates whether exceptions should throw the extended stack trace or not.

```raku
say "Will show extended stack trace" if $*RAKUDO-OPTIONS.ll-exception;
```

M
-

A `List` of command line parameters of `-M` specifications, to be considered to have been specified.

```raku
if $*RAKUDO-OPTIONS.M -> @M {
    say "Arguments: @M";
}
```

modules
-------

A `List` of strings of the `-M` specifications to have considered to have been given.

```raku
if $*RAKUDO-OPTIONS.modules -> @modules {
    say "Specified: @modules";
}
```

n
-

The command line parameter that indicates the program should be run for each line of input.

```raku
say "Executing with -n" if $*RAKUDO-OPTIONS.n;
```

p
-

The command line parameter that indicates the program should be run for each line of input, and that `$_` should be printed after each line of input.

```raku
say "Executing with -p" if $*RAKUDO-OPTIONS.p;
```

optimize
--------

The command line parameter that indicates the optimization level.

```raku
say "Running with $_" with $*RAKUDO-OPTIONS.optimize;
```

program
-------

The command line parameter that indicates the program to be executed. Is either a string (in which case it is the name of the script to run) or a `List` consisting of `-e` and the code to executed.

```raku
say "Running $*RAKUDO-OPTIONS.program";
```

profile
-------

The command line parameter that indicates whether a profile should be made, and what type.

```raku
say "Creating a profile with $_" with $*RAKUDO-OPTIONS.profile;
```

stagestats
----------

The command line parameter that indicates whether stage statistics should be shown while compiling.

```raku
say "Showed stage statistics while compiling" if $*RAKUDO-OPTIONS.stagestats;
```

target
------

The command line parameter indicating the target of the compilation.

```raku
say "Compiling for target $_" with $*RAKUDO-OPTIONS.target;
```

METHODS
=======

run
---

The `.run` method returns a `Proc::Async` object by calling the `run` command with the `.run-parameters` of the `Rakudo::Options` object, and any additional positional and named arguments that you give it.

```raku
Rakudo::Options.new(
  program => $*PROGRAM.sibling('run.raku')
).run(<foo bar>);

my $ro = Rakudo::Options.new(
  program => $*PROGRAM.sibling('run.raku')
);
my $output = $ro.run(<foo bar>, :out).out.slurp;
```

run-with-environment-variable
-----------------------------

The `.run-with-environment-variable` is like the `.run` method, but it also takes a `Pair` as the first positional parameter. This pair should have the key as the name of an environment variable to be set, and as value, the value that environment variable should have when calling `run`.

It returns the `Proc::Async` object in the parent process, and `Nil` in the child process.

```raku
# parent process
if $*RAKUDO-OPTIONS.run-with-environment-variable(
  (MVM_SPESH_LOG => 'spesh-log')  # note extra parentheses needed
) {
    # inspect spesh-log
    exit;
}
# child process, code you want spesh-logged
```

run-parameters
--------------

The `.run-parameters` method returns a `Slip` with all of the parameters that should be passed to the `run` command. It is an internal helper method, that could be used for introspection and debugging, or if you want to execute your own `run` commands.

```raku
my $ro := Rakudo::Options.new(
  program => $*PROGRAM.sibling('run.raku')
);
run $ro.run-parameters, <foo bar>;
```

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Rakudo-Options . Comments and Pull Requests are welcome.

If you like this module, or what I'm doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2021, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

