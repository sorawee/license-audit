#lang racket/base

(provide get-license/local
         get-license/global

         (struct-out package)

         current-cache-time
         current-url)

(require racket/set
         racket/match
         racket/list
         racket/file
         net/url
         net/base64
         setup/getinfo
         pkg/lib
         json)

(define current-cache-time (make-parameter 3600))
(define current-url (make-parameter "https://pkgs.racket-lang.org/pkgs-all.json.gz"))

(struct package (name required-by license mode author tags) #:transparent)

;; filter-out-racket :: (listof package?) -> (listof package?)
;; base depends on a phantom package racket
;; (https://github.com/racket/racket/blob/master/pkgs/base/info.rkt)
;; which could cause confusion, so let's filter it out.
(define (filter-out-racket xs)
  (filter-not (match-lambda
                [(package "racket" _ _ _ _ _) #t]
                [_ #f])
              xs))

(define (resolve-meta-pkg pkg)
  (match pkg
    ["@"
     (append (resolve-meta-pkg "@-global")
             (resolve-meta-pkg "@-local"))]
    ["@-global"
     (for/list ([(key val) (in-hash (fetch (current-url)))])
       (symbol->string key))]
    ["@-local"
     (append (resolve-meta-pkg "@-local-user")
             (resolve-meta-pkg "@-local-installation"))]
    ["@-local-user"
     (for/list ([(key val) (in-hash (read-pkgs-db 'user))])
       key)]
    ["@-local-installation"
     (for/list ([(key val) (in-hash (read-pkgs-db 'installation))])
       key)]
    [_ #f]))

(define (get-license/local pkg
                           #:build-deps? [build-deps? #f]
                           #:seen [seen* (mutable-set)]
                           #:required-by [required-by #f])
  (define seen (set-copy seen*))
  (define *collectibles* '())
  (define *non-collectibles* '())
  (define (loop pkg required-by)
    (unless (set-member? seen pkg)
      (set-add! seen pkg)
      (define dir (pkg-directory pkg))
      (cond
        [dir
         (define get-info (get-info/full dir))

         (set! *collectibles*
               (cons (package pkg
                              required-by
                              (get-info 'license (λ () #f))
                              'local
                              #f
                              #f)
                     *collectibles*))

         (define direct-deps
           (for/list ([dep (extract-pkg-dependencies
                            get-info #:build-deps? build-deps?)])
             (match dep
               [(? string?) dep]
               [(cons dep _) dep])))

         (for ([dep direct-deps])
           (loop dep pkg))]
        [else
         (set! *non-collectibles*
               (cons (package pkg required-by #f 'unknown/local #f #f)
                     *non-collectibles*))])))

  (match (resolve-meta-pkg pkg)
    [#f (loop pkg required-by)]
    [pkgs (for ([subpkg (in-list pkgs)])
            (loop subpkg pkg))])

  (values *collectibles* (filter-out-racket *non-collectibles*)))

(define temp-path (build-path (find-system-path 'temp-dir) "license-audit"))
(define cache (make-hash))

(define (fetch url)
  (define (do-fetch)
    (call/input-url (string->url url)
                    get-pure-port
                    read-json))

  (hash-ref!
   cache url
   (λ ()
     (with-handlers ([exn:fail:filesystem? (λ (e) (do-fetch))])
       (unless (directory-exists? temp-path)
         (make-directory temp-path))

       (define path
         (build-path temp-path
                     (bytes->string/utf-8
                      (base64-encode (string->bytes/utf-8 url) #""))))

       (define should-update?
         (or (not (file-exists? path))
             (< (+ (file-or-directory-modify-seconds path) (current-cache-time))
                (current-seconds))))

       (when should-update?
         (with-output-to-file path
           (λ () (write (do-fetch)))))

       (file->value path)))))

(define (get-license/global
         pkg
         #:build-deps? [build-deps? #f]
         #:local? [local? #f])
  (define json (fetch (current-url)))
  (define seen (mutable-set))
  (define *collectibles* '())
  (define *non-collectibles* '())

  (define (loop pkg required-by this-local?)
    (unless (set-member? seen pkg)
      (cond
        [this-local?
         (define-values (collectibles non-collectibles)
           (get-license/local pkg
                              #:build-deps? build-deps?
                              #:seen seen
                              #:required-by required-by))
         (set-union! seen (list->set (map package-name collectibles)))
         (set! *collectibles* (append collectibles *collectibles*))
         (for ([pkg-dep (in-list non-collectibles)])
           (loop (package-name pkg-dep) (package-required-by pkg-dep) #f))]
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
              (for/list ([dep (in-list (hash-ref pkg-info
                                                 (if build-deps?
                                                     'dependencies
                                                     'rt-dependencies)))])
                (match dep
                  [(? string?) dep]
                  [(cons dep _) dep])))

            (for ([dep (in-list direct-deps)])
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

  (match (resolve-meta-pkg pkg)
    [#f (loop pkg #f local?)]
    [pkgs (for ([subpkg (in-list pkgs)])
            (loop subpkg pkg local?))])

  (values *collectibles* (filter-out-racket *non-collectibles*)))
