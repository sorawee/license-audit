#lang racket

;; suppress running tests on this file
(module test racket/base)

(require raco/command-name
         license-audit
         racket/cmdline
         text-table
         (prefix-in p: pprint))

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
   [("--no-main-distribution") "Do not include packages in the main distribution"
                               (set! no-main-dist? #t)]
   [("--tags") "Show tags" (set! show-tags? #t)]
   [("--authors") "Show authors (and group by them)" (set! group-by-author? #t)]
   #:args pkgs
   pkgs))

(when (and (or group-by-author? show-tags?) (not (eq? mode 'global)))
  (raise-user-error "Showing tags or authors requires --global-only"))

(define (wrap s #:width [width 32])
  (string-join
   (for/list ([slice (in-slice width (in-string (~a s)))])
     (apply string slice))
   "\n"))

(define (wrap-sexp d)
  (parameterize ([p:current-page-width 32])
    (p:pretty-format
     (let loop ([d (cond
                     [(string? d) (read (open-input-string d))]
                     [else d])])
       (cond
         [(list? d)
          (p:nest 1
                  (p:h-append (p:text "(")
                              (p:h-concat (p:apply-infix p:soft-line (map loop d)))
                              (p:text ")")))]
         [else (p:text (~a d))])))))

(define (print-output pkgs*)
  (printf "~a packages queried\n\n" (length pkgs*))
  (define (cmp<? a b)
    (cond
      [(and a b) (string<? a b)]
      [a #f]
      [b #t]
      [else #f]))
  (define pkgs
    (cond
      [group-by-author?
       (sort pkgs* cmp<? #:key package-author)]
      [else pkgs*]))
  (displayln
   (table->string
    #:border-style
    '(("╭─" "─" "─┬─" "─╮")
      ("│ " " " " │ " " │")
      ("├─" "─" "─┼─" "─┤")
      ("╰─" "─" "─┴─" "─╯"))
    #:row-sep? '(#t #f ...)
    (cons
     (append '(" * " "package name" "required by" "license")
             (cond
               [group-by-author? (list "author")]
               [else '()])
             (cond
               [show-tags? '("tags")]
               [else '()]))
     (for/list ([pkg (in-list pkgs)])
       (match-define (package name required-by license mode author tags) pkg)
       (append
        (list (case mode
                [(local)  "[l]"]
                [(global) "[g]"]
                [(unknown/local) "[u]"]
                [(unknown/global) "[U]"]
                [else (error 'unreachable)])
              (wrap name)
              (cond
                [required-by required-by]
                [else "-"])
              (case mode
                [(unknown/local unknown/global) "-"]
                [else (cond
                        [license (wrap-sexp license)]
                        [else "no license indicated"])]))
        (cond
          [group-by-author? (list (cond
                                    [author (string-join (string-split author " ") "\n")]
                                    [else "-"]))]
          [else '()])
        (cond
          [show-tags? (list (cond
                              [tags (wrap-sexp tags)]
                              [else "-"]))]
          [else '()])))))))

(for ([pkg (in-list pkgs)])
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
    (for/set ([pkg (in-sequences (in-list main-collectibles)
                                 (in-list main-non-collectibles)
                                 (in-list main-test-collectibles)
                                 (in-list main-test-non-collectibles))])
      (package-name pkg)))

  (print-output
   (for/list ([pkg (in-sequences (in-list (reverse collectibles))
                                 (in-list (reverse non-collectibles)))]
              #:unless (set-member? excludes (package-name pkg)))
     pkg)))
