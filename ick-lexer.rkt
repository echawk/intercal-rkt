#lang racket
(require brag/support)

(provide tokenize)

(define keywords
  '("DO" "PLEASE" "NEXT" "READ" "OUT" "GIVE" "UP" "COME" "FROM"))

(define (tokenize in)
  (define str (port->string in))

  (define words
    (regexp-match*
     #px"\\(|\\)|<-|~|\\$|#|\\.|:|\\*|&|\\?|V|[0-9]+|[A-Za-z]+"
     str))

  (for/list ([w words])
    (cond
      ;; numbers
      [(regexp-match #px"^[0-9]+$" w)
       (token 'NUMBER (string->number w))]

      ;; punctuation
      [(equal? w ".") (token 'DOT w)]
      [(equal? w ":") (token 'COLON w)]
      [(equal? w "*") (token 'STAR w)]
      [(equal? w "<-") (token 'GETS w)]
      [(equal? w "#") (token 'MESH w)]

      [(equal? w "$") (token 'MINGLE w)]
      [(equal? w "~") (token 'SELECT w)]

      ;; unary operations
      [(equal? w "&") (token 'UNARY_AND w)]
      [(equal? w "V") (token 'UNARY_OR w)]
      [(equal? w "?") (token 'UNARY_XOR w)]


      ;; Array access
      [(equal? w "SUB") (token 'SUB w)]

      ;; keywords
      [(member (string-upcase w) keywords)
       (token (string->symbol (string-upcase w)) w)]

      [else
       (token 'ID (string->symbol w))])))
