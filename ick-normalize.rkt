#lang racket

(provide normalize-program)

(define (normalize-subscript-chain base subs)
  `(sub ,(normalize-expr base) ,@subs))

(define (extract-subscripts ast)
  (match ast
    [`(sublist ,e) (list (normalize-expr e))]
    [`(sublist ,rest ,e) (append (extract-subscripts rest)
                                 (list (normalize-expr e)))]
    [_ (list (normalize-expr ast))]))

(define (extract-dimensions ast)
  (match ast
    [`(dim-list ,lhs "BY" ,rhs)
     (if (and (pair? lhs) (eq? (car lhs) 'dim-list))
         (append (extract-dimensions lhs)
                 (list (normalize-expr rhs)))
         (list (normalize-expr lhs)
               (normalize-expr rhs)))]
    [_ (list (normalize-expr ast))]))

;; =============================================================================
;; EXPRESSION NORMALIZER
;; Crushes the dense 6-layer CST from brag down into clean Lisp expressions.
;; =============================================================================
(define (normalize-expr ast)
  (match ast
    ;; 1. Pass-throughs (Collapse redundant layers)
    [`(expr ,e)    (normalize-expr e)]
    [`(mingle ,m)  (normalize-expr m)]
    [`(select ,s)  (normalize-expr s)]
    [`(unary ,u)   (normalize-expr u)]
    [`(postfix ,p) (normalize-expr p)]
    [`(primary ,p) (normalize-expr p)]

    ;; INTERCAL Grouping (Sparks and Rabbit Ears act as parentheses)
    [`(primary "'" ,e "'")  (normalize-expr e)]
    [`(primary "\"" ,e "\"") (normalize-expr e)]

    ;; 2. Binary Operators
    [`(mingle ,lhs "$" ,rhs) `(mingle ,(normalize-expr lhs) ,(normalize-expr rhs))]
    [`(select ,lhs "~" ,rhs) `(select ,(normalize-expr lhs) ,(normalize-expr rhs))]

    ;; 3. Unary Operators
    [`(unary "&" ,rhs) `(unary-and ,(normalize-expr rhs))]
    [`(unary "V" ,rhs) `(unary-or  ,(normalize-expr rhs))]
    [`(unary "?" ,rhs) `(unary-xor ,(normalize-expr rhs))]

    ;; 4. Subscripting (Arrays)
    [`(var ,base "SUB" ,subs)     (normalize-subscript-chain base (extract-subscripts subs))]
    [`(postfix ,base "SUB" ,subs) (normalize-subscript-chain base (extract-subscripts subs))]

    ;; 5. Variables (e.g. "." "I" -> '.I)
    [`(var ,prefix (ident ,id))
     (string->symbol (format "~a~a" prefix id))]

    ;; 6. Constants
    [`(primary "#" ,n)    `(mesh ,n)]
    [`(primary "MESH" ,n) `(mesh ,n)]

    ;; 7. Targets (for control flow labels)
    [`(target "(" ,n ")") n]
    [`(target "#" ,n)     `(mesh ,n)]
    [`(target "MESH" ,n)  `(mesh ,n)]
    [`(target ,n)         n]

    ;; Base Cases
    [(? number? n) n]
    [(? symbol? s) s]
    [(? string? s) s]
    [_ (error "Unknown expression shape:" ast)]))


;; =============================================================================
;; STASH / RETRIEVE HELPER
;; Recursively extracts variables, ignoring the '+' tokens from C-INTERCAL
;; =============================================================================
(define (extract-stash-vars ast)
  (match ast
    ;; Peel back layers
    [`(expr ,e)    (extract-stash-vars e)]
    [`(mingle ,m)  (extract-stash-vars m)]
    [`(select ,s)  (extract-stash-vars s)]
    [`(unary ,u)   (extract-stash-vars u)]
    [`(postfix ,p) (extract-stash-vars p)]
    [`(primary ,p) (extract-stash-vars p)]

    [`(primary "'" ,e "'")  (extract-stash-vars e)]
    [`(primary "\"" ,e "\"") (extract-stash-vars e)]

    [`(expr-list ,e1 "+" ,e2) (append (extract-stash-vars e1) (extract-stash-vars e2))]
    [`(expr-list ,e) (extract-stash-vars e)]

    ;; Split at binaries
    [`(mingle ,l "$" ,r) (append (extract-stash-vars l) (extract-stash-vars r))]
    [`(select ,l "~" ,r) (append (extract-stash-vars l) (extract-stash-vars r))]
    [`(unary ,op ,r)     (extract-stash-vars r)]

    ;; If it's a subscripted array, we stash the array, not the index
    [`(var ,base "SUB" ,idx)     (extract-stash-vars base)]
    [`(postfix ,base "SUB" ,idx) (extract-stash-vars base)]

    ;; Found a variable! Extract it.
    [`(var ,prefix (ident ,id))
     (list (string->symbol (format "~a~a" prefix id)))]

    [_ '()]))


;; =============================================================================
;; STATEMENT NORMALIZER
;; Maps semantic operations and weaves in Modifiers (PLEASE, NOT, ONCE, etc.)
;; =============================================================================
(define (normalize-op op)
  (match op
    [`(op (assign ,var "<-" ,rhs))
     (if (and (list? rhs) (eq? (car rhs) 'dim-list))
         `(assign ,(normalize-expr var) (dimension ,@(extract-dimensions rhs)))
         `(assign ,(normalize-expr var) ,(normalize-expr rhs)))]

    [`(op (next ,tgt "NEXT"))
     `(next ,(normalize-expr tgt))]

    [`(op (comefrom "COME" "FROM" ,tgt))
     `(come-from ,(normalize-expr tgt))]

    [`(op (readout "READ" "OUT" ,expr))
     `(read-out ,(normalize-expr expr))]

    [`(op (writein "WRITE" "IN" ,var))
     `(write-in ,(normalize-expr var))]

    [`(op (ignore "IGNORE" ,var))
     `(ignore ,(normalize-expr var))]

    [`(op (remember "REMEMBER" ,var))
     `(remember ,(normalize-expr var))]

    [`(op (stash "STASH" ,expr))
     `(stash ,@(extract-stash-vars expr))]

    [`(op (retrieve "RETRIEVE" ,expr))
     `(retrieve ,@(extract-stash-vars expr))]

    [`(op (forget "FORGET" ,expr))
     `(forget ,(normalize-expr expr))]

    [`(op (resume "RESUME" ,expr))
     `(resume ,(normalize-expr expr))]

    [`(op (abstain "ABSTAIN" "FROM" (abstain-target ,tgt)))
     `(abstain ,(normalize-expr tgt))]

    [`(op (reinstate "REINSTATE" (abstain-target ,tgt)))
     `(reinstate ,(normalize-expr tgt))]

    [`(op (giveup "GIVE" "UP"))
     `(give-up)]

    [`(op (nothing "NOTHING"))
     `(nothing)]

    [_ (error "Unrecognized operation:" op)]))

(define (normalize-stmt stmt)
  (match stmt
    [`(stmt ,parts ...)
     ;; Separate the structural components
     (define prefixes (filter (lambda (x) (and (list? x) (eq? (car x) 'do-prefix))) parts))
     (define postfixes (filter (lambda (x) (and (list? x) (eq? (car x) 'do-postfix))) parts))
     (define op-node (findf (lambda (x) (and (list? x) (eq? (car x) 'op))) parts))

     (define prefix-strs (map cadr prefixes))
     (define postfix-strs (map cadr postfixes))

     ;; Normalize the core semantic operation
     (define base-op (normalize-op op-node))

     ;; Wrap with state modifiers (Not -> Once -> Again)
     (define is-not (or (member "NOT" prefix-strs) (member "DON'T" prefix-strs)))
     (define with-not (if is-not `(not ,base-op) base-op))

     (define is-once (member "ONCE" postfix-strs))
     (define with-once (if is-once `(once ,with-not) with-not))

     (define is-again (member "AGAIN" postfix-strs))
     (define with-again (if is-again `(again ,with-once) with-once))

     ;; Look for a percentage modifier (e.g. `(do-prefix "%" 50)`)
     (define prob-prefix (findf (lambda (p) (equal? (cadr p) "%")) prefixes))
     (define with-prob (if prob-prefix `(% ,(caddr prob-prefix) ,with-again) with-again))

     ;; Wrap in the outermost politeness level
     (define is-please (member "PLEASE" prefix-strs))
     (if is-please
         `(please ,with-prob)
         `(do ,with-prob))]))

;; =============================================================================
;; AST REWRITER: FIX UNARY PRECEDENCE
;; =============================================================================
;; Turns `(mingle (unary-xor X) Y)` into `(unary-xor (mingle X Y))`
(define (fix-unary-ast ast)
  (match ast
    [`(mingle (,U ,X) ,Y)
     #:when (member U '(unary-and unary-or unary-xor))
     `(,U (mingle ,(fix-unary-ast X) ,(fix-unary-ast Y)))]
    [`(select (,U ,X) ,Y)
     #:when (member U '(unary-and unary-or unary-xor))
     `(,U (select ,(fix-unary-ast X) ,(fix-unary-ast Y)))]
    [(list elements ...)
     (map fix-unary-ast elements)]
    [other other]))

;; =============================================================================
;; TOP-LEVEL PROGRAM NORMALIZER
;; =============================================================================
(define (normalize-line line)
  (match line
    [`(line (label "(" ,n ")") ,stmt)
     `(,n ,(normalize-stmt stmt))]

    [`(line (label "(" ,n ")"))
     `(,n (do (give-up)))]

    [`(line ,stmt)
     (normalize-stmt stmt)]))

(define (normalize-program tree)
  (match tree
    [`(program ,lines ...)
     (fix-unary-ast
      `(sick-program/syslib
        ,@(map normalize-line lines)))]
    [_ (error "Unrecognized program structure:" tree)]))
