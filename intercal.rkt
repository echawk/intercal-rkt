#lang racket

(provide (except-out (all-from-out racket) read read-syntax)
         (all-from-out "sick.rkt")
         (rename-out [intercal-read read]
                     [intercal-read-syntax read-syntax]))

(require "sick.rkt"
         "ick-lexer.rkt"
         "ick-bnf.rkt"
         "ick-normalize.rkt")

;; 2. THE READER FUNCTIONS
(define (intercal-read in)
  (syntax->datum (intercal-read-syntax #f in)))

(define (intercal-read-syntax src in)
  (define source-code (port->string in))

  (if (non-empty-string? (string-trim source-code))
      (let* ([parse-tree (parse (tokenize (open-input-string source-code)))]
             [normalized-ast (normalize-program (syntax->datum parse-tree))])

        ;; Explicitly build the module, using #'module to guarantee
        ;; Racket recognizes it as a core module declaration.
        (datum->syntax #f
         `(,#'module intercal-mod "intercal.rkt"
            ,normalized-ast)))

      ;; Return EOF on the second pass so Racket stops reading
      eof))
