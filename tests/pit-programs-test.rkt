#lang racket

(require rackunit
         racket/runtime-path)

(define-runtime-path triangular-i-path "../pit/triangular.i")

(define (module-main-output path)
  (define intercal-main
    (parameterize ([current-output-port (open-output-string)])
      (dynamic-require path 'intercal-main)))
  (check-pred procedure? intercal-main)
  (with-output-to-string intercal-main))

(test-case "triangular tutorial program prints the first ten triangular numbers"
  (check-equal?
   (module-main-output triangular-i-path)
   (string-append
    "I\n"
    "III\n"
    "VI\n"
    "X\n"
    "XV\n"
    "XXI\n"
    "XXVIII\n"
    "XXXVI\n"
    "XLV\n"
    "LV\n")))
