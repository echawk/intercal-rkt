#lang setup/infotab

(define collection 'multi)
(define name "intercal")
(define version "0.1")
(define pkg-desc "INTERCAL implemented in Racket with a reader, normalizer, and macro-compiled runtime.")
(define license 'MIT)
(define deps '("roman-numeral" "brag"))
(define build-deps '("rackunit-lib" "scribble-lib" "racket-doc"))
(define scribblings '(("scribblings/intercal.scrbl" (multi-page) (language))
                      ("scribblings/programming-intercal.scrbl" (multi-page) (language))))
