#lang racket

(require (for-syntax roman-numeral)
         (for-syntax racket/match)
         (for-syntax syntax/parse)
         )
(define ick-error-table
  #hash(
        ("E000" .
                ("ICL000I ~a"
                 "Runtime syntax error; prints the undecodable statement text."))

        ("E017" .
                ("ICL017I DO YOU EXPECT ME TO FIGURE THIS OUT?"
                 "Constant outside onespot range (compile-time error)."))

        ("E079" .
                ("ICL079I PROGRAMMER IS INSUFFICIENTLY POLITE"
                 "Too few PLEASEs (~<20%) in statement identifiers."))

        ("E099" .
                ("ICL099I PROGRAMMER IS OVERLY POLITE"
                 "Too many PLEASEs (~>33%) in statement identifiers."))

        ("E111" .
                ("ICL111I COMMUNIST PLOT DETECTED, COMPILER IS SUICIDING"
                 "Using non-INTERCAL-72 features with -t option."))

        ("E123" .
                ("ICL123I PROGRAM HAS DISAPPEARED INTO THE BLACK LAGOON"
                 "Exceeded NEXT stack limit (80) or mismanaged NEXT/FORGET."))

        ("E127" .
                ("ICL127I SAYING 'ABRACADABRA' WITHOUT A MAGIC WAND WON’T DO YOU ANY GOOD"
                 "System library could not be found."))

        ("E129" .
                ("ICL129I PROGRAM HAS GOTTEN LOST"
                 "NEXT target cannot be resolved."))

        ("E139" .
                ("ICL139I I WASN’T PLANNING TO GO THERE ANYWAY"
                 "ABSTAIN/REINSTATE references nonexistent line."))

        ("E182" .
                ("ICL182I YOU MUST LIKE THIS LABEL A LOT!"
                 "Duplicate line labels are not allowed."))

        ("E197" .
                ("ICL197I SO! 65535 LABELS AREN’T ENOUGH FOR YOU?"
                 "Invalid line label (must be 1–65535)."))

        ("E200" .
                ("ICL200I NOTHING VENTURED, NOTHING GAINED"
                 "Invalid or nonexistent variable used."))

        ("E222" .
                ("ICL222I BUMMER, DUDE!"
                 "Out of memory during STASH operations."))

        ("E240" .
                ("ICL240I ERROR HANDLER PRINTED SNIDE REMARK"
                 "Array dimension too small (runtime)."))

        ("E241" .
                ("ICL241I VARIABLES MAY NOT BE STORED IN WEST HYPERSPACE"
                 "Invalid array subscripting or dimensional mismatch."))

        ("E252" .
                ("ICL252I I’VE FORGOTTEN WHAT I WAS ABOUT TO SAY"
                 "Out of memory during I/O."))

        ("E256" .
                ("ICL256I THAT’S TOO HARD FOR MY TINY BRAIN"
                 "Unsupported command in PIC-INTERCAL."))

        ("E275" .
                ("ICL275I DON’T BYTE OFF MORE THAN YOU CAN CHEW"
                 "Twospot value stored in onespot variable."))

        ("E277" .
                ("ICL277I YOU CAN ONLY DISTORT THE LAWS OF MATHEMATICS SO FAR"
                 "Impossible reverse assignment."))

        ("E281" .
                ("ICL281I THAT MUCH QUOTATION AMOUNTS TO PLAGIARISM"
                 "Exceeded nesting limit (3200)."))

        ("E333" .
                ("ICL333I YOU CAN’T HAVE EVERYTHING, WHERE WOULD YOU PUT IT?"
                 "Too many variables."))

        ("E345" .
                ("ICL345I THAT’S TOO COMPLEX FOR ME TO GRASP"
                 "Compiler ran out of memory."))

        ("E404" .
                ("ICL404I I’M ALL OUT OF CHOICES!"
                 "No choicepoints available."))

        ("E405" .
                ("ICL405I PROGRAM REJECTED FOR MENTAL HEALTH REASONS"
                 "Used multithreading constructs without -m."))

        ("E436" .
                ("ICL436I THROW STICK BEFORE RETRIEVING!"
                 "RETRIEVE without STASH."))

        ("E444" .
                ("ICL444I IT CAME FROM BEYOND SPACE"
                 "Invalid COME FROM / NEXT FROM target."))

        ("E533" .
                ("ICL533I YOU WANT MAYBE WE SHOULD IMPLEMENT 64-BIT VARIABLES?"
                 "Value exceeds twospot limits."))

        ("E553" .
                ("ICL553I BETTER LATE THAN NEVER"
                 "Buffer overflow detected."))

        ("E555" .
                ("ICL555I FLOW DIAGRAM IS EXCESSIVELY CONNECTED"
                 "Multiple COME FROMs without multithreading."))

        ("E562" .
                ("ICL562I I DO NOT COMPUTE"
                 "Input unavailable."))

        ("E579" .
                ("ICL579I WHAT BASE AND/OR LANGUAGE INCLUDES ~a?"
                 "Invalid spelt-out digit input."))

        ("E621" .
                ("ICL621I ERROR TYPE 621 ENCOUNTERED"
                 "Invalid NEXT stack usage."))

        ("E632" .
                ("ICL632I THE NEXT STACK RUPTURES. ALL DIE. OH, THE EMBARRASSMENT!"
                 "RESUME past end of NEXT stack."))

        ("E633" .
                ("ICL633I PROGRAM FELL OFF THE EDGE"
                 "Execution ran past program end."))

        ("E652" .
                ("ICL652I HOW DARE YOU INSULT ME!"
                 "PIN used outside PIC mode."))

        ("E666" .
                ("ICL666I COMPILER HAS INDIGESTION"
                 "Compiler ran out of memory."))

        ("E774" .
                ("ICL774I RANDOM COMPILER BUG"
                 "Intentional random failure."))

        ("E777" .
                ("ICL777I A SOURCE IS A SOURCE, OF COURSE, OF COURSE"
                 "Input file could not be opened."))

        ("E778" .
                ("ICL778I UNEXPLAINED COMPILER BUG"
                 "Internal compiler/runtime failure."))

        ("E810" .
                ("ICL810I ARE ONE-CHARACTER COMMANDS TOO SHORT FOR YOU?"
                 "Debugger received too much input."))

        ("E811" .
                ("ICL811I PROGRAM IS TOO BADLY BROKEN TO RUN"
                 "Too many breakpoints."))

        ("E888" .
                ("ICL888I I HAVE NO FILE AND I MUST SCREAM"
                 "Output file could not be written."))

        ("E899" .
                ("ICL899I HELLO? CAN ANYONE GIVE ME A HAND HERE?"
                 "Required libraries unavailable."))

        ("E990" .
                ("ICL990I FLAG ETIQUETTE FAILURE BAD SCOUT NO BISCUIT"
                 "Unknown runtime flag."))

        ("E991" .
                ("ICL991I YOU HAVE TOO MUCH ROPE TO HANG YOURSELF"
                 "Out of memory in multithreading/backtracking."))

        ("E993" .
                ("ICL993I I GAVE UP LONG AGO"
                 "TRY AGAIN not last statement."))

        ("E994" .
                ("ICL994I NOCTURNAL EMISSION, PLEASE LAUNDER SHEETS IMMEDIATELY"
                 "Emitter encountered unknown opcode."))

        ("E995" .
                ("ICL995I DO YOU REALLY EXPECT ME TO HAVE IMPLEMENTED THAT?"
                 "Unimplemented feature reached."))

        ("E997" .
                ("ICL997I ILLEGAL POSSESSION OF A CONTROLLED UNARY OPERATOR"
                 "Operator invalid for current base."))

        ("E998" .
                ("ICL998I EXCUSE ME, YOU MUST HAVE ME CONFUSED WITH SOME OTHER COMPILER"
                 "Unrecognized file type."))

        ("E999" .
                ("ICL999I NO SKELETON IN MY CLOSET, WOE IS ME!"
                 "Missing skeleton file."))
        ))

