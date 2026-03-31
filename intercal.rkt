#lang racket

(provide (except-out (all-from-out racket) read read-syntax)
         (all-from-out "sick.rkt")
         (rename-out [intercal-read read]
                     [intercal-read-syntax read-syntax]))

(require "sick.rkt"
         "ick-lexer.rkt"
         "ick-bnf.rkt"
         "ick-normalize.rkt")

(define (clean-intercal-string str)
  (define lines (string-split str "\n"))

  ;; 1. Matches lines that start with a VALID operation or variable assignment.
  ;; It ensures DO/PLEASE is immediately followed by a real command (STASH, etc) or a variable [.:,;]
  (define valid-start-rx
    #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|MAYBE|%[0-9]+)[ \t]*)+(?:STASH|RETRIEVE|IGNORE|REMEMBER|ABSTAIN|REINSTATE|FORGET|RESUME|READ|WRITE|COME|GIVE|NOTHING|[.:,;]|\\()")

  ;; 2. Matches multi-line continuations.
  ;; These are indented lines containing ONLY valid INTERCAL math/logic symbols, quotes, and numbers.
  ;; This cleanly catches wrapped math while rejecting "DOUBLE OR SINGLE PRECISION OVERFLOW"
  (define continuation-rx
    #px"^[ \t]+[\"'?&V!#0-9.:,~$\\s]+$")

  (define cleaned-lines
    (filter (lambda (l)
              (or (regexp-match? valid-start-rx l)
                  (regexp-match? continuation-rx l)))
            lines))

  (string-join cleaned-lines "\n"))

;; 2. THE READER FUNCTIONS
(define (intercal-read in)
  (syntax->datum (intercal-read-syntax #f in)))

(define (intercal-read-syntax src in)
  (define source-code (clean-intercal-string (port->string in)))

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
