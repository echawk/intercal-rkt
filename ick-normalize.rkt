#lang racket

(require "ick-bnf.rkt")
(require "ick-lexer.rkt")
(require "ick-driver.rkt")

(provide normalize-program)

(define (normalize stx)
  (match stx

    [`(expr "&" ,e) `(unary-and ,(normalize e))]
    [`(expr "V" ,e) `(unary-or ,(normalize e))]
    [`(expr "?" ,e) `(unary-xor ,(normalize e))]

    ;; unwrap redundant expr
    [`(expr ,x) (normalize x)]

    ;; constants
    [`(expr "#" ,n)
     `(const ,n)]

    ;; variable
    [`(var "." (ident ,id))
     `(var ,(string->symbol (format ".~a" id)))]

    [`(var ":" (ident ,id))
     `(var ,(string->symbol (format ":~a" id)))]

    [`(var "*" (ident ,id))
     `(var ,(string->symbol (format "*~a" id)))]

    ;; binary ops
    [`(expr ,lhs "$" ,rhs)
     `(mingle ,(normalize lhs) ,(normalize rhs))]

    [`(expr ,lhs "~" ,rhs)
     `(select ,(normalize lhs) ,(normalize rhs))]

    [`(var ,base "SUB" ,idx)
     `(sub ,(normalize base) ,(normalize idx))]
    ;; fallback
    [else stx]))


(define (normalize-op op)
  (match op
    [`(assign ,v "<-" ,e)
     `(assign ,(normalize v) ,(normalize e))]

    [`(readout "READ" "OUT" ,e)
     `(read-out ,(normalize e))]

    [`(next "NEXT" ,n)
     `(next ,n)]

    [`(giveup "GIVE" "UP")
     `(give-up)]

    [else op]))

(define (normalize-program tree)
  (match tree
    [`(program ,lines ...)
     `(sick-program
       ,@(map normalize-line lines))]))

(define (normalize-line line)
  (match line
    [`(line (label ,n)
            (stmt ,_ (op ,op)))
     `(,n (do ,(normalize-op op)))]))



;; (normalize-program
;;  (syntax->datum
;;   (parse
;;    (tokenize
;;     (open-input-string
;;      "10 DO .I <- 5
;;     20 PLEASE NEXT 10
;;     30 DO READ OUT .I
;;     40 PLEASE GIVE UP")))))
