#lang info
(define collection "license-audit")
(define deps '("base" "text-table" "pprint"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/license-audit.scrbl" ())))
(define pkg-desc "audit package licenses (including their dependencies)")
(define version "1.0")
(define pkg-authors '(sorawee))
(define license '(Apache-2.0 OR MIT))
(define raco-commands
  '(("license-audit"
     license-audit/raco
     "audit package licenses (including their dependencies)"
     #f)))
