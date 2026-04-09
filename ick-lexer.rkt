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
    "TRY" "TRYING"
    "GIVE" "UP" "COME" "FROM"
    "NOTHING"
    ;; Gerunds.
    "CALCULATING" "FORGETTING" "RESUMING" "STASHING" "RETRIEVING"
    "IGNORING" "REMEMBERING" "ABSTAINING" "REINSTATING" "NEXTING"
    "READING"
    "WRITING"
    ))

(define (simple-subscript-start? w)
  (member w '("." ":" "," "*" "#")))

(define (consume-simple-subscript words start)
  (define first (list-ref words start))
  (cond
    [(member first '("." ":" "," "*"))
     (values (take (drop words start) 2) (+ start 2))]
    [(equal? first "#")
     (values (take (drop words start) 2) (+ start 2))]
    [else
     (values (list first) (add1 start))]))

(define (expand-packed-subscripts words)
  (let loop ([remaining words] [acc '()])
    (cond
      [(null? remaining) (reverse acc)]
      [(and (pair? remaining) (equal? (car remaining) "SUB"))
       (define base-acc (cons "SUB" acc))
       (let subloop ([idx (cdr remaining)] [sub-acc base-acc] [need-first? #t])
         (cond
           [(null? idx) (loop idx sub-acc)]
           [(simple-subscript-start? (car idx))
            (define-values (piece rest-index)
              (consume-simple-subscript idx 0))
            (define next-acc
              (append (reverse piece)
                      (if need-first?
                          sub-acc
                          (cons "SUB" sub-acc))))
            (subloop (drop idx (length piece)) next-acc #f)]
           [else (loop idx sub-acc)]))]
      [else
       (loop (cdr remaining) (cons (car remaining) acc))])))

(define (tokenize in)
  (define str (port->string in))

  ;; Replace some common "idioms".
  (define clean-str
    (string-replace
     (string-replace str "!" "'.")
     "DON'T" "DO NOT"))

  (define words
    (expand-packed-subscripts
     (regexp-match*
      #px"\\(|\\)|<-|~|\\$|#|\\+|\\.|:|\\*|,|&|\\?|!|%|'|\"|[0-9]+|[A-Za-z][A-Za-z0-9]*"
      clean-str)))

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
