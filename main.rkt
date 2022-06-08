#lang racket/base

(provide get-license/local
         get-license/global
         (struct-out package))

(require racket/set
         racket/match
         racket/list
         racket/runtime-path
         file/gunzip
         net/url
         setup/getinfo
         pkg/lib
         json)

(define-runtime-path test-data-path "data/pkgs-all.json.gz")

(struct package (name required-by license mode author tags) #:transparent)

(define (get-license/local pkg
                           #:build-deps? [build-deps? #f]
                           #:seen [seen* (mutable-set)]
                           #:required-by [required-by #f])
  (define seen (set-copy seen*))
  (define *collectibles* '())
  (define *non-collectibles* '())
  (let loop ([pkg pkg] [required-by required-by])
    (unless (set-member? seen pkg)
      (set-add! seen pkg)
      (define dir (pkg-directory pkg))
      (cond
        [dir
         (define get-info (get-info/full dir))

         (set! *collectibles*
               (cons (package pkg required-by (get-info 'license (λ () #f)) 'local #f #f)
                     *collectibles*))

         (define direct-deps
           (for/list ([dep (extract-pkg-dependencies get-info
                                                     #:build-deps? build-deps?)])
             (match dep
               [(? string?) dep]
               [(cons dep _) dep])))

         (for ([dep direct-deps])
           (loop dep pkg))]
        [else
         (set! *non-collectibles*
               (cons (package pkg required-by #f 'unknown/local #f #f)
                     *non-collectibles*))])))

  (values (reverse *collectibles*)
          ;; handle "racket" specially
          (filter-not (match-lambda
                        [(package "racket" _ _ _ _ _) #t]
                        [_ #f])
                      (reverse *non-collectibles*))))

(define caches (make-hash))

(define (call/url url proc)
  (proc (hash-ref! caches
                   url
                   (λ ()
                     (call/input-url
                      (string->url url)
                      get-pure-port
                      (λ (p)
                        (define-values (in out) (make-pipe))
                        (gunzip-through-ports p out)
                        (read-json in)))))))

(define (get-license/global
               pkg
               #:build-deps? [build-deps? #f]
               #:local? [local? #f]
               #:url [url (string-append "file://" (path->string test-data-path))])
  (call/url
   url
   (λ (json)
     (define seen (mutable-set))
     (define *collectibles* '())
     (define *non-collectibles* '())

     (define (loop pkg required-by this-local?)
       (unless (set-member? seen pkg)
         (cond
           [this-local?
            (define-values (collectibles non-collectibles)
              (get-license/local pkg #:build-deps? build-deps? #:seen seen))
            (set-union! seen (list->set (map package-name collectibles)))
            (set! *collectibles* (append collectibles *collectibles*))
            (for ([pkg-dep non-collectibles])
              (loop (package-name pkg-dep) pkg #f))]
           [else
            (set-add! seen pkg)
            (define pkg-info (hash-ref json (string->symbol pkg) #f))
            (cond
              [pkg-info
               (set! *collectibles*
                     (cons (package pkg
                                    required-by
                                    (hash-ref pkg-info 'license)
                                    'global
                                    (hash-ref pkg-info 'author)
                                    (hash-ref pkg-info 'tags))
                           *collectibles*))

               (define direct-deps
                 (for/list ([dep (hash-ref pkg-info
                                           (if build-deps?
                                               'dependencies
                                               'rt-dependencies))])
                   (match dep
                     [(? string?) dep]
                     [(cons dep _) dep])))

               (for ([dep direct-deps])
                 (loop dep pkg local?))]
              [else
               (set! *non-collectibles*
                     (cons (package pkg
                                    required-by
                                    #f
                                    'unknown/global
                                    #f
                                    #f)
                           *non-collectibles*))])])))

     (match pkg
       ["@"
        (for ([(pkg _) json])
          (loop (symbol->string pkg) "@" local?))]
       [_ (loop pkg #f local?)])

     (values (reverse *collectibles*)
             ;; handle "racket" specially
             (filter-not (match-lambda
                           [(package "racket" _ _ _ _ _) #t]
                           [_ #f])
                         (reverse *non-collectibles*))))))
