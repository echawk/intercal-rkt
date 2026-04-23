#lang racket

(provide (except-out (all-from-out racket) read read-syntax)
         (all-from-out "sick.rkt")
         current-intercal-implementation-module-path
         current-intercal-language-module-path
         (rename-out [intercal-read read]
                     [intercal-read-syntax read-syntax]))

(require "sick.rkt"
         "ick-lexer.rkt"
         "ick-bnf.rkt"
         "ick-normalize.rkt")

(define clean-intercal-string clean-intercal-source)
(define current-intercal-implementation-module-path
  (make-parameter #f))
(define current-intercal-language-module-path
  current-intercal-implementation-module-path)

(define intercal-module-source
  (variable-reference->module-source
   (#%variable-reference)))

(define (default-implementation-module-path src)
  (cond
    [(path? src)
     (path->string
      (find-relative-path
       (or (path-only src) (current-directory))
       intercal-module-source))]
    [else "intercal.rkt"]))

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
        (define implementation-module-path
          (or (current-intercal-implementation-module-path)
              (default-implementation-module-path src)))
        (datum->syntax #f
         `(,#'module intercal-mod racket/base
            (require ,implementation-module-path)
            (provide intercal-main)
            (define (intercal-main)
              (parameterize ([sick-capture-output #f])
                (call-with-values (lambda () ,normalized-ast)
                  (lambda ignored (void)))))
            (module+ main
              (intercal-main)))))

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
