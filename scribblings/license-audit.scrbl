#lang scribble/manual
@require[@for-label[license-audit
                    racket/base]
         scribble/bnf]

@title{license-audit: audit package licenses (including their dependencies)}
@author[@author+email["Sorawee Porncharoenwase" "sorawee.pwase@gmail.com"]]

@defmodule[license-audit]

This package provides a tool @exec{raco license-audit} to audit package licenses (including their dependencies).

@section{Running @exec{raco license-audit}}

@exec{raco license-audit @nonterm{name} ...} displays license information of @nonterm{name},
including its dependencies, to the standard output.

The @exec{raco license-audit} command accepts the following flags:

@itemlist[
  @item{@DFlag{local-only}, @Flag{l} --- read the license information from only local installation.
        This means that @nonterm{name}s must be installed locally.
        Currently, this flag is @bold{mandatory}.}
  @item{@DFlag{build-time}, @Flag{b} --- also include build-time dependencies.}
]

In the future, we plan to support the command without the @DFlag{local-only} flag, which will allow reading
the license information from the package server without requiring local installation.
However, currently this feature is still not supported.

As an example, running @exec{raco license-audit -l fmt} on some systems might output the following
(provided that the package @tt{fmt} is installed)

@verbatim|{
=== package: fmt ===

Auditable packages:
fmt                      (Apache-2.0 OR MIT)
pprint-compact           (Apache-2.0 OR MIT)   (required by: fmt)
base                     (Apache-2.0 OR MIT)   (required by: pprint-compact)
racket-lib               (Apache-2.0 OR MIT)   (required by: base)
racket-aarch64-macosx-3  no license indicated  (required by: racket-lib)
syntax-color-lib         (Apache-2.0 OR MIT)   (required by: fmt)
parser-tools-lib         (Apache-2.0 OR MIT)   (required by: syntax-color-lib)
option-contract-lib      no license indicated  (required by: syntax-color-lib)

Non-auditable packages:
racket-win32-i386-3            (required by: racket-lib)
racket-win32-x86_64-3          (required by: racket-lib)
racket-win32-arm64-3           (required by: racket-lib)
racket-x86_64-linux-natipkg-3  (required by: racket-lib)
racket-x86_64-macosx-3         (required by: racket-lib)
racket-i386-macosx-3           (required by: racket-lib)
racket-ppc-macosx-3            (required by: racket-lib)
db-ppc-macosx                  (required by: racket-lib)
db-win32-i386                  (required by: racket-lib)
db-win32-x86_64                (required by: racket-lib)
db-win32-arm64                 (required by: racket-lib)
db-x86_64-linux-natipkg        (required by: racket-lib)
com-win32-i386                 (required by: racket-lib)
com-win32-x86_64               (required by: racket-lib)
}|

@deftech{Auditable packages} refers to packages (and their dependencies) which are installed on the system.
The first column shows package names.
The second column shows the license information (if available).
Lastly, the last column shows the depencency chain.

On the other hand, @deftech{non-auditable packages} refers to dependencies
which are not installed on the system due to platform mismatch.
Users should audit these entries manually.
