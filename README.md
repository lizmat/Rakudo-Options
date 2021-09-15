[![Actions Status](https://github.com/lizmat/Rakudo-Options/workflows/test/badge.svg)](https://github.com/lizmat/Rakudo-Options/actions)

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

String indicating the executable with which the process is supposed to be running.

  * includes

The `List` of The names of the directories that should be considered to have been specified with `-I`.

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

A string with the name of the script that is supposed to be running.

  * stagestats

Whether the `--stagestats` flag is considered to be specified. Expected to be a truthy / falsey value.

  * target

The string of the `--target` flag to be considered specified.

ACCESSORS
=========

include
-------

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

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

