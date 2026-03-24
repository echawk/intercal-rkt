#lang racket

(require (for-syntax roman-numeral)
         (for-syntax syntax/parse))

(define-syntax (mesh stx)
  (syntax-parse stx
    [(_ rn:identifier)
     (let* ([n (roman->number (symbol->string (syntax-e #'rn)))])
       (datum->syntax stx n))]))

;; Helper: Integer to fixed-width list of bits (MSB to LSB)
(define (int->bits n width)
  (let loop ([n n] [w width] [acc '()])
    (if (= w 0)
        acc
        (loop (arithmetic-shift n -1)
              (sub1 w)
              (cons (bitwise-and n 1) acc)))))

;; Helper: List of bits to Integer
(define (bits->int bit-list)
  (foldl (lambda (bit acc) (bitwise-ior (arithmetic-shift acc 1) bit))
         0
         bit-list))


(define (intercal-select val mask width)
  (let* ([val-bits (int->bits val width)]
         [mask-bits (int->bits mask width)]
         ;; Keep val bits only where mask bit is 1
         [selected-bits
          (filter-map (lambda (v m) (if (= m 1) v #f))
                      val-bits mask-bits)])
    ;; bits->int naturally packs them to the right!
    (bits->int selected-bits)))

(define (intercal-mingle a b width)
  (let ([a-bits (int->bits a width)]
        [b-bits (int->bits b width)])
    ;; Zip the lists together: '( (a1 b1) (a2 b2) ... )
    ;; Then flatten them: '(a1 b1 a2 b2 ...)
    (let ([mingled-bits (flatten (map list a-bits b-bits))])
      (bits->int mingled-bits))))


(require rackunit)

;; (Assume the ALU functions from the previous response are defined here)

(define (intercal-unary op-proc val width)
  (let* ([bits (int->bits val width)]
         ;; Right rotation: move the last bit to the front
         [rotated-bits (cons (last bits) (drop-right bits 1))])
    (let ([result-bits (map op-proc bits rotated-bits)])
      (bits->int result-bits))))


(define (mingle a b) (intercal-mingle a b 8))
(define (select a b) (intercal-select a b 8))
(define (unary-and val) (intercal-unary bitwise-and val 8))
(define (unary-or val)  (intercal-unary bitwise-ior val 8))
(define (unary-xor val) (intercal-unary bitwise-xor val 8))

(test-case "INTERCAL Bitwise Operations"
  ;; MINGLE ($): Interleaves bits of 5 (0101) and 3 (0011)
  ;; Padded to 8 bits: a = 00000101, b = 00000011
  ;; Mingled: 00 00 00 00 00 01 00 11 -> 0000000000010011 (binary) -> 19 (decimal)
  (check-equal? (intercal-mingle 5 3 8) 39 "Mingle 5 and 3")

  ;; SELECT (~): Selects bits of 5 (0101) using mask 3 (0011)
  ;; val = 00000101, mask = 00000011
  ;; Keeps only the last two bits of val (0, 1), packed to the right -> 01 -> 1
  (check-equal? (intercal-select 5 3 8) 1 "Select 5 using mask 3")

  ;; UNARY AND (&): val AND right-rotated val
  ;; val = 5 (00000101), rotated = 10000010
  ;; 00000101 AND 10000010 = 00000000 -> 0
  (check-equal? (unary-and 5 ) 0 "Unary AND on 5")

  ;; UNARY OR (V): val OR right-rotated val
  ;; 00000101 OR 10000010 = 10000111 -> 135
  (check-equal? (unary-or 5 ) 135 "Unary OR on 5"))

(define (sick-dec val) (max 0 (sub1 val)))

(require (for-syntax racket/base syntax/parse racket/list racket/dict racket/string))

(define-syntax (sick-program stx)
  (syntax-parse stx
    [(_ (label ((~seq (~or (~datum do) (~datum please)) ...) op)) ...)

     ;; --- COMPILE TIME ANALYSIS (Phase 1) ---
     (define lines (syntax->list #'(label ...)))
     (define ops (syntax->list #'(op ...)))

     ;; 1. Build the non-deterministic COME FROM map
     (define grouped-come-froms
       (let ([h (make-hash)])
         (for-each (lambda (lbl op)
                     (syntax-parse op
                       [((~datum come-from) target)
                        (let ([t (syntax-e #'target)]
                              [l (syntax-e lbl)])
                          (hash-set! h t (cons l (hash-ref h t '()))))]
                       [_ (void)]))
                   lines ops)
         (hash-map h cons)))

     ;; 2. Dynamically extract all variables (.I, :V, etc.)
     (define all-vars
        (remove-duplicates
         (filter (lambda (sym)
                   (and (symbol? sym)
                        (let ([str (symbol->string sym)])
                          ;; Check for scalar or array prefixes
                          (member (substring str 0 1) '("." ":" "*")))))
                 (flatten (map syntax->datum ops)))))

     ;; Generate (define var 0) and (define var-stack '()) for each
     (define var-definitions
       (map (lambda (v)
              (define vid (datum->syntax stx v))
              (define vstack (datum->syntax stx (string->symbol (string-append (symbol->string v) "-stack"))))
              (define str (symbol->string v))
              (if (string-prefix? str "*")
                  #`(begin (define #,vid #f) (define #,vstack '()))
                  #`(begin (define #,vid 0)  (define #,vstack '()))))
            all-vars))

     ;; 3. Generate Case Clauses
       (define case-clauses
         (let loop ([lbls lines] [operations ops])
           (cond
             [(null? lbls) '()]
             [else
              (define current-lbl (car lbls))
              (define next-lbl (if (null? (cdr lbls)) #f (cadr lbls)))

              (define compiled-op
                (syntax-parse (car operations)

                  [((~datum assign) ((~datum sub) arr idx) val)
                   #`(vector-set! arr (sub1 idx) val)]

                  [((~datum assign) var val)
                   (let ([var-str (symbol->string (syntax-e #'var))])
                     (cond
                       ;; Array Dimensioning (if var starts with , or *)
                       [(string-prefix? var-str "*")
                        #`(set! var (make-vector val 0))]
                       ;; Standard Scalar
                       [else #`(set! var val)]))]

                  [((~datum stash) var ...)
                   #`(begin
                       #,@(map (lambda (v)
                                 (let ([vstack (datum->syntax stx (string->symbol (string-append (symbol->string (syntax-e v)) "-stack")))])
                                   #`(set! #,vstack (cons #,v #,vstack))))
                               (syntax->list #'(var ...))))]
                  [((~datum retrieve) var ...)
                   #`(begin
                       #,@(map (lambda (v)
                                 (let ([vstack (datum->syntax stx (string->symbol (string-append (symbol->string (syntax-e v)) "-stack")))])
                                   #`(begin
                                       (set! #,v (car #,vstack))
                                       (set! #,vstack (cdr #,vstack)))))
                               (syntax->list #'(var ...))))]

                  [((~datum read-out) var)
                   #`(let ([v var])
                       (if (vector? v)
                           (set! output-acc (append (reverse (vector->list v)) output-acc))
                           (set! output-acc (cons v output-acc))))]

                  [((~datum come-from) target)
                   #`(void)]
                  [((~datum next) target)
                   #`(set! next-stack (cons '#,(if next-lbl next-lbl #f) next-stack))]
                  [((~datum resume) var)
                   #`(void)]
                  [((~datum forget) var)
                   #`(void)] ;; Handled in the branch logic
                  [((~datum give-up))
                   #`(void)]
                  [(~datum give-up) #'(void)]
                  [_ #`(void)]))

              (define branch
                #`[(#,current-lbl)
                   #,compiled-op
                   #,(syntax-parse (car operations)
                       [((~datum give-up))
                        #`(apply values (reverse output-acc))]
                       [(~datum give-up)
                        #`(apply values (reverse output-acc))]
                       [((~datum next) target)
                        #`(loop (get-actual-next #,current-lbl target))]
                       [((~datum resume) var)
                        #`(if (> var 0)
                              (let ([return-pc (list-ref next-stack (- var 1))])
                                (set! next-stack (drop next-stack var))
                                (loop (get-actual-next #,current-lbl return-pc)))
                              (loop (get-actual-next #,current-lbl '#,next-lbl)))]
                       [((~datum forget) var)
                        #`(begin
                            (if (> var 0)
                                (set! next-stack (drop next-stack var))
                                (void))
                            (loop (get-actual-next #,current-lbl '#,next-lbl)))]
                       [_
                        #`(loop (get-actual-next #,current-lbl '#,next-lbl))])])

              (cons branch (loop (cdr lbls) (cdr operations)))])))

     ;; --- CODE EMISSION (Phase 0) ---
     #`(let ()
         #,@var-definitions
         (define output-acc '())
         (define next-stack '())

         ;; Inject the compile-time grouping map into the runtime
         (define cf-map '#,grouped-come-froms)

         ;; Runtime Router: Checks if the executed line was hijacked.
         (define (get-actual-next executed-lbl natural-next)
           (let ([hijackers (dict-ref cf-map executed-lbl '())])
             (if (null? hijackers)
                 natural-next
                 (list-ref hijackers (random (length hijackers))))))

         (define (run)
           (let loop ([pc #,(syntax-e (car lines))])
             (case pc
               #,@case-clauses
               [else (error "Fell off graph! PC:" pc)])))
         (run))]))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do     (assign .I (mesh V))))                ; .I = 5
    (20 (do     (assign .II (mesh III))))             ; .II = 3
    (30 (please (assign :I (mingle .I .II))))         ; :I = Mingle(5, 3) -> 39
    (40 (do     (read-out :I)))                       ; Accumulate 39
    (50 (do     (assign .III (unary-xor .I))))        ; .III = XOR on 5 (returns 135 in 8-bit logic)
    (60 (do     (read-out .III)))                     ; Accumulate 135
    (70 (please (give-up)))))
  list)
 (list 39 135))

;;(displayln "-----")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .I (mesh III))))     ; .I = 3
    (20 (do (assign .RES (mesh I))))     ; .RES = 1 (constant for popping 1 level)

    ;; --- Main Program ---
    (30 (do (next 60)))                  ; Call subroutine! Pushes 40 to stack.
    (40 (do (read-out .I)))              ; We return here! Output the modified value.
    (50 (please (give-up)))              ; End the program cleanly

    ;; --- Subroutine ---
    (60 (do (read-out .I)))              ; Output 3
    (70 (do (assign .I (sick-dec .I))))  ; Decrement to 2
    (80 (do (resume .RES)))))            ; Pop 1 item (which is 40) and jump back to it!
  list)
 (list 3 2))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .I (mesh III))))     ; .I = 3
    (20 (do (assign .RES (mesh I))))     ; .RES = 1

    ;; --- Main Program ---
    (30 (do (next 60)))                  ; Call subroutine! Pushes 40 to stack.
    (40 (do (read-out .I)))              ; We should NEVER reach here.
    (50 (please (give-up)))

    ;; --- Subroutine ---
    (60 (do (read-out .I)))              ; Output 3
    (70 (do (forget .RES)))              ; Delete 40 from the stack. Does NOT jump.
    (80 (do (assign .I (sick-dec .I))))  ; Decrement to 2
    (90 (do (read-out .I)))              ; Output 2
    (100 (please (give-up)))))            ; End program
  list)
 (list 3 2))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .I (mesh III))))    ; .I = 3
    (20 (do (read-out .I)))             ; Output 3. Control flow expects to go to 30...
    (30 (please (give-up)))             ; ...but we NEVER reach this give-up!

    ;; --- The Hijacker ---
    (40 (do (come-from 20)))            ; Intercepts control immediately after line 20
    (50 (do (assign .I (sick-dec .I)))) ; Decrement to 2
    (60 (do (read-out .I)))             ; Output 2
    (70 (please (give-up)))))            ; End program cleanly
  list)
 (list 3 2))

(displayln "Testing non-deterministic COME FROM (Outputs will vary run-to-run)")
(sick-program
  (10 (do (assign .I (mesh I))))
  (20 (do (read-out .I)))          ;; Both 30 and 50 want to hijack this!
  (30 (do (come-from 20)))         ;; Fixed macro syntax bug here
  (40 (do (read-out 999)))
  (45 (please (give-up)))
  (50 (do (come-from 20)))         ;; Fixed macro syntax bug here
  (60 (do (read-out 888)))
  (70 (please (give-up))))

;; FIXME: does not work.
;; (sick-program
;;   (10 (please (assign .I (mesh X))))
;;   (20 (stash .I))
;;   (30 (assign .II (mingle (mesh V) (mesh III))))
;;   (40 (please (retrieve .I)))
;;   (50 (come-from 20))
;;   (55 (read-out .I))
;;   (60 (please (give-up))))

(check-equal?
   (call-with-values
    (thunk
     (sick-program
      (10 (do (assign *I (mesh V))))        ; Dimension 32-bit array *I to size 5
      (20 (do (assign (sub *I 1) (mesh X))))  ; *I[1] = 10
      (30 (do (assign (sub *I 5) (mesh III)))) ; *I[5] = 3
      (40 (do (read-out *I)))               ; Output all elements: (10 0 0 0 3)
      (50 (please (give-up)))))
    list)
   (list 10 0 0 0 3))

(require roman-numeral)

(define (string->sick-program str)
  (let ((len (string-length str)))
    (cons
     'sick-program
     (append
      (cons
       '(10 (do (assign *I (mesh xi))))
       (map
        (lambda (p)
          (let ((i (car p))
                (m (cadr p)))
            `(,(* 10 (add1 i)) (do (assign (sub *I ,i) ,m)))))
        (map list
             (range 1 (add1 len))
             (map (lambda (rn) `(mesh ,rn))
                  (map string->symbol
                       (map number->roman
                            (map char->integer
                                 (string->list str))))))))
      (list
       `(,(* 10 (+ 2 len)) (do (read-out *I)))
       `(,(* 10 (+ 3 len)) (give-up)))))))

;; (map integer->char
;;      (call-with-values
;;       (thunk
;;        (eval
;;         (string->sick-program "hello world")))
;;       list))



(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign *1 (mesh XIII))))      ;; DO ,1 <- #13
    (20 (please (assign (sub *1 1) 238)))  ;; PLEASE DO ,1 SUB #1 <- #238
    (30 (do (assign (sub *1 2) 108)))      ;; DO ,1 SUB #2 <- #108
    (40 (do (assign (sub *1 3) 112)))      ;; DO ,1 SUB #3 <- #112
    (50 (do (assign (sub *1 4) 0)))        ;; DO ,1 SUB #4 <- #0
    (60 (do (assign (sub *1 5) 64)))       ;; DO ,1 SUB #5 <- #64
    (70 (do (assign (sub *1 6) 194)))      ;; DO ,1 SUB #6 <- #194
    (80 (do (assign (sub *1 7) 48)))       ;; DO ,1 SUB #7 <- #48
    (90 (please (assign (sub *1 8) 22)))   ;; PLEASE DO ,1 SUB #8 <- #22
    (100 (do (assign (sub *1 9) 248)))     ;; DO ,1 SUB #9 <- #248
    (110 (do (assign (sub *1 10) 168)))    ;; DO ,1 SUB #10 <- #168
    (120 (do (assign (sub *1 11) 24)))     ;; DO ,1 SUB #11 <- #24
    (130 (do (assign (sub *1 12) 16)))     ;; DO ,1 SUB #12 <- #16
    (140 (do (assign (sub *1 13) 162)))    ;; DO ,1 SUB #13 <- #162
    (150 (do (read-out *1)))               ;; PLEASE READ OUT ,1
    (160 (please (give-up)))))
  list)
 (list 238 108 112 0 64 194 48 22 248 168 24 16 162))

