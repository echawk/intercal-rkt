#lang racket/base

(require racket/runtime-path)

(define-runtime-path root-intercal-path "../../intercal.rkt")

(define base-intercal-read
  (dynamic-require root-intercal-path 'read))

(define base-intercal-read-syntax
  (dynamic-require root-intercal-path 'read-syntax))

(define current-intercal-implementation-module-path
  (dynamic-require root-intercal-path
                   'current-intercal-implementation-module-path))

(provide read
         read-syntax)

(define installed-implementation-module-path
  `(file ,(path->string root-intercal-path)))

(define (read in)
  (parameterize ([current-intercal-implementation-module-path
                  installed-implementation-module-path])
    (base-intercal-read in)))

(define (read-syntax src in)
  (parameterize ([current-intercal-implementation-module-path
                  installed-implementation-module-path])
    (base-intercal-read-syntax src in)))
