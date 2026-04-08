#lang racket
(require roman-numeral)
(require rackunit)
(require "sick.rkt")


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


(require "ick-lexer.rkt")
(require "ick-bnf.rkt")
(require "ick-driver.rkt")
(require "ick-normalize.rkt")
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
