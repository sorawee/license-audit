#lang racket/base

(provide get-license/local
         (struct-out package))

(require racket/set
         racket/match
         racket/list
         setup/getinfo
         pkg/lib)

(struct package (name required-by license) #:transparent)

(define (get-license/local pkg #:build-deps? [build-deps? #f])
  (define seen (mutable-set))
  (define collectibles '())
  (define non-collectibles '())
  (let loop ([pkg pkg] [required-by #f])
    (cond
      [(set-member? seen pkg) '()]
      [else
       (set-add! seen pkg)
       (define dir (pkg-directory pkg))
       (cond
         [dir
          (define get-info (get-info/full dir))
          (define direct-deps
            (for/list ([dep (extract-pkg-dependencies get-info
                                                      #:build-deps? build-deps?)])
              (match dep
                [(? string?) dep]
                [(cons dep _) dep])))

          (set! collectibles
                (cons (package pkg required-by (get-info 'license (λ () #f)))
                      collectibles))

          (for ([dep direct-deps])
            (loop dep pkg))]
         [else
          (set! non-collectibles
                (cons (package pkg required-by #f)
                      non-collectibles))])]))

  (values (reverse collectibles)
          ;; handle "racket" specially
          (filter-not (match-lambda
                        [(package "racket" _ _) #t]
                        [_ #f])
                      (reverse non-collectibles))))
