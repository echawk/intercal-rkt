#lang racket
(require roman-numeral)
(require rackunit)
(require racket/system)
(require "../sick.rkt")

(define (run-racket-file path [stdin ""])
  (define racket-exe
    (or (find-executable-path "racket")
        (error "Could not locate racket executable")))
  (define-values (proc out in err)
    (subprocess #f #f #f racket-exe path))
  (display stdin in)
  (close-output-port in)
  (define stdout (port->string out))
  (define stderr (port->string err))
  (close-input-port out)
  (close-input-port err)
  (subprocess-wait proc)
  (values (subprocess-status proc) stdout stderr))

(define (run-shell-command cmd)
  (define shell-exe
    (or (find-executable-path "sh")
        (error "Could not locate sh executable")))
  (define-values (proc out in err)
    (subprocess #f #f #f shell-exe "-lc" cmd))
  (close-output-port in)
  (define stdout (port->string out))
  (define stderr (port->string err))
  (close-input-port out)
  (close-input-port err)
  (subprocess-wait proc)
  (values (subprocess-status proc) stdout stderr))


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
  ;; (check-equal? (unary-or 5 ) 135 "Unary OR on 5")
  )

(define (slow-int->bits n width)
  (let loop ([n n] [w width] [acc '()])
    (if (= w 0)
        acc
        (loop (arithmetic-shift n -1)
              (sub1 w)
              (cons (bitwise-and n 1) acc)))))

(define (slow-bits->int bit-list)
  (foldl (lambda (bit acc) (bitwise-ior (arithmetic-shift acc 1) bit))
         0
         bit-list))

(define (slow-intercal-select val mask width)
  (let* ([val-bits (slow-int->bits val width)]
         [mask-bits (slow-int->bits mask width)]
         [selected-bits
          (filter-map (lambda (v m) (if (= m 1) v #f))
                      val-bits mask-bits)])
    (slow-bits->int selected-bits)))

(define (slow-intercal-mingle a b width)
  (define a-bits (slow-int->bits a width))
  (define b-bits (slow-int->bits b width))
  (slow-bits->int (flatten (map list a-bits b-bits))))

(define (slow-intercal-unary op-proc val width)
  (define bits (slow-int->bits val width))
  (define rotated-bits (cons (last bits) (drop-right bits 1)))
  (slow-bits->int (map op-proc bits rotated-bits)))

(define (expanded-sick-module-source stx)
  (format "~s"
          (syntax->datum
           (expand
            #`(module sick-expand-test racket
                (require "../sick.rkt")
                #,stx)))))

(test-case "optimized bit operators preserve reference semantics"
  (define sample-8 '(0 1 2 3 5 7 15 16 31 85 170 255))
  (define sample-16 '(0 1 2 3 5 7 15 16 31 255 256 257 1023 32767 32768 65535))
  (define sample-32 '(0 1 2 3 5 7 15 16 31 255 256 257 65535 65536 65537 2147483648 4294967295))

  (for* ([a (in-list sample-8)]
         [b (in-list sample-8)])
    (check-equal? (intercal-mingle a b 8)
                  (slow-intercal-mingle a b 8))
    (check-equal? (intercal-select a b 8)
                  (slow-intercal-select a b 8)))

  (for* ([a (in-list sample-16)]
         [b (in-list sample-16)])
    (check-equal? (intercal-mingle a b 16)
                  (slow-intercal-mingle a b 16))
    (check-equal? (intercal-select a b 16)
                  (slow-intercal-select a b 16))
    (check-equal? (mingle-16 a b)
                  (slow-intercal-mingle a b 16))
    (check-equal? (select-16 a b)
                  (slow-intercal-select a b 16)))

  (for* ([a (in-list sample-32)]
         [b (in-list sample-32)])
    (check-equal? (intercal-select a b 32)
                  (slow-intercal-select a b 32))
    (check-equal? (select-32 a b)
                  (slow-intercal-select a b 32)))

  (for ([v (in-list sample-8)])
    (check-equal? (intercal-unary bitwise-and v 8)
                  (slow-intercal-unary bitwise-and v 8))
    (check-equal? (intercal-unary bitwise-ior v 8)
                  (slow-intercal-unary bitwise-ior v 8))
    (check-equal? (intercal-unary bitwise-xor v 8)
                  (slow-intercal-unary bitwise-xor v 8)))

  (for ([v (in-list sample-16)])
    (check-equal? (intercal-unary bitwise-and v 16)
                  (slow-intercal-unary bitwise-and v 16))
    (check-equal? (intercal-unary bitwise-ior v 16)
                  (slow-intercal-unary bitwise-ior v 16))
    (check-equal? (intercal-unary bitwise-xor v 16)
                  (slow-intercal-unary bitwise-xor v 16))
    (check-equal? (unary-and-16 v)
                  (slow-intercal-unary bitwise-and v 16))
    (check-equal? (unary-or-16 v)
                  (slow-intercal-unary bitwise-ior v 16))
    (check-equal? (unary-xor-16 v)
                  (slow-intercal-unary bitwise-xor v 16)))

  (for ([v (in-list sample-32)])
    (check-equal? (intercal-unary bitwise-and v 32)
                  (slow-intercal-unary bitwise-and v 32))
    (check-equal? (intercal-unary bitwise-ior v 32)
                  (slow-intercal-unary bitwise-ior v 32))
    (check-equal? (intercal-unary bitwise-xor v 32)
                  (slow-intercal-unary bitwise-xor v 32))
    (check-equal? (unary-and-32 v)
                  (slow-intercal-unary bitwise-and v 32))
    (check-equal? (unary-or-32 v)
                  (slow-intercal-unary bitwise-ior v 32))
    (check-equal? (unary-xor-32 v)
                  (slow-intercal-unary bitwise-xor v 32))))

(test-case "SELECT width follows the right operand width in generated code"
  (define expanded-source
    (expanded-sick-module-source
     #'(sick-program
        (10 (do (assign |.202| (mesh 511))))
        (20 (do (assign |.1|
                        (select
                         (unary-xor
                          (mingle
                           (select |.202| |.202|)
                           (mesh 32768)))
                         (mingle (mesh 16384) (mesh 16384))))))
        (30 (do (read-out |.1|)))
        (40 (please (give-up))))))
  (check-true (regexp-match? #rx"select-32" expanded-source)))

(test-case "unlambda allocator SELECT expression keeps twospot width"
  (check-equal?
   (call-with-values
   (thunk
     (sick-program
      (10 (do (assign |.202| (mesh 511))))
      (20 (do (assign |.1|
                      (select
                       (unary-xor
                        (mingle
                         (select |.202| |.202|)
                         (mesh 32768)))
                       (mingle (mesh 16384) (mesh 16384))))))
      (30 (do (read-out |.1|)))
      (40 (please (give-up)))))
    list)
   (list 2)))

(test-case "abstain analysis marks only lines that can actually be abstained"
  (check-equal?
   (sort
    (compute-abstain-guard-lines
     '((10 _ do 100 #f #f #f (assign .X (mesh 1)))
       (20 _ do 100 #f #f #f (read-out .X))
       (30 _ do 100 #f #f #f (give-up))))
    <)
   '())
  (check-equal?
   (sort
    (compute-abstain-guard-lines
     '((10 100 do 100 #f #f #f (assign .X (mesh 1)))
       (20 _ do 100 #f #f #f (abstain 100))
       (30 _ do 100 #f #f #f (read-out .X))))
    <)
   '(10))
  (check-equal?
   (sort
    (compute-abstain-guard-lines
     '((10 _ do 100 #f #f #f (read-out .X))
       (20 _ do 100 #f #f #f (abstain-gerunds-once reading-out))
       (30 _ do 100 #f #f #f (assign .X (mesh 1)))))
    <)
   '(10))
  (check-equal?
   (sort
    (compute-abstain-guard-lines
     '((10 _ do 100 #f #t #f (read-out .X))
       (20 _ do 100 #f #f #f (give-up))))
    <)
   '(10))
  (check-equal?
   (sort
    (compute-abstain-guard-lines
     '((10 _ do 100 #t #f #f (give-up))
       (20 _ do 100 #f #f #f (read-out .X))))
    <)
   '(10)))

(test-case "ignore analysis marks only variables that can actually be ignored"
  (check-equal?
   (sort
    (compute-ignore-guard-vars
     '((10 _ do 100 #f #f #f (assign .X (mesh 1)))
       (20 _ do 100 #f #f #f (read-out .X))
       (30 _ do 100 #f #f #f (give-up))))
    symbol<?)
   '())
  (check-equal?
   (sort
    (compute-ignore-guard-vars
     '((10 _ do 100 #f #f #f (ignore .X |,A|))
       (20 _ do 100 #f #f #f (remember .Y))
       (30 _ do 100 #f #f #f (assign .X (mesh 1)))))
    string<? #:key symbol->string)
   '(|,A| .X .Y)))

(test-case "COME FROM analysis marks only labels that can actually be hijacked"
  (check-equal?
   (sort
    (compute-come-from-guard-labels
     '((10 _ do 100 #f #f #f (assign .X (mesh 1)))
       (20 _ do 100 #f #f #f (read-out .X))
       (30 _ do 100 #f #f #f (give-up))))
    <)
   '())
  (check-equal?
   (sort
    (compute-come-from-guard-labels
     '((10 100 do 100 #f #f #f (assign .X (mesh 1)))
       (20 _ do 100 #f #f #f (come-from 100))
       (30 200 do 100 #f #f #f (read-out .X))
       (40 _ do 100 #f #f #f (come-from (mesh 200)))))
    <)
   '(100 200)))

(test-case "abstain optimizer removes guard code from non-abstainable lines"
  (define no-abstain-source
    (expanded-sick-module-source
     #'(sick-program
        (10 (do (assign .X (mesh 'I))))
        (20 (do (read-out .X)))
        (30 (please (give-up))))))
  (define with-abstain-source
    (expanded-sick-module-source
     #'(sick-program
        (10 (do (assign .X (mesh 'I))))
        (20 (do (abstain 10)))
        (30 (please (give-up))))))
  (check-false (regexp-match? #rx"is-abstained\\?" no-abstain-source))
  (check-true (regexp-match? #rx"is-abstained\\?" with-abstain-source)))

(test-case "ignore optimizer removes table lookups for non-ignorable variables"
  (define no-ignore-source
    (expanded-sick-module-source
     #'(sick-program
        (10 (do (assign .X (mesh 'I))))
        (20 (do (write-in .X)))
        (30 (do (retrieve .X)))
        (40 (please (give-up))))))
  (define with-ignore-source
    (expanded-sick-module-source
     #'(sick-program
        (10 (do (ignore .X)))
        (20 (do (assign .X (mesh 'I))))
        (30 (do (write-in .X)))
        (40 (do (retrieve .X)))
        (50 (please (give-up))))))
  (check-false (regexp-match? #rx"hash-ref ignore-tbl" no-ignore-source))
  (check-true (regexp-match? #rx"hash-ref ignore-tbl" with-ignore-source)))

;; FIXME: fix test
;; (check-equal?
;;  (call-with-values
;;   (thunk
;;    (sick-program
;;     (do     (assign .I (mesh 'V))) ; .I = 5
;;     (do     (assign .II (mesh 'III))) ; .II = 3
;;     (please (assign :I (mingle .I .II))) ; :I = Mingle(5, 3) -> 39
;;     (do     (read-out :I)) ; Accumulate 39
;;     (do     (assign .III (unary-xor .I))) ; .III = XOR on 5 (returns 135 in 8-bit logic)
;;     (do     (read-out .III)) ; Accumulate 135
;;     (please (give-up))))
;;   list)
;;  (list 39 135))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .I (mesh 'III))))     ; .I = 3
    (20 (do (assign .RES (mesh 'I))))     ; .RES = 1 (constant for popping 1 level)

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
    (20 (do (next 40)))
    (30 (do (read-out (mesh 'I))))
    (35 (please (give-up)))
    (40 (do (read-out (mesh 'II))))
    (45 (do (resume (mesh 'I))))
    (50 (do (come-from 20)))
    (60 (do (read-out (mesh 'III))))
    (70 (please (give-up)))))
  list)
 (list 2 3)
 "COME FROM on a NEXT line triggers only when the saved NEXT entry is RESUMEd to")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (20 (do (next 40)))
    (30 (do (read-out (mesh 'I))))
    (35 (please (give-up)))
    (40 (do (read-out (mesh 'II))))
    (45 (do (resume (mesh 'I))))
    (50 (do (come-from 40)))
    (60 (do (read-out (mesh 'III))))
    (70 (please (give-up)))))
  list)
 (list 2 3)
 "COME FROM on the NEXT target label fires after the target statement finishes")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (20 (do (next 40)))
    (30 (do (read-out (mesh 'I))))
    (35 (please (give-up)))
    (40 (do (read-out (mesh 'II))))
    (45 (do (forget (mesh 'I))))
    (46 (please (give-up)))
    (50 (do (come-from 20)))
    (60 (do (read-out (mesh 'III))))
    (70 (please (give-up)))))
  list)
 (list 2)
 "FORGETting a NEXT entry prevents delayed COME FROM hijack")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (20 (do (next 60)))
    (30 (do (read-out (mesh 'I))))
    (35 (please (give-up)))
    (60 (do (next 90)))
    (70 (do (read-out (mesh 'II))))
    (80 (please (give-up)))
    (90 (do (read-out (mesh 'IV))))
    (95 (do (resume (mesh 'II))))
    (100 (do (come-from 20)))
    (110 (do (read-out (mesh 'III))))
    (120 (please (give-up)))
    (130 (do (come-from 60)))
    (140 (do (read-out (mesh 'V))))
    (150 (please (give-up)))))
  list)
 (list 4 3)
 "A larger RESUME only triggers delayed COME FROM for the entry actually resumed to")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .RES (mesh 'V))))
    (20 (do (next 40)))
    (30 (please (give-up)))
    (40 (do (forget .RES)))
    (50 (please (give-up)))))
  list)
 '()
 "FORGET saturates instead of erroring when asked to remove too many NEXT entries")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .ONE (mesh 'I))))
    (20 (do (next 60)))
    (30 (do (read-out (mesh 'I))))
    (40 (please (give-up)))
    (60 (do (next 90)))
    (70 (do (read-out (mesh 'II))))
    (80 (please (give-up)))
    (90 (do (resume .ONE)))))
  list)
 (list 2)
 "RESUME 1 returns to the most recent NEXT target")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .TWO (mesh 'II))))
    (20 (do (next 60)))
    (30 (do (read-out (mesh 'I))))
    (40 (please (give-up)))
    (60 (do (next 90)))
    (70 (do (read-out (mesh 'II))))
    (80 (please (give-up)))
    (90 (do (resume .TWO)))))
  list)
 (list 1)
 "RESUME 2 jumps to the last removed NEXT entry")

(check-exn
 exn:fail?
 (thunk
  (sick-program
   (10 (do (assign .ZERO (mesh 'OH))))
   (20 (do (next 40)))
   (30 (please (give-up)))
   (40 (do (resume .ZERO)))))
 "RESUME 0 raises the INTERCAL error")

(check-exn
 exn:fail?
 (thunk
  (sick-program
   (10 (do (assign .TWO (mesh 'II))))
   (20 (do (next 50)))
   (30 (do (resume .TWO)))
   (40 (please (give-up)))
   (50 (do (next 30)))))
 "RESUME to the current line re-enters it, then ruptures the emptied NEXT stack")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .ONE (mesh 'I))))
    (20 (do (abstain-gerunds (mesh 'II) calculating)))
    (30 (do (reinstate-gerunds calculating)))
    (40 (do (assign .I (mesh 'V))))
    (50 (do (read-out .I)))
    (60 (please (give-up)))))
  list)
 (list 0)
 "Computed gerund abstain stacks and reinstate removes one layer")

(check-exn
 exn:fail?
 (thunk
  (sick-program
   (10 (do (retrieve .I)))
   (20 (please (give-up)))))
 "Retrieve without stash raises the INTERCAL error instead of raw car/cdr failure")


(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .I (mesh 'III))))     ; .I = 3
    (20 (do (assign .RES (mesh 'I))))     ; .RES = 1

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
    (10 (do (assign .I (mesh 'III))))    ; .I = 3
    (20 (do (read-out .I)))             ; Output 3. Control flow expects to go to 30...
    (30 (please (give-up)))             ; ...but we NEVER reach this give-up!

    ;; --- The Hijacker ---
    (40 (do (come-from 20)))            ; Intercepts control immediately after line 20
    (50 (do (assign .I (sick-dec .I)))) ; Decrement to 2
    (60 (do (read-out .I)))             ; Output 2
    (70 (please (give-up)))))            ; End program cleanly
  list)
 (list 3 2))

;; (displayln "Testing non-deterministic COME FROM (Outputs will vary run-to-run)")
;; (sick-program
;;  (do (assign .I (mesh 'I)))
;;  (20 (do (read-out .I)))
;;  (do (come-from 20))
;;  (do (read-out 999))
;;  (please (give-up))
;;  (do (come-from 20))
;;  (do (read-out 888))
;;  (please (give-up)))

;; (sick-program
;;  (10 (please (assign .I (mesh 'X))))
;;  (20 (do (stash .I)))
;;  (30 (do (assign .II (mingle (mesh 'V) (mesh 'III)))))
;;  (40 (please (retrieve .I)))
;;  (50 (please (come-from 20)))
;;  (55 (do (read-out .I)))
;;  (60 (please (give-up))))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign *I (mesh 'V))))        ; Dimension 32-bit array *I to size 5
    (20 (do (assign (sub *I 1) (mesh 'X))))  ; *I[1] = 10
    (30 (do (assign (sub *I 5) (mesh 'III)))) ; *I[5] = 3
    (40 (do (read-out *I)))               ; Output all elements: (10 0 0 0 3)
    (50 (please (give-up)))))
  list)
 (list 10 0 0 0 3))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign *M (dimension (mesh 'II) (mesh 'III)))))
    (20 (do (assign (sub *M (mesh 'I) (mesh 'I)) (mesh 'V))))
    (30 (do (assign (sub *M (mesh 'II) (mesh 'III)) (mesh 'X))))
    (40 (do (read-out (sub *M (mesh 'I) (mesh 'I)))))
    (50 (do (read-out (sub *M (mesh 'II) (mesh 'III)))))
    (60 (please (give-up)))))
  list)
 (list 5 10))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign *M (dimension (mesh 'II) (mesh 'II)))))
    (20 (do (assign (sub *M (mesh 'II) (mesh 'I)) (mesh 'VII))))
    (30 (do (assign .X (sub (sub *M (mesh 'II)) (mesh 'I)))))
    (40 (do (read-out .X)))
    (50 (please (give-up)))))
  list)
 (list 7)
 "Nested SUB expressions flatten and read multidimensional arrays correctly")

(check-exn
 exn:fail?
 (thunk
  (sick-program
   (10 (do (assign .X 65536)))
   (20 (please (give-up)))))
 "Assigning a twospot-sized value to a onespot raises E275")

(check-exn
 exn:fail?
 (thunk
  (sick-program
   (10 (do (assign :X 4294967296)))
   (20 (please (give-up)))))
 "Assigning beyond twospot range raises E533")

(check-exn
 exn:fail?
 (thunk
  (parameterize ([current-input-port (open-input-string "")])
    (sick-program
     (10 (do (write-in .X)))
     (20 (please (give-up))))))
 "Numeric WRITE IN at EOF raises the INTERCAL error instead of a host exception")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign |;A| (dimension (mesh 'I)))))
    (20 (do (assign (sub |;A| (mesh 'I)) 42)))
    (30 (do (assign :X (sub |;A| (mesh 'I)))))
    (40 (do (read-out :X)))
    (50 (please (give-up)))))
  list)
 (list 42)
 "Semicolon arrays are tracked as twospot arrays and can be read back")


(define (string->sick-program str)
  (let ((len (string-length str)))
    (cons
     'sick-program
     (append
      (cons
       '(do (assign *I (mesh xi)))
       (map
        (lambda (p)
          (let ((i (car p))
                (m (cadr p)))
            `(do (assign (sub *I ,i) ,m))))
        (map list
             (range 1 (add1 len))
             (map (lambda (rn) `(mesh ,rn))
                  (map string->symbol
                       (map number->roman
                            (map char->integer
                                 (string->list str))))))))
      (list
       '(do (read-out *I))
       '(please (give-up)))))))

;; (map integer->char
;;      (call-with-values
;;       (thunk
;;        (eval
;;         (string->sick-program "hello world")))
;;       list))

;; FIXME: fix actual string output in sick.rkt
;; (check-equal?
;;  (call-with-values
;;   (thunk
;;    (sick-program
;;     (10 (do (assign *1 (mesh 'XIII))))      ;; DO ,1 <- #13
;;     (20 (please (assign (sub *1 1) 238)))  ;; PLEASE DO ,1 SUB #1 <- #238
;;     (30 (do (assign (sub *1 2) 108)))      ;; DO ,1 SUB #2 <- #108
;;     (40 (do (assign (sub *1 3) 112)))      ;; DO ,1 SUB #3 <- #112
;;     (50 (do (assign (sub *1 4) 0)))        ;; DO ,1 SUB #4 <- #0
;;     (60 (do (assign (sub *1 5) 64)))       ;; DO ,1 SUB #5 <- #64
;;     (70 (do (assign (sub *1 6) 194)))      ;; DO ,1 SUB #6 <- #194
;;     (80 (do (assign (sub *1 7) 48)))       ;; DO ,1 SUB #7 <- #48
;;     (90 (please (assign (sub *1 8) 22)))   ;; PLEASE DO ,1 SUB #8 <- #22
;;     (100 (do (assign (sub *1 9) 248)))     ;; DO ,1 SUB #9 <- #248
;;     (110 (do (assign (sub *1 10) 168)))    ;; DO ,1 SUB #10 <- #168
;;     (120 (do (assign (sub *1 11) 24)))     ;; DO ,1 SUB #11 <- #24
;;     (130 (do (assign (sub *1 12) 16)))     ;; DO ,1 SUB #12 <- #16
;;     (140 (do (assign (sub *1 13) 162)))    ;; DO ,1 SUB #13 <- #162
;;     (150 (do (read-out *1)))               ;; PLEASE READ OUT ,1
;;     (160 (please (give-up)))))
;;   list)
;;  (list 238 108 112 0 64 194 48 22 248 168 24 16 162))

;; (check-equal?
;;  (call-with-values
;;   (thunk
;;    (sick-program-core
;;     (1 (100 (_ (do (assign .I (mesh 'I))))))        ; .I = 1
;;     (2 (100 (_ (do (abstain (10))))))              ; Disable label 10
;;     (3 (100 (10 (do (assign .I (mesh 'V))))))       ; SKIPPED: .I would become 5
;;     (4 (100 (_ (do (read-out .I)))))               ; Outputs 1, not 5
;;     (5 (100 (_ (please (give-up)))))))
;;   list)
;;  (list 1))

;; (check-equal?
;;  (call-with-values
;;   (thunk
;;    (sick-program-core
;;     (1 (100 (_ (do (assign .I (mesh 'I))))))        ; .I = 1
;;     (2 (100 (_ (do (abstain (100))))))             ; Disable the hijacker AT label 100
;;     (3 (100 (20 (do (read-out .I)))))              ; Output 1. Control naturally flows to line 4.
;;     (4 (100 (_ (do (assign .I (mesh 'II))))))       ; .I = 2
;;     (5 (100 (_ (do (read-out .I)))))               ; Output 2.
;;     (6 (100 (_ (please (give-up)))))               ; End cleanly.

;;     ;; --- The Hijacker ---
;;     (7 (100 (100 (do (come-from 20)))))            ; Tries to intercept after 20, but is ABSTAINED!
;;     (8 (100 (_ (do (assign .I (mesh 'V))))))        ; Should NEVER run.
;;     (9 (100 (_ (do (read-out .I)))))
;;     (10 (100 (_ (please (give-up)))))))
;;   list)
;;  (list 1 2))

;; (check-equal?
;;  (call-with-values
;;   (thunk
;;    (sick-program-core
;;     (1 (100 (_ (do (assign *I (mesh 'V))))))        ; Dimension 32-bit array *I to 5
;;     (2 (100 (_ (do (abstain (30))))))              ; Disable the assignment at label 30
;;     (3 (100 (10 (do (assign (sub *I 1) (mesh 'I)))))); *I[1] = 1
;;     (4 (100 (30 (do (assign (sub *I 3) (mesh 'V)))))); SKIPPED
;;     (5 (100 (40 (do (assign (sub *I 5) (mesh 'X)))))); *I[5] = 10
;;     (6 (100 (_ (do (read-out *I)))))               ; Should be (1 0 0 0 10)
;;     (7 (100 (_ (please (give-up)))))))
;;   list)
;;  (list 1 0 0 0 10))


(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (do (assign .I (mesh 'I)))     ; .I = 1
    (do (ignore .I))              ; .I is now read-only
    (do (assign .I (mesh 'V)))     ; SKIPPED: Silently fails because .I is ignored
    (do (read-out .I))            ; Outputs 1
    (do (remember .I))            ; .I is read/write again
    (do (assign .I (mesh 'X)))     ; .I = 10
    (do (read-out .I))            ; Outputs 10
    (please (give-up))))
  list)
 (list 1 10)
 "Ignore and Remember scalar logic")


(check-equal?
 (call-with-values
  (thunk
   ;; Simulating standard input for the WRITE IN command
   (with-input-from-string "ONE TWO THREE"
     (thunk
      (sick-program
       (do (write-in .I))        ; Reads "123", converts to 123
       (do (read-out .I))
       (please (give-up))))))
  list)
 (list 123)
 "Write In from STDIN")

(check-equal?
 (with-output-to-string
   (thunk
    (sick-program
     (do (assign *I (mesh 'XIII)))
     (do (assign (sub *I (mesh 'I)) (mesh 234)))
     (do (assign (sub *I (mesh 'II)) (mesh 112)))
     (do (assign (sub *I (mesh 'III)) (mesh 112)))
     (do (assign (sub *I (mesh 'IV)) (mesh 0)))
     (do (assign (sub *I (mesh 'V)) (mesh 64)))
     (do (assign (sub *I (mesh 'VI)) (mesh 194)))
     (do (assign (sub *I (mesh 'VII)) (mesh 48)))
     (do (assign (sub *I (mesh 'VIII)) (mesh 22)))
     (do (assign (sub *I (mesh 'IX)) (mesh 248)))
     (do (assign (sub *I (mesh 'X)) (mesh 168)))
     (do (assign (sub *I (mesh 'XI)) (mesh 24)))
     (do (assign (sub *I (mesh 'XII)) (mesh 16)))
     (do (assign (sub *I (mesh 'XIII)) (mesh 214)))
     (do (read-out *I))
     (please (give-up)))))
 "hello, world\n"
 "Array READ OUT uses C-INTERCAL tape output")



;; FIXME: fix test.
;; (check-equal?
;;  (call-with-values
;;   (thunk
;;    (sick-program
;;     (do     (assign .I (mesh 'V))) ; .I = 5
;;     (do     (assign .II (mesh 'III))) ; .II = 3
;;     (please (assign :I (mingle .I .II))) ; :I = Mingle(5, 3) -> 39
;;     (do     (read-out :I)) ; Accumulate 39
;;     (do     (assign .III (unary-xor .I))) ; .III = XOR on 5 (returns 135 in 8-bit logic)
;;     (do     (read-out .III)) ; Accumulate 135
;;     (please (give-up))))
;;   list)
;;  (list 39 135))

;;(displayln "-----")

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign .I (mesh 'III))))     ; .I = 3
    (20 (do (assign .RES (mesh 'I))))     ; .RES = 1 (constant for popping 1 level)

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
    (10 (do (assign .I (mesh 'III))))     ; .I = 3
    (20 (do (assign .RES (mesh 'I))))     ; .RES = 1

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
    (10 (do (assign .I (mesh 'III))))    ; .I = 3
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
 (do (assign .I (mesh 'I)))
 (20 (do (read-out .I)))
 (do (come-from 20))
 (do (read-out 999))
 (please (give-up))
 (do (come-from 20))
 (do (read-out 888))
 (please (give-up)))

(sick-program
 (10 (please (assign .I (mesh 'X))))
 (20 (do (stash .I)))
 (30 (do (assign .II (mingle (mesh 'V) (mesh 'III)))))
 (40 (please (retrieve .I)))
 (50 (please (come-from 20)))
 (55 (do (read-out .I)))
 (60 (please (give-up))))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign *I (mesh 'V))))        ; Dimension 32-bit array *I to size 5
    (20 (do (assign (sub *I 1) (mesh 'X))))  ; *I[1] = 10
    (30 (do (assign (sub *I 5) (mesh 'III)))) ; *I[5] = 3
    (40 (do (read-out *I)))               ; Output all elements: (10 0 0 0 3)
    (50 (please (give-up)))))
  list)
 (list 10 0 0 0 3))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (10 (do (assign *1 (mesh 'XIII))))      ;; DO ,1 <- #13
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

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (do (assign .I (mesh 'I)))     ; .I = 1
    (do (ignore .I))              ; .I is now read-only
    (do (assign .I (mesh 'V)))     ; SKIPPED: Silently fails because .I is ignored
    (do (read-out .I))            ; Outputs 1
    (do (remember .I))            ; .I is read/write again
    (do (assign .I (mesh 'X)))     ; .I = 10
    (do (read-out .I))            ; Outputs 10
    (please (give-up))))
  list)
 (list 1 10)
 "Ignore and Remember scalar logic")

(check-equal?
 (call-with-values
  (thunk
   ;; Simulating standard input for the WRITE IN command
   (with-input-from-string "ONE TWO THREE"
     (thunk
      (sick-program
       (do (write-in .I))        ; Reads "123", converts to 123
       (do (read-out .I))
       (please (give-up))))))
  list)
 (list 123)
 "Write In from STDIN")

(displayln "----")
(time
 (sick-program
  (1 (do nothing))
  (please (once (come-from (13))))
  (please (once (come-from (mesh 11))))
  (do (come-from (1)))
  (do (once (read-out (mesh 1))))
  (6 (do (again (read-out (mesh 2)))))
  (do (read-out (mesh 3)))
  (do (once (abstain (6))))
  (do (not (once (read-out (mesh 4)))))
  (10 (do (not (again (read-out (mesh 5))))))
  (11 (do (once (reinstate (10)))))
  (do (read-out (mesh 6)))
  (13 (do (not (read-out (mesh 7)))))
  (do (reinstate (17)))
  (15 (do (once (next 19))))
  (16 (please (read-out (mesh 8))))
  (17 (do (not (again (next (15))))))
  (please (give-up))
  (19 (please (read-out (mesh 9))))
  (do (next (16)))))


 "
    DO .9 <- #16
    DO .10 <- #0
    DO .11 <- #1

(1) PLEASE READ OUT .11
    DO .1 <- .10
    DO .2 <- .11
    PLEASE (1009) NEXT
    DO .10 <- .11
    DO .11 <- .3

    DO (3) NEXT
    DO (1) NEXT

(3) DO (4) NEXT
    PLEASE GIVE UP

(4) DO .1 <- .9
    DO .2 <- #1
    PLEASE (1010) NEXT
    DO .9 <- .3
    DO .1 <- '.9~.9'~#1
    PLEASE (1020) NEXT
    DO RESUME .1
"

'(sick-program
  (do (assign .IX (mesh 16)))
  (do (assign .X (mesh 0)))
  (do (assign .XI (mesh 1)))

  (1 (please (read-out .XI)))
  (do (assign .I .X))
  (do (assign .II .XI))
  (please (next 1009))
  (do (assign .X .XI))
  (do (assign .XI .III))

  (do (next 3))
  (do (next 1))

  (3 (do (next 4)))
  (please (give-up))

  (4 (do (assign .I .IX)))
  (do (assign .II (mesh 1)))
  (please (next 1010))
  (do (assign .IX .III))
  ;;(do (assign .1 ))
  ;; '.9~.9'~#1

  (please (next 1020))
  (do (resume .I))
  )


(require "../ick-lexer.rkt")
(require "../ick-bnf.rkt")
(require "../ick-driver.rkt")
(require "../ick-normalize.rkt")
;; (parse
;;  (tokenize
;;   (open-input-string
;;    "
;; (1)	DO NOTHING
;; 	PLEASE COME FROM (13) ONCE
;; 	PLEASE COME FROM #11 ONCE
;; 	DO COME FROM (1)
;; 	DO READ OUT #1 ONCE
;; (6)	DO READ OUT #2 AGAIN
;; 	DO READ OUT #3
;; 	DO ABSTAIN FROM (6) ONCE
;; 	DON'T READ OUT #4 ONCE
;; (10)	DON'T READ OUT #5 AGAIN
;; (11)   	DO REINSTATE (10) ONCE
;; 	DO READ OUT #6
;; (13)	DON'T READ OUT #7
;; 	DO REINSTATE (17)
;; (15)   	DO (19) NEXT ONCE
;; (16)   	PLEASE READ OUT #8
;; (17)	DON'T (15) NEXT AGAIN
;; 	PLEASE GIVE UP
;; (19)	PLEASE READ OUT #9
;; 	DO (16) NEXT


;; ")))
(normalize-program
 (syntax->datum
  (parse
   (tokenize
    (open-input-string
     "
(1)	DO NOTHING
	PLEASE COME FROM (13) ONCE
	PLEASE COME FROM #11 ONCE
	DO COME FROM (1)
	DO READ OUT #1 ONCE
(6)	DO READ OUT #2 AGAIN
	DO READ OUT #3
	DO ABSTAIN FROM (6) ONCE
	DO NOT READ OUT #4 ONCE
(10)	DO NOT READ OUT #5 AGAIN
(11)   	DO REINSTATE (10) ONCE
	DO READ OUT #6
(13)	DO NOT READ OUT #7
	DO REINSTATE (17)
(15)   	DO (19) NEXT ONCE
(16)   	PLEASE READ OUT #8
(17)	DO NOT (15) NEXT AGAIN
	PLEASE GIVE UP
(19)	PLEASE READ OUT #9
	DO (16) NEXT


")))))

;; (expand-once
;;  '(sick-program/syslib
;;    (do (assign |.9| (mesh 10)))
;;    (do (assign |.10| (mesh 0)))
;;    (do (assign |.11| (mesh 1)))
;;    (1 (please (read-out |.11|)))
;;    (do (assign |.1| |.10|))
;;    (do (assign |.2| |.11|))
;;    (please (next 1009))
;;    (do (assign |.10| |.11|))
;;    (do (assign |.11| |.3|))
;;    (do (next 3))
;;    (do (next 1))
;;    (3 (do (next 4)))
;;    (please (give-up))
;;    (4 (do (assign |.1| |.9|)))
;;    (do (assign |.2| (mesh 1)))
;;    (please (next 1010))
;;    (do (assign |.9| |.3|))
;;    (do (assign |.1| (select (select |.9| |.9|) (mesh 1))))
;;    (please (next 1020))
;;    (do (resume |.1|))))
