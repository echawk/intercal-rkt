#lang racket/base

(require (rename-in "../../intercal.rkt"
                    [read base-intercal-read]
                    [read-syntax base-intercal-read-syntax]))

(provide read
         read-syntax)

(define (read in)
  (parameterize ([current-intercal-language-module-path 'intercal])
    (base-intercal-read in)))

(define (read-syntax src in)
  (parameterize ([current-intercal-language-module-path 'intercal])
    (base-intercal-read-syntax src in)))
