#lang racket

;; suppress running tests on this file
(module test racket/base)

(require raco/command-name
         license-audit
         racket/cmdline
         text-table)

(define local? #f)
(define build-deps? #f)

(define pkgs
  (command-line
   #:program (short-program+command-name)
   #:once-each
   [("-l" "--local-only") "Only use local packages" (set! local? #t)]
   [("-b" "--build-time") "Include build-time dependencies" (set! build-deps? #t)]
   #:args pkgs
   pkgs))

(unless local?
  (raise-user-error "Global audit is not yet implemented"))

(define (format-req-by req-by)
  (cond
    [req-by
     (format "(required by: ~a)" req-by)]
    [else ""]))

(for ([pkg pkgs])
  (printf "=== package: ~a ===\n\n" pkg)
  (define-values (collectibles non-collectibles)
    (get-license/local pkg #:build-deps? build-deps?))
  (printf "Auditable packages:\n")

  (print-table
   #:border-style 'space
   #:row-sep? #f
   #:framed? #f
   (for/list ([pkg collectibles])
     (match-define (package name required-by license) pkg)
     (list (~a name " ")
           (~a (or license "no license indicated") " ")
           (format-req-by required-by))))

  (newline)
  (printf "Non-auditable packages:\n")
  (print-table
   #:border-style 'space
   #:row-sep? #f
   #:framed? #f
   (for/list ([pkg non-collectibles])
     (match-define (package name required-by _) pkg)
     (list (~a name " ")
           (format-req-by required-by))))
  (newline))
