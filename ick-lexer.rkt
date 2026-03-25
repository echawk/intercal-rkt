#lang racket
(require brag/support)

(provide tokenize)

(define keywords
  '("DO"
    "PLEASE" "MAYBE" "NOT" "ONCE" "AGAIN" ;; Should "SUB" be here?
    "BY" "FORGET" "RESUME" "STASH" "RETRIEVE" "IGNORE"
    "REMEMBER" "ABSTAIN" "REINSTATE"
    "NEXT"
    "READ" "OUT"
    "WRITE" "IN"
    "GIVE" "UP" "COME" "FROM"
    ;; Gerunds.
    "CALCULATING" "FORGETTING" "RESUMING" "STASHING" "RETRIEVING"
    "IGNORING" "REMEMBERING" "ABSTAINING" "REINSTATING" "NEXTING"
    "READING"
    "WRITING"
    ))

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
