#lang racket
(require rackunit
         "ick-driver.rkt"
         "ick-normalize.rkt")

(define (parse* s)
  (syntax->datum (parse-intercal s)))

(define (norm* s)
  (normalize-program (parse* s)))

(test-case "basic assignment"
  (check-equal?
   (norm* "(1) DO .I <- 5")
   '(sick-program/syslib
     (1 (do (assign .I 5))))))

(test-case "mesh constant"
  (check-equal?
   (norm* "(10) DO .I <- #5")
   '(sick-program/syslib
     (10 (do (assign .I (mesh 5)))))))

(test-case "mingle operator"
  (check-equal?
   (norm* "(10) DO :X <- .I $ #3")
   '(sick-program/syslib
     (10 (do (assign :X
                     (mingle .I (mesh 3))))))))

(test-case "select operator"
  (check-equal?
   (norm* "(10) DO :X <- .I ~ #3")
   '(sick-program/syslib
     (10 (do (assign :X
                     (select .I (mesh 3))))))))

(test-case "read out"
  (check-equal?
   (norm* "(10) DO READ OUT .I")
   '(sick-program/syslib
     (10 (do (read-out .I))))))

(test-case "next"
  (check-equal?
   (norm* "(10) DO (20) NEXT")
   '(sick-program/syslib
     (10 (do (next 20))))))

(test-case "give up"
  (check-equal?
   (norm* "(10) PLEASE GIVE UP")
   '(sick-program/syslib
     (10 (please (give-up))))))

(test-case "multi-line program"
  (check-equal?
   (norm*
    "(10) DO .I <- 5
     (20) DO READ OUT .I
     PLEASE GIVE UP")
   '(sick-program/syslib
     (10 (do (assign .I 5)))
     (20 (do (read-out .I)))
     (please (give-up)))))

(test-case "sub basic"
  (check-equal?
   (norm*
    "(10) DO .I SUB 1 <- #5")
   '(sick-program/syslib
     (10 (do (assign (sub .I 1) (mesh 5)))))))

(test-case "array dimension assignment"
  (check-equal?
   (norm*
    "(10) DO ,201 <- .200 BY #32767 BY .204")
   '(sick-program/syslib
     (10 (do (assign |,201| (dimension |.200| (mesh 32767) |.204|)))))))

(test-case "packed subscript chain"
  (check-equal?
   (norm*
    "(10) DO ,201SUB.201.202#7 <- ,202SUB.201.202#7")
   '(sick-program/syslib
     (10 (do (assign (sub (sub (sub |,201| |.201|) |.202|) (mesh 7))
                     (sub (sub (sub |,202| |.201|) |.202|) (mesh 7))))))))

;; (test-case "sub in expr"
;;   (parse*
;;    "10 DO :X <- .I SUB 1"))

(test-case "unary ops"
  (check-equal?
   (norm* "(10) DO .X <- & .I")
   '(sick-program/syslib
     (10 (do (assign .X
                     (unary-and .I))))))
  (check-equal?
   (norm* "(10) DO .X <- ? .I")
   '(sick-program/syslib
     (10 (do (assign .X
                     (unary-xor .I))))))
  (check-equal?
   (norm* "(10) DO .X <- V .I")
   '(sick-program/syslib
     (10 (do (assign .X
                     (unary-or .I)))))))

;; (test-case "mingle chain"
;;   (norm* "10 DO .X <- .A $ .B $ .C"))

;; (test-case "mixed mingle/select"
;;   (norm* "10 DO .X <- .A $ .B ~ .C"))

;; (test-case "unary + mingle"
;;   (norm* "10 DO .X <- & .A $ .B"))

;; (test-case "nested unary"
;;   (norm* "10 DO .X <- & V .A"))

;; (test-case "unary on expression"
;;   (norm* "10 DO .X <- & (.A $ .B)"))

;; (test-case "sub simple"
;;   (norm* "10 DO .X <- .A SUB 1"))

;; (test-case "nested sub"
;;   (norm* "10 DO .X <- .A SUB 1 SUB 2"))

;; (test-case "sub + mingle"
;;   (norm* "10 DO .X <- .A SUB 1 $ .B"))

;; (test-case "sub rhs expr"
;;   (norm* "10 DO .X <- .A SUB (.B $ 1)"))

;; (test-case "deep nesting"
;;   (norm*
;;    "10 DO .X <- .A $ .B $ .C $ .D $ .E"))

;; (test-case "control flow mix"
;;   (norm*
;;    "10 DO .I <- 5
;;     20 DO NEXT 40
;;     30 DO READ OUT .I
;;     40 PLEASE GIVE UP"))

;; (test-case "come-from"
;;   (parse*
;;    "10 DO .I <- 5
;;     20 DO COME FROM 10"))

;; (test-case "colon var"
;;   (norm* "10 DO :X <- 5"))

;; (test-case "star var"
;;   (norm* "10 DO *X <- 5"))

;; (test-case "constants in expr"
;;   (norm* "10 DO .X <- #5 $ #3"))

;; (test-case "constant select"
;;   (norm* "10 DO .X <- #5 ~ #3"))

;; (test-case "weird spacing"
;;   (norm*
;;    "10    DO     .X   <-    .A    $    #3"))

;; (test-case "long program"
;;   (norm*
;;    (string-join
;;     (for/list ([i (in-range 1 50)])
;;       (format "~a DO .X <- .X $ #1" (* 10 i)))
;;     "\n")))

;; (test-case "ambiguous unary"
;;   (norm* "(10) DO .X <- & .A $ .B"))

(test-case "everything together"
  (norm*
   "DO ,A <- 5
    DO .X <- & .A SUB 1 $ #3
    DO READ OUT .X
    PLEASE GIVE UP"))

;; ;; (test-case "unary binds tighter than SUB"
;; ;;   (norm* "10 DO .X <- & .A SUB 1"))

;; (test-case "triple unary"
;;   (norm* "10 DO .X <- & V ? .A"))

;; (test-case "sub + binary nesting"
;;   (norm* "10 DO .X <- .A SUB 1 $ .B SUB 2"))

;; (test-case "everything pathological"
;;   (norm*
;;    "10 DO *A <- 5
;;     20 DO .X <- & .A SUB 1 $ .B SUB 2 ~ #3
;;     30 DO READ OUT .X
;;     40 PLEASE GIVE UP"))

;; (test-case "deep sub chain"
;;   (norm*
;;    "10 DO .X <- .A SUB 1 SUB 2 SUB 3 SUB 4"))

;; (test-case "unary constant"
;;   (norm* "10 DO .X <- & #5"))

;; (test-case "const sub mix"
;;   (norm* "10 DO .X <- #5 $ .A SUB 1"))

;; (test-case "mixed casing"
;;   (norm* "10 do .x <- .a $ #3"))

(norm*
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
")
