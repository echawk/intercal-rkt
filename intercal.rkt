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
  (define token-rx
    #px"\\(|\\)|<-|~|\\$|#|\\+|\\.|:|\\*|,|&|\\?|V|!|%|'|\"|[0-9]+|[A-Za-z]+")

  (define (parseable-line-prefix line)
    (define tokens
      (regexp-match*
       token-rx
       (string-replace
        (string-replace line "!" "'.")
        "DON'T" "DO NOT")))
    (for/or ([n (in-range (length tokens) 0 -1)])
      (define candidate (string-join (take tokens n) " "))
      (with-handlers ([exn:fail? (lambda (_) #f)])
        (parse (tokenize (open-input-string candidate)))
        candidate)))

  ;; 1. Matches lines that start with a VALID operation or variable assignment.
  ;; It ensures DO/PLEASE is immediately followed by a real command (STASH, etc) or a variable [.:,;]
  (define valid-start-rx
    #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|MAYBE|%[0-9]+)[ \t]*)+(?:STASH|RETRIEVE|IGNORE|REMEMBER|ABSTAIN|REINSTATE|FORGET|RESUME|READ|WRITE|COME|GIVE|NOTHING|[.:,;]|\\()")

  ;; 2. Matches multi-line continuations.
  ;; These are indented continuation lines containing compact expression tokens
  ;; (including SUB) but no free-form prose spacing.
  (define continuation-rx
    #px"^[ \t]+[\"'?&V!#0-9.:,~$A-Za-z]+$")

  ;; 3. Matches statement prefixes that are syntactically incomplete on their own,
  ;; but are expected to continue on the next indented line.
  (define incomplete-start-rx
    #px"^(?:.*(?:<-|RESUME|FORGET|STASH|RETRIEVE|READ OUT|WRITE IN|ABSTAIN FROM|REINSTATE|SUB|BY|\\$|~|&|V|\\?|['\"]))[ \t]*$")

  (define cleaned-lines
    (filter values
                 (map (lambda (l)
                        (cond
                          [(regexp-match? valid-start-rx l)
                           (if (regexp-match? incomplete-start-rx l)
                               l
                               (parseable-line-prefix l))]
                          [(regexp-match? continuation-rx l) l]
                          [else #f]))
                 lines)))

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
            (call-with-values (lambda () ,normalized-ast)
              (lambda ignored (void))))))

      ;; Return EOF on the second pass so Racket stops reading
      eof))

;; (let ((_ 'foo))
;;   (define (clean-intercal-string str)
;;     (define lines (string-split str "\n"))

;;     ;; 1. Matches lines that start with a VALID operation or variable assignment.
;;     ;; It ensures DO/PLEASE is immediately followed by a real command (STASH, etc) or a variable [.:,;]
;;     (define valid-start-rx
;;       #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|MAYBE|%[0-9]+)[ \t]*)+(?:STASH|RETRIEVE|IGNORE|REMEMBER|ABSTAIN|REINSTATE|FORGET|RESUME|READ|WRITE|COME|GIVE|NOTHING|[.:,;]|\\()")

;;     ;; 2. Matches multi-line continuations.
;;     ;; These are indented lines containing ONLY valid INTERCAL math/logic symbols, quotes, and numbers.
;;     ;; This cleanly catches wrapped math while rejecting "DOUBLE OR SINGLE PRECISION OVERFLOW"
;;     (define continuation-rx
;;       #px"^[ \t]+[\"'?&V!#0-9.:,~$\\s+-]+$")

;;     (define cleaned-lines
;;       (filter (lambda (l)
;;                 (or (regexp-match? valid-start-rx l)
;;                     (regexp-match? continuation-rx l)))
;;               lines))

;;     (string-join cleaned-lines "\n"))

;;   (normalize-program
;;    (syntax->datum
;;     (parse
;;      (tokenize
;;       (open-input-string
;;        (clean-intercal-string
;;         (file->string "syslib.i")
;;         ;;     "
;;         ;;        DO ,1 <- #2
;;         ;;        DO ,1 SUB #1 <- #10
;;         ;;        PLEASE DO ,1 SUB #2 <- #20
;;         ;;        DO READ OUT ,1 SUB #1
;;         ;;        PLEASE DO READ OUT ,1 SUB #2
;;         ;;        PLEASE GIVE UP

;;         ;; "
;;         )))))))
;; (normalize-program
;;  (syntax->datum
;;   (parse
;;    (tokenize
;;     (open-input-string
;;      "
;;     DO .9 <- #10
;;     DO .10 <- #0
;;     DO .11 <- #1

;; (1) PLEASE READ OUT .11
;;     DO .1 <- .10
;;     DO .2 <- .11
;;     PLEASE (1009) NEXT
;;     DO .10 <- .11
;;     DO .11 <- .3

;;     DO (3) NEXT
;;     DO (1) NEXT

;; (3) DO (4) NEXT
;;     PLEASE GIVE UP

;; (4) DO .1 <- .9
;;     DO .2 <- #1
;;     PLEASE (1010) NEXT
;;     DO .9 <- .3
;;     DO .1 <- '.9~.9'~#1
;;     PLEASE (1020) NEXT
;;     DO RESUME .1

;; ")))))
