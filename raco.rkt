#lang racket

;; suppress running tests on this file
(module test racket/base)

(require raco/command-name
         license-audit
         racket/cmdline
         text-table)

(define mode #f)
(define build-deps? #f)

(define pkgs
  (command-line
   #:program (short-program+command-name)
   #:once-any
   [("-l" "--local-only") "Only use local packages" (set! mode 'local)]
   [("-g" "--global-only") "Only use global packages" (set! mode 'global)]
   #:once-each
   [("-b" "--build-time") "Include build-time dependencies" (set! build-deps? #t)]
   #:args pkgs
   pkgs))

(define (print-auditable collectibles)
  (display
   (string-join
    (map
     (λ (s) (string-trim s #:left? #f))
     (string-split
      (table->string
       #:border-style 'space
       #:row-sep? #f
       #:framed? #f
       (for/list ([pkg collectibles])
         (match-define (package name required-by license mode) pkg)
         (append
          (list (case mode
                  [(local)  "[l] "]
                  [(global) "[g] "]
                  [(unknown/local) "[u] "]
                  [(unknown/global) "[u] "]
                  [else (error 'unreachable)])
                (~a name " ")
                (cond
                  [required-by
                   (format "~a " required-by)]
                  [else "- "]))
          (case mode
            [(unknown/local unknown/global) '("can't find the package")]
            [else (list (~a (or license "no license indicated")))]))))
      "\n"))
    "\n")))

(for ([pkg pkgs])
  (printf "=== package: ~a ===\n\n" pkg)
  (define-values (collectibles non-collectibles)
    (case mode
      [(local)
       (get-license/local pkg #:build-deps? build-deps?)]
      [(global)
       (get-license/global pkg
                           #:build-deps? build-deps?
                           #:local? #f)]
      [(#f)
       (get-license/global pkg
                           #:build-deps? build-deps?
                           #:local? #t)]
      [else (error 'unreachable)]))
  (print-auditable (append collectibles non-collectibles)))
