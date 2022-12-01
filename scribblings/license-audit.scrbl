#lang scribble/manual
@require[@for-label[license-audit
                    racket/base]
         scribble/example
         scribble/bnf]

@(define (setup-eval path)
    (define eval (make-log-based-eval path 'replay))
    (eval '(require racket/port))
    (eval '(define (run flags)
             (with-output-to-string
               (λ ()
                 (parameterize ([current-command-line-arguments flags])
                   (dynamic-require 'license-audit/raco #f))))))
    eval)

@(define eval-1 (setup-eval "scribblings/ex1.rktd"))
@(define eval-2 (setup-eval "scribblings/ex2.rktd"))

@title{license-audit: audit package licenses}
@author[@author+email["Sorawee Porncharoenwase" "sorawee.pwase@gmail.com"]]

@defmodule[license-audit]

This package provides a tool @exec{raco license-audit} to audit package licenses.
The tool also shows information from transitive dependencies.

@section{Running @exec{raco license-audit}}

@exec{raco license-audit @nonterm{option} ... @nonterm{name} ...} displays license information of @nonterm{name}s,
including their dependencies, to the standard output.
By default, it queries information from locally installed packages first,
and if the information is not available locally,
it proceeds to query information from the package index server.

Following @nonterm{name} is specially recognized:

@itemlist[
  @item{@tt|{@}| --- a meta package that depends on all packages on the package index server and all packages locally installed.}
  @item{@tt|{@-global}| --- a meta package that depends on all packages on the package index server.}
  @item{@tt|{@-local}| --- a meta package that depends on all packages locally installed.}
  @item{@tt|{@-local-user}| --- a meta package that depends on all packages locally installed in the user scope.}
  @item{@tt|{@-local-installation}| --- a meta package that depends on all packages locally installed in the installation scope.}
]

The @exec{raco license-audit} command accepts the following @nonterm{option}s:

@itemlist[
  @item{@DFlag{local-only}, @Flag{l} --- only read the license information from locally installed packages.}
  @item{@DFlag{global-only}, @Flag{g} --- only read the license information from the package index server.}
  @item{@DFlag{build-time}, @Flag{b} --- also include build-time dependencies.}
  @item{@DFlag{no-main-distribution} --- exclude packages in the main distribution (including their transitive dependencies and its tests).}
  @item{@DFlag{tags} --- show tags (this option requires @DFlag{global-only}).}
  @item{@DFlag{authors} --- show authors and group by them (this option requires @DFlag{global-only}).}
]

@section{Examples}

As an example, running @exec{raco license-audit --local-only license-audit} on some systems might output the following

@(verbatim (eval-1 '(run #("--local-only" "license-audit"))))

However, running the same command without @DFlag{local-only} produces:

@(verbatim (eval-2 '(run #("license-audit"))))

@section{Output format}

The first column indicates the status:

@itemlist[
  @item{@tt{[l]} -- the package is queried from locally installed packages}
  @item{@tt{[g]} -- the package is queried from the package index server}
  @item{@tt{[u]} -- the package can't be queried from locally installed packages
        (only applicable for @DFlag{local-only}).

        One possible reason for a package to have this status is that the package
        is a @emph{conditional dependency},
        which will be installed only on a specific platform,
        and the platform does not match the local platform.
        For example, in @secref{Examples}, @tt{racket-win32-i386-3}
        is a conditional dependency (of @tt{base}).
        The package will be installed only on @tt{win32-i386}.
        Therefore, it has the @tt{[u]} status, as the local platform here
        is @tt{aarch64-macosx}, which doesn't match @tt{win32-i386}.}
  @item{@tt{[U]} -- the package can't be queried from the package index server
        (only applicable for non @DFlag{local-only})}
]

The second column indicates a package name.

The third column indicates what package requires the package.
I.e., it shows why the row is included in the output.
@tt{-} means there is no package that requires the package (because it is a @nonterm{name}).

The fourth column indicates a @tech[#:doc '(lib "pkg/scribblings/pkg.scrbl")]{license S-expression}.
If there is no license defined, @tt{no license indicated} will be shown.
