#lang racket

;; suppress running tests on this file
(module test racket/base)

(require raco/command-name
         license-audit
         racket/cmdline
         text-table)

(define mode #f)
(define build-deps? #f)
(define group-by-author? #f)
(define no-main-dist? #f)
(define show-tags? #f)

(define pkgs
  (command-line
   #:program (short-program+command-name)
   #:once-any
   [("-l" "--local-only") "Only use local packages" (set! mode 'local)]
   [("-g" "--global-only") "Only use global packages" (set! mode 'global)]
   #:once-each
   [("--build-time") "Include build-time dependencies" (set! build-deps? #t)]
   [("--tags") "Show tags" (set! show-tags? #t)]
   [("--no-main-distribution") "Do not include packages in the main distribution"
                               (set! no-main-dist? #t)]
   [("--author") "Group by author" (set! group-by-author? #t)]
   #:args pkgs
   pkgs))

(define (wrap s #:width [width 32] #:extra [extra 0])
  (define extra-space (make-string extra #\space))
  (string-join
   (for/list ([slice (in-slice width (~a s))])
     (string-append (apply string slice) extra-space))
   "\n"))

(define (print-auditable pre-collectibles)
  (define collectibles
    (cond
      [group-by-author?
       (sort pre-collectibles string<?
             #:key (λ (p)
                     (define author (package-author p))
                     (cond
                       [author author]
                       [else ""])))]
      [else pre-collectibles]))
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
         (match-define (package name required-by license mode author tags) pkg)
         (append
          (cond
            [group-by-author? (list (wrap (or author "no information") #:extra 1))]
            [else '()])
          (list (case mode
                  [(local)  "[l] "]
                  [(global) "[g] "]
                  [(unknown/local) "[u] "]
                  [(unknown/global) "[u] "]
                  [else (error 'unreachable)])
                (wrap name #:extra 1)
                (cond
                  [required-by required-by]
                  [else "- "])
                (case mode
                  [(unknown/local unknown/global) "can't find the package "]
                  [else (wrap (or license "no license indicated") #:extra 1)]))
          (cond
            [show-tags? (list (wrap (or tags "no information")))]
            [else '()]))))
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
  (define-values (main-collectibles main-non-collectibles)
    (cond
      [no-main-dist?
       (case mode
         [(local)
          (get-license/local "main-distribution" #:build-deps? #t)]
         [else
          (get-license/global "main-distribution"
                              #:build-deps? #t
                              #:local? #f)])]
      [else (values '() '())]))
  (define-values (main-test-collectibles main-test-non-collectibles)
    (cond
      [no-main-dist?
       (case mode
         [(local)
          (get-license/local "main-distribution-test" #:build-deps? #t)]
         [else
          (get-license/global "main-distribution-test"
                              #:build-deps? #t
                              #:local? #f)])]
      [else (values '() '())]))
  (define excludes
    (for/set ([pkg (append main-collectibles
                           main-non-collectibles
                           main-test-collectibles
                           main-test-non-collectibles)])
      (package-name pkg)))
  (print-auditable
   (for/list ([pkg (append collectibles non-collectibles)]
              #:unless (set-member? excludes (package-name pkg)))
     pkg)))
