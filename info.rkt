#lang setup/infotab

(define collection 'multi)
(define name "intercal")
(define version "0.1")
(define pkg-desc "INTERCAL implemented in Racket with a reader, normalizer, and macro-compiled runtime.")
(define license 'MIT)
(define deps '("base" "roman-numeral" "brag"))
(define build-deps '("rackunit-lib" "scribble-lib" "racket-doc"))
(define test-omit-paths
  '("compiled"
    "intercal/compiled"
    "intercal/lang/compiled"
    "presentation"
    "tests/compiled"
    "tools/compiled"
    "vend"
    "fib-ick.rkt"
    "fib-ick-expanded.rkt"
    "pow.rkt"))
