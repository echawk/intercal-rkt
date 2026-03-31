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
    "NOTHING"
    ;; Gerunds.
    "CALCULATING" "FORGETTING" "RESUMING" "STASHING" "RETRIEVING"
    "IGNORING" "REMEMBERING" "ABSTAINING" "REINSTATING" "NEXTING"
    "READING"
    "WRITING"
    ))

(define (tokenize in)
  (define str (port->string in))

  (define clean-str (string-replace str "!" "'."))

  (define words
    (regexp-match*
     #px"\\(|\\)|<-|~|\\$|#|\\+|\\.|:|\\*|,|&|\\?|V|!|%|'|\"|[0-9]+|[A-Za-z]+"
     clean-str))

  (for/list ([w words])
    (cond
      ;; numbers
      [(regexp-match #px"^[0-9]+$" w)
       (token 'NUMBER (string->number w))]

      ;; punctuation
      [(equal? w ".") (token 'DOT w)]
      [(equal? w ":") (token 'COLON w)]
      [(equal? w "*") (token 'STAR w)]
      [(equal? w ",") (token 'COMMA w)]
      [(equal? w "<-") (token 'GETS w)]
      [(equal? w "#") (token 'MESH w)]
      [(equal? w "'") (token 'SQUOTE w)]
      [(equal? w "\"") (token 'DQUOTE w)]
      [(equal? w "%") (token 'PERCENT w)]

      [(equal? w "$") (token 'MINGLE w)]
      [(equal? w "~") (token 'SELECT w)]

      [(equal? w "+") (token 'PLUS w)]

      ;; unary operations
      [(equal? w "&") (token 'UNARY_AND w)]
      [(equal? w "V") (token 'UNARY_OR w)]
      [(equal? w "!") (token 'UNARY_OR w)]
      [(equal? w "?") (token 'UNARY_XOR w)]

      ;; Parens for Labels.
      [(equal? w "(") (token 'LPAREN w)]
      [(equal? w ")") (token 'RPAREN w)]

      ;; Array access
      [(equal? w "SUB") (token 'SUB w)]

      ;; keywords
      [(member (string-upcase w) keywords)
       (token (string->symbol (string-upcase w)) w)]

      [else
       (token 'ID (string->symbol w))])))