(define (ick-err code . args)
  (let ((entry (hash-ref ick-error-table code #f)))
    (cond
      (entry (apply format (car entry) args))
      (else (error "Unknown INTERCAL error code" code)))))

(define (ick-err/wimp code . args)
  (let ((entry (hash-ref ick-error-table code #f)))
    (cond
      (entry
       (string-append
        (apply format (car entry) args)
        "\n"
        (cadr entry)))
      (else (error "Unknown INTERCAL error code" code)))))

(define (arabic->number as)
  (match as
    ["ZERO" 0]
    ["ONE" 1]
    ["TWO" 2]
    ["THREE" 3]
    ["FOUR" 4]
    ["FIVE" 5]
    ["SIX" 6]
    ["SEVEN" 7]
    ["EIGHT" 8]
    ["NINE" 9]
    [_ (ick-err "E579" as)]))

(define (mesh rn)
  (roman->number (symbol->string rn)))

(define-for-syntax (mesh rn)
  (roman->number (symbol->string rn)))

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

(define (char-ascii? ch)
  (and (char? ch)
       (<= (char->integer ch) 127)))

(define (string-ascii? s)
  (and (string? s)
       (for/and ([ch (in-string s)]) (char-ascii? ch))))

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

;; MAJOR FIXME: need to restructure the programs to instead have their line
;; numbers be separate from their labels - I want to make sure that before
;; I get too far along, we do not box ourselves into a corner.

;; For the come-from logic, we can simply rewrite it to have there be a mapping
;; from label (whether it be computed or provided) to a line number -> that is
;; also a more semantically correct option, since this also will allow us to check
;; if a line number has been abstained or not.


;; Also, will need to fix the current issues which arise if you decide to write
;; (please (do (foo ...))) since it will always cause the program to fail.
;; I think the *ideal* way to do this would be with a syntax class or something
;; similar, but I'm somewhat open to whatever is the *correct* solution.

;; Part of me also wants to refactor how lines are actually compiled anyways, since
;; we have to add a number of checks & whatnot - particularly with regards to
;; abstaining - I want to work on getting that functionality to be foolproof.

;; I'm OK with the current forget/resume/etc stack stuff, it appears to work fine
;; for our usecases. I'm sure that there is a more elegant way to do it.

;; I will need to add in "type checks" or maybe just enforcement for our data.

;; while ,A is for arrays, . and : are for 16 & 32 bit unsigned integers only.
;; Since ',' is a character we cannot directly capture with racket (since it lives
;; in the reader) we instead use '*' for arrays, which feels more 'C-like' anyways.
;; (string-ascii? "phỏ")
;; (string-ascii? "pho")
;; (string-locale-) (char-downcase #\Ỉ)
;; ẢA

;; (car (list 'Â))

;; What would be fun is if we instead used some random unicode character instead.

(define-for-syntax (normalize-line line num)
  (match line
    [(or `(do . ,_)      `(please . ,_))      `(,num (_ ,line))]
    [(or `(,_ (do . ,_)) `(,_ (please . ,_))) `(,num ,line)]
    [_ (error (format "~a" line))]))

(define-for-syntax (normalize-sick-prog prog)
  (map (lambda (p)
         (match p
           [`(,num ,line)
            (normalize-line line num)]))
       (map list (range 1 (add1 (length prog))) prog)))

(define-syntax (sick-program-core stx)
  (syntax-parse stx
    [(_ (ln:integer (lbl ((~seq (~or (~datum do) (~datum please)) ...) op))) ...)

     ;; =====================================================================
     ;; PHASE 2: Collect all vars (w/ their types)
     ;; =====================================================================
     (define ops (syntax->list #'(op ...)))

     (define all-vars
       (remove-duplicates
        (filter (lambda (sym)
                  (and (symbol? sym)
                       (let ([str (symbol->string sym)])
                         ;; Added ',' to the array prefixes for future-proofing
                         (member (substring str 0 1) '("." ":" "*" ",")))))
                (flatten (map syntax->datum ops)))))

     ;; =====================================================================
     ;; PHASE 3: Build come from map (w/ line numbers included)
     ;; =====================================================================
     ;; Map: target-label -> list of hijacker line numbers (ln)
     (define grouped-come-froms
       (let ([h (make-hash)])
         (for-each (lambda (l-ln l-op)
                     (syntax-parse l-op
                       [((~datum come-from) target)
                        (let ([t (syntax-e #'target)]
                              [ln (syntax-e l-ln)])
                          (hash-set! h t (cons ln (hash-ref h t '()))))]
                       [_ (void)]))
                   (syntax->list #'(ln ...))
                   ops)
         (hash-map h cons)))

     ;; We also need a map from line-number -> label to check if a hijacker is abstained
     (define ln->lbl-map
       (let ([h (make-hash)])
         (for-each (lambda (l-ln l-lbl)
                     (let ([lbl-val (syntax-e l-lbl)])
                       (unless (eq? lbl-val '_)
                         (hash-set! h (syntax-e l-ln) lbl-val))))
                   (syntax->list #'(ln ...))
                   (syntax->list #'(lbl ...)))
         h))

     ;; =====================================================================
     ;; PHASE 4: Build vars & stacks
     ;; =====================================================================
     (define var-definitions
       (map (lambda (v)
              (define vid (datum->syntax stx v))
              (define vstack (datum->syntax stx (string->symbol (string-append (symbol->string v) "-stack"))))
              (define str (symbol->string v))
              (if (or (string-prefix? str "*") (string-prefix? str ","))
                  #`(begin (define #,vid #f) (define #,vstack '()))
                  #`(begin (define #,vid 0)  (define #,vstack '()))))
            all-vars))

     ;; =====================================================================
     ;; PHASE 5 & 6: Tie it all together (Emission & Abstain table generation)
     ;; =====================================================================
     (define case-clauses
       (let loop ([lns (syntax->list #'(ln ...))]
                  [lbls (syntax->list #'(lbl ...))]
                  [operations ops])
         (cond
           [(null? lns) '()]
           [else
            (define current-ln (car lns))
            (define current-lbl (car lbls))
            (define next-ln-val (if (null? (cdr lns)) #f (syntax-e (cadr lns))))

            ;; FIXME: need to support multidimensional arrays.

            ;; --- Semantics compilation ---
            (define compiled-op
              (syntax-parse (car operations)
                [((~datum assign) ((~datum sub) arr idx) val)
                 #`(vector-set! arr (sub1 idx) val)]
                [((~datum assign) var val)
                 (let ([var-str (symbol->string (syntax-e #'var))])
                   (cond
                     [(or (string-prefix? var-str "*") (string-prefix? var-str ","))
                      #`(set! var (make-vector val 0))]
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
                [((~datum write-in) var)
                 ;; FIXME: add wimp-mode support.
                 ;; FIXME: figure out a better way to do input on matrices?
                 #`(set! var (string-join
                              (map number->string
                                   (map (lambda (str)
                                          arabic->number)
                                        (string-split (read-string)))) ""))]
                [((~datum read-out) var)
                 #`(let ([v var])
                     (if (vector? v)
                         (set! output-acc (append (reverse (vector->list v)) output-acc))
                         (set! output-acc (cons v output-acc))))]

                ;; Abstain / Reinstate matching
                [((~datum abstain) (~optional (~datum from)) (target)) #`(hash-set! abstain-tbl 'target #t)]
                [((~datum abstain) (~optional (~datum from)) target)   #`(hash-set! abstain-tbl 'target #t)]
                [((~datum reinstate) (target)) #`(hash-set! abstain-tbl 'target #f)]
                [((~datum reinstate) target)   #`(hash-set! abstain-tbl 'target #f)]

                ;; Control flow Ops (handled safely below, but NEXT needs to push to stack here)
                [((~datum come-from) target) #`(void)]
                [((~datum next) target)      #`(set! next-stack (cons '#,(if next-ln-val next-ln-val #f) next-stack))]
                [((~datum resume) var)       #`(void)]
                [((~datum forget) var)       #`(void)]
                [((~datum give-up))          #`(void)]
                [(~datum give-up)            #`(void)]
                [_ #`(void)]))

            ;; --- Clause branch generation ---
            (define branch
              (let ([lbl-val (syntax-e current-lbl)]
                    [ln-val (syntax-e current-ln)])
                #`[(#,current-ln)
                   (let ([is-abstained? #,(if (eq? lbl-val '_) #f #`(hash-ref abstain-tbl '#,current-lbl #f))])

                     ;; 1. Execute Op Semantics (only if not abstained)
                     (unless is-abstained?
                       #,compiled-op)

                     ;; 2. Determine and execute Control Flow (Tail Call)
                     (if is-abstained?
                         ;; If abstained, bypass specific jump logic and just go to next natural line
                         (loop (get-actual-next '#,lbl-val '#,next-ln-val))
                         ;; If NOT abstained, execute specific control flow
                         #,(syntax-parse (car operations)
                             [((~datum give-up)) #`(apply values (reverse output-acc))]
                             [(~datum give-up)   #`(apply values (reverse output-acc))]
                             [((~datum next) target)
                              #`(loop (get-actual-next '#,lbl-val (get-ln-for-lbl 'target)))]
                             [((~datum resume) var)
                              #`(if (> var 0)
                                    (let ([target-pc (list-ref next-stack (- var 1))])
                                      (set! next-stack (drop next-stack var))
                                      (loop (get-actual-next '#,lbl-val target-pc)))
                                    (loop (get-actual-next '#,lbl-val '#,next-ln-val)))]
                             [((~datum forget) var)
                              #`(begin
                                  (if (> var 0)
                                      (set! next-stack (drop next-stack var))
                                      (void))
                                  (loop (get-actual-next '#,lbl-val '#,next-ln-val)))]
                             [_ #`(loop (get-actual-next '#,lbl-val '#,next-ln-val))])))]))

            (cons branch (loop (cdr lns) (cdr lbls) (cdr operations)))])))

     ;; --- Final Code Assembly ---
     #`(let ()
         #,@var-definitions
         (define output-acc '())
         (define next-stack '())
         (define abstain-tbl (make-hash))

         (define cf-map '#,grouped-come-froms)

         ;; Inject Label -> Line Number map for `next` jumps
         (define lbl->ln-map '#,(let ([h (make-hash)])
                                  (for-each (lambda (l-ln l-lbl)
                                              (let ([v (syntax-e l-lbl)])
                                                (unless (eq? v '_)
                                                  (hash-set! h v (syntax-e l-ln)))))
                                            (syntax->list #'(ln ...))
                                            (syntax->list #'(lbl ...)))
                                  h))

         ;; Inject Line Number -> Label map to check if hijackers are abstained
         (define rt-ln->lbl-map '#,ln->lbl-map)

         (define (get-ln-for-lbl target-lbl)
           (hash-ref lbl->ln-map target-lbl (lambda () (error "Unknown label" target-lbl))))

         (define (get-actual-next executed-lbl natural-next-ln)
           (if (not (eq? executed-lbl '_))
               (let ([hijackers (dict-ref cf-map executed-lbl '())])
                 ;; Filter out abstainers! If the hijacker line has a label, and that label is abstained, it CANNOT hijack.
                 (let ([active-hijackers
                        (filter (lambda (h-ln)
                                  (let ([h-lbl (hash-ref rt-ln->lbl-map h-ln #f)])
                                    (if h-lbl
                                        (not (hash-ref abstain-tbl h-lbl #f))
                                        #t)))
                                hijackers)])
                   (if (null? active-hijackers)
                       natural-next-ln
                       (list-ref active-hijackers (random (length active-hijackers))))))
               natural-next-ln))

         (define (run)
           (let loop ([pc #,(syntax-e (car (syntax->list #'(ln ...))))])
             (case pc
               #,@case-clauses
               [else (error "Fell off graph! PC:" pc)])))
         (run))]))

(define-syntax (sick-program stx)
  (syntax-parse stx
    [(_ sick-line ...)
     (define raw-lines (syntax->datum #'(sick-line ...)))
     (define normalized-datums (normalize-sick-prog raw-lines))
     (datum->syntax stx `(,#'sick-program-core ,@normalized-datums) stx)]))

(check-equal?
 (call-with-values
  (thunk
   (sick-program
    (do     (assign .I (mesh 'V))) ; .I = 5
    (do     (assign .II (mesh 'III))) ; .II = 3
    (please (assign :I (mingle .I .II))) ; :I = Mingle(5, 3) -> 39
    (do     (read-out :I)) ; Accumulate 39
    (do     (assign .III (unary-xor .I))) ; .III = XOR on 5 (returns 135 in 8-bit logic)
    (do     (read-out .III)) ; Accumulate 135
    (please (give-up))))
  list)
 (list 39 135))

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

(require roman-numeral)

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
   (sick-program-core
    (1 (_ (do (assign .I (mesh 'I)))))        ; .I = 1
    (2 (_ (do (abstain (10)))))              ; Disable label 10
    (3 (10 (do (assign .I (mesh 'V)))))       ; SKIPPED: .I would become 5
    (4 (_ (do (read-out .I))))               ; Outputs 1, not 5
    (5 (_ (please (give-up))))))
  list)
 (list 1))

(check-equal?
 (call-with-values
  (thunk
   (sick-program-core
    (1 (_ (do (assign .I (mesh 'I)))))        ; .I = 1
    (2 (_ (do (abstain (100)))))             ; Disable the hijacker AT label 100
    (3 (20 (do (read-out .I))))              ; Output 1. Control naturally flows to line 4.
    (4 (_ (do (assign .I (mesh 'II)))))       ; .I = 2
    (5 (_ (do (read-out .I))))               ; Output 2.
    (6 (_ (please (give-up))))               ; End cleanly.

    ;; --- The Hijacker ---
    (7 (100 (do (come-from 20))))            ; Tries to intercept after 20, but is ABSTAINED!
    (8 (_ (do (assign .I (mesh 'V)))))        ; Should NEVER run.
    (9 (_ (do (read-out .I))))
    (10 (_ (please (give-up))))))
  list)
 (list 1 2))

(check-equal?
 (call-with-values
  (thunk
   (sick-program-core
    (1 (_ (do (assign *I (mesh 'V)))))        ; Dimension 32-bit array *I to 5
    (2 (_ (do (abstain (30)))))              ; Disable the assignment at label 30
    (3 (10 (do (assign (sub *I 1) (mesh 'I))))); *I[1] = 1
    (4 (30 (do (assign (sub *I 3) (mesh 'V))))); SKIPPED
    (5 (40 (do (assign (sub *I 5) (mesh 'X))))); *I[5] = 10
    (6 (_ (do (read-out *I))))               ; Should be (1 0 0 0 10)
    (7 (_ (please (give-up))))))
  list)
 (list 1 0 0 0 10))
