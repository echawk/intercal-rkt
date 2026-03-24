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
   (norm* "10 DO .I <- 5")
   '(sick-program
     (10 (do (assign (var .I) 5))))))


(test-case "mesh constant"
  (check-equal?
   (norm* "10 DO .I <- #5")
   '(sick-program
     (10 (do (assign (var .I) (const 5)))))))

(test-case "mingle operator"
  (check-equal?
   (norm* "10 DO :X <- .I $ #3")
   '(sick-program
     (10 (do (assign (var :X)
                     (mingle (var .I) (const 3))))))))

(test-case "select operator"
  (check-equal?
   (norm* "10 DO :X <- .I ~ #3")
   '(sick-program
     (10 (do (assign (var :X)
                     (select (var .I) (const 3))))))))


(test-case "read out"
  (check-equal?
   (norm* "10 DO READ OUT .I")
   '(sick-program
     (10 (do (read-out (var .I)))))))


(test-case "next"
  (check-equal?
   (norm* "10 DO NEXT 20")
   '(sick-program
     (10 (do (next 20))))))

(test-case "give up"
  (check-equal?
   (norm* "10 PLEASE GIVE UP")
   '(sick-program
     (10 (do (give-up))))))


(test-case "multi-line program"
  (check-equal?
   (norm*
    "10 DO .I <- 5
     20 DO READ OUT .I
     30 PLEASE GIVE UP")
   '(sick-program
     (10 (do (assign (var .I) 5)))
     (20 (do (read-out (var .I))))
     (30 (do (give-up))))))

(test-case "sub basic"
  (check-equal?
   (parse*
    "10 DO .I SUB 1 <- 5")
   ;; just check parse shape, not normalize yet
   '(program
     (line
      (label 10)
      (stmt
       (polite "DO")
       (op
        (assign
         (var (var "." (ident I)) "SUB" (expr 1))
         "<-"
         (expr 5))))))))

(test-case "sub in expr"
  (parse*
   "10 DO :X <- .I SUB 1"))

(test-case "unary ops"
  (check-equal?
   (norm* "10 DO .X <- & .I")
   '(sick-program
     (10 (do (assign (var .X)
                     (unary-and (var .I)))))))
  (check-equal?
   (norm* "10 DO .X <- ? .I")
   '(sick-program
     (10 (do (assign (var .X)
                     (unary-xor (var .I)))))))
  (check-equal?
   (norm* "10 DO .X <- V .I")
   '(sick-program
     (10 (do (assign (var .X)
                     (unary-or (var .I))))))))

(test-case "mingle chain"
  (norm* "10 DO .X <- .A $ .B $ .C"))

(test-case "mixed mingle/select"
  (norm* "10 DO .X <- .A $ .B ~ .C"))

(test-case "unary + mingle"
  (norm* "10 DO .X <- & .A $ .B"))

(test-case "nested unary"
  (norm* "10 DO .X <- & V .A"))

;; (test-case "unary on expression"
;;   (norm* "10 DO .X <- & (.A $ .B)"))

(test-case "sub simple"
  (norm* "10 DO .X <- .A SUB 1"))

(test-case "nested sub"
  (norm* "10 DO .X <- .A SUB 1 SUB 2"))

(test-case "sub + mingle"
  (norm* "10 DO .X <- .A SUB 1 $ .B"))

;; (test-case "sub rhs expr"
;;   (norm* "10 DO .X <- .A SUB (.B $ 1)"))

(test-case "deep nesting"
  (norm*
   "10 DO .X <- .A $ .B $ .C $ .D $ .E"))

(test-case "control flow mix"
  (norm*
   "10 DO .I <- 5
    20 DO NEXT 40
    30 DO READ OUT .I
    40 PLEASE GIVE UP"))

(test-case "come-from"
  (parse*
   "10 DO .I <- 5
    20 DO COME FROM 10"))

(test-case "colon var"
  (norm* "10 DO :X <- 5"))

(test-case "star var"
  (norm* "10 DO *X <- 5"))

(test-case "constants in expr"
  (norm* "10 DO .X <- #5 $ #3"))

(test-case "constant select"
  (norm* "10 DO .X <- #5 ~ #3"))

(test-case "weird spacing"
  (norm*
   "10    DO     .X   <-    .A    $    #3"))

(test-case "long program"
  (norm*
   (string-join
    (for/list ([i (in-range 1 50)])
      (format "~a DO .X <- .X $ #1" (* 10 i)))
    "\n")))

;; (test-case "normalize idempotence"
;;   (let* ([p (parse* "10 DO .X <- .A $ #3")]
;;          [n1 (normalize-program p)]
;;          [n2 (normalize-program n1)])
;;     (check-equal? n1 n2)))

(test-case "parentheses unsupported"
  (check-exn exn:fail?
    (λ () (parse* "10 DO .X <- (.A $ .B)"))))

(test-case "ambiguous unary"
  (norm* "10 DO .X <- & .A $ .B"))

(test-case "everything together"
  (norm*
   "10 DO *A <- 5
    20 DO .X <- & .A SUB 1 $ #3
    30 DO READ OUT .X
    40 PLEASE GIVE UP"))

;; (test-case "unary binds tighter than SUB"
;;   (norm* "10 DO .X <- & .A SUB 1"))

(test-case "triple unary"
  (norm* "10 DO .X <- & V ? .A"))

(test-case "sub + binary nesting"
  (norm* "10 DO .X <- .A SUB 1 $ .B SUB 2"))

(test-case "everything pathological"
  (norm*
   "10 DO *A <- 5
    20 DO .X <- & .A SUB 1 $ .B SUB 2 ~ #3
    30 DO READ OUT .X
    40 PLEASE GIVE UP"))

(test-case "deep sub chain"
  (norm*
   "10 DO .X <- .A SUB 1 SUB 2 SUB 3 SUB 4"))

(test-case "unary constant"
  (norm* "10 DO .X <- & #5"))

(test-case "const sub mix"
  (norm* "10 DO .X <- #5 $ .A SUB 1"))

(test-case "mixed casing"
  (norm* "10 do .x <- .a $ #3"))
