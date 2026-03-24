#lang racket
(require "ick.rkt"
         "ick-lexer.rkt"
         brag/support)

(provide parse-intercal)

(define (parse-intercal str)
  (define tokens (tokenize (open-input-string str)))
  (parse tokens))

;; (parse
;;  (tokenize
;;   (open-input-string
;;    "10 DO ASSIGN .I 5
;; 20 PLEASE NEXT 10
;; 30 DO READ OUT .I
;; 40 PLEASE GIVE UP")))
