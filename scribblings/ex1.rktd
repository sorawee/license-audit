;; This file was created by make-log-based-eval
((require racket/port) ((3) 0 () 0 () () (c values c (void))) #"" #"")
((define (run flags)
   (with-output-to-string
    (λ ()
      (parameterize
       ((current-command-line-arguments flags))
       (dynamic-require 'license-audit/raco #f)))))
 ((3) 0 () 0 () () (c values c (void)))
 #""
 #"")
((run #("--local-only" "license-audit"))
 ((3)
  0
  ()
  0
  ()
  ()
  (c
   values
   c
   (u
    .
    "=== package: license-audit ===\n\n30 packages queried\n\n╭─────┬───────────────────────────────┬───────────────────┬──────────────────────────────╮\n│  *  │ package name                  │ required by       │ license                      │\n├─────┼───────────────────────────────┼───────────────────┼──────────────────────────────┤\n│ [l] │ license-audit                 │ -                 │ (Apache-2.0 OR MIT)          │\n│ [l] │ base                          │ license-audit     │ (Apache-2.0 OR MIT)          │\n│ [l] │ racket-lib                    │ base              │ (Apache-2.0 OR MIT)          │\n│ [l] │ racket-aarch64-macosx-3       │ racket-lib        │ ((Apache-2.0 OR MIT) AND     │\n│     │                               │                   │  (BSD-3-clause AND OpenSSL)) │\n│ [l] │ text-table                    │ license-audit     │ no license indicated         │\n│ [l] │ pprint                        │ license-audit     │ no license indicated         │\n│ [l] │ dherman-struct                │ pprint            │ no license indicated         │\n│ [l] │ compatibility-lib             │ dherman-struct    │ (Apache-2.0 OR MIT)          │\n│ [l] │ scheme-lib                    │ compatibility-lib │ (Apache-2.0 OR MIT)          │\n│ [l] │ net-lib                       │ compatibility-lib │ (Apache-2.0 OR MIT)          │\n│ [l] │ srfi-lite-lib                 │ net-lib           │ (Apache-2.0 OR MIT)          │\n│ [l] │ sandbox-lib                   │ compatibility-lib │ (Apache-2.0 OR MIT)          │\n│ [l] │ errortrace-lib                │ sandbox-lib       │ (Apache-2.0 OR MIT)          │\n│ [l] │ source-syntax                 │ errortrace-lib    │ (Apache-2.0 OR MIT)          │\n│ [l] │ rackunit-lib                  │ pprint            │ (Apache-2.0 OR MIT)          │\n│ [l] │ testing-util-lib              │ rackunit-lib      │ (Apache-2.0 OR MIT)          │\n│ [u] │ racket-win32-i386-3           │ racket-lib        │ -                            │\n│ [u] │ racket-win32-x86_64-3         │ racket-lib        │ -                            │\n│ [u] │ racket-win32-arm64-3          │ racket-lib        │ -                            │\n│ [u] │ racket-x86_64-linux-natipkg-3 │ racket-lib        │ -                            │\n│ [u] │ racket-x86_64-macosx-3        │ racket-lib        │ -                            │\n│ [u] │ racket-i386-macosx-3          │ racket-lib        │ -                            │\n│ [u] │ racket-ppc-macosx-3           │ racket-lib        │ -                            │\n│ [u] │ db-ppc-macosx                 │ racket-lib        │ -                            │\n│ [u] │ db-win32-i386                 │ racket-lib        │ -                            │\n│ [u] │ db-win32-x86_64               │ racket-lib        │ -                            │\n│ [u] │ db-win32-arm64                │ racket-lib        │ -                            │\n│ [u] │ db-x86_64-linux-natipkg       │ racket-lib        │ -                            │\n│ [u] │ com-win32-i386                │ racket-lib        │ -                            │\n│ [u] │ com-win32-x86_64              │ racket-lib        │ -                            │\n╰─────┴───────────────────────────────┴───────────────────┴──────────────────────────────╯\n")))
 #""
 #"")
