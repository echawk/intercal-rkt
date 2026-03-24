#lang racket
(require brag/support)

(provide tokenize)

(define (tokenize in)
  (define str (port->string in))

  (define words
    (regexp-match* #px"[.:*][A-Za-z0-9]+|[0-9]+|[A-Za-z]+" str))

  (for/list ([w words])
    (cond
      ;; numbers
      [(regexp-match #px"^[0-9]+$" w)
       (token 'NUMBER (string->number w))]

      ;; variables like .I :X *FOO
      [(regexp-match #px"^[.:*][A-Za-z0-9]+$" w)
       (token 'VAR w)]

      ;; keywords
      [else
       (token (string->symbol (string-upcase w)) w)])))
