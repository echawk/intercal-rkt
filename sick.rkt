#lang racket

(require
 roman-numeral
 (for-syntax roman-numeral)
 (for-syntax racket/match)
 (for-syntax syntax/parse))

(provide (all-defined-out))

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
  (cond
    ((number? rn) rn)
    ((symbol? rn) (roman->number (symbol->string rn)))))

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


(define (mingle a b) (intercal-mingle a b 16))
(define (select a b) (intercal-select a b 16))
(define (unary-and val) (intercal-unary bitwise-and val 16))
(define (unary-or val)  (intercal-unary bitwise-ior val 16))
(define (unary-xor val) (intercal-unary bitwise-xor val 16))



(define (sick-dec val) (max 0 (sub1 val)))

(struct intercal-array (dimensions data) #:transparent)

(define (make-intercal-array dims)
  (define normalized-dims
    (for/list ([dim dims])
      (unless (and (integer? dim) (positive? dim))
        (error (ick-err "E240")))
      dim))
  (intercal-array normalized-dims
                  (make-vector (apply * normalized-dims) 0)))

(define (legacy-vector->array arr)
  (intercal-array (list (vector-length arr)) arr))

(define (ensure-intercal-array arr)
  (cond
    [(intercal-array? arr) arr]
    [(vector? arr) (legacy-vector->array arr)]
    [else (error (ick-err "E241"))]))

(define (intercal-array-offset arr idxs)
  (define dims (intercal-array-dimensions arr))
  (unless (= (length dims) (length idxs))
    (error (ick-err "E241")))
  (for/fold ([offset 0])
            ([dim dims]
             [idx idxs])
    (unless (and (integer? idx) (<= 1 idx dim))
      (error (ick-err "E241")))
    (+ (* offset dim) (sub1 idx))))

(define (intercal-array-ref* arr idxs)
  (define actual-arr (ensure-intercal-array arr))
  (vector-ref (intercal-array-data actual-arr)
              (intercal-array-offset actual-arr idxs)))

(define (intercal-array-set!* arr idxs val)
  (define actual-arr (ensure-intercal-array arr))
  (vector-set! (intercal-array-data actual-arr)
               (intercal-array-offset actual-arr idxs)
               val))

(define (array-output-list arr)
  (cond
    [(intercal-array? arr) (vector->list (intercal-array-data arr))]
    [(vector? arr) (vector->list arr)]
    [else '()]))

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

(define-for-syntax (extract-body body pct is-not is-once is-again)
  (match body
    [`(not ,rest)   (extract-body rest pct #t is-once is-again)]
    [`(once ,rest)  (extract-body rest pct is-not #t is-again)]
    [`(again ,rest) (extract-body rest pct is-not is-once #t)]
    [`(% ,p ,rest)  (extract-body rest p is-not is-once is-again)]
    [op             (list pct is-not is-once is-again op)]))

(define-for-syntax (normalize-line line num)
  (match line
    ;; Labeled line
    [`(,lbl ,(list (and m (or 'do 'please)) body))
     (match-define (list pct is-not is-once is-again op)
       (extract-body body 100 #f #f #f))
     `(,num ,lbl ,m ,pct ,is-not ,is-once ,is-again ,op)]
    ;; Unlabeled line
    [`(,(and m (or 'do 'please)) ,body)
     (match-define (list pct is-not is-once is-again op)
       (extract-body body 100 #f #f #f))
     `(,num _ ,m ,pct ,is-not ,is-once ,is-again ,op)]
    [_ (error (format "Invalid sick line format: ~a" line))]))

(define-for-syntax (normalize-sick-prog prog)
  (map (lambda (p)
         (match p
           [`(,num ,line) (normalize-line line num)]))
       (map list (range 1 (add1 (length prog))) prog)))

;; Evaluates targets like (mesh XI) or (11) at compile time
(define-for-syntax (eval-label-target tgt-stx)
  (syntax-parse tgt-stx
    [((~datum mesh) rn)
     (let ([e (syntax-e #'rn)])
       (if (symbol? e) (roman->number (symbol->string e)) e))]
    [(tgt) (syntax-e #'tgt)]
    [tgt (syntax-e #'tgt)]))

(define-for-syntax (extract-sub-target datum)
  (let loop ([node datum] [acc '()])
    (match node
      [`(sub ,base ,idxs ...)
       (cond
         [(null? idxs) (values #f '())]
         [(and (pair? base) (eq? (car base) 'sub))
          (define-values (inner-base inner-idxs) (loop base '()))
          (if inner-base
              (values inner-base (append inner-idxs idxs))
              (values base idxs))]
         [else
          (values base idxs)])]
      [`(sub ,base ,idx) (loop base (cons idx acc))]
      [(? symbol? base) (if (null? acc)
                            (values #f '())
                            (values base acc))]
      [_ (values #f '())])))


(define-syntax (sick-program-core stx)
  (syntax-parse stx
    ;; Accept the new normalized tuple format!
    [(_ (ln:integer lbl modifier pct:integer is-not:boolean is-once:boolean is-again:boolean op) ...)

     (define ops (syntax->list #'(op ...)))

     (define all-vars
       (remove-duplicates
        (filter (lambda (sym)
                  (and (symbol? sym)
                       (let ([str (symbol->string sym)])
                         (member (substring str 0 1) '("." ":" "*" ",")))))
                (flatten (map syntax->datum ops)))))

     (define grouped-come-froms
       (let ([h (make-hash)])
         (for-each (lambda (l-ln l-op)
                     (syntax-parse l-op
                       [((~datum come-from) target)
                        (let ([t (eval-label-target #'target)]
                              [ln (syntax-e l-ln)])
                          (hash-set! h t (cons ln (hash-ref h t '()))))]
                       [_ (void)]))
                   (syntax->list #'(ln ...))
                   ops)
         (hash-map h cons)))

     (define ln->lbl-map
       (let ([h (make-hash)])
         (for-each (lambda (l-ln l-lbl)
                     (let ([lbl-val (syntax-e l-lbl)])
                       (unless (eq? lbl-val '_)
                         (hash-set! h (syntax-e l-ln) lbl-val))))
                   (syntax->list #'(ln ...))
                   (syntax->list #'(lbl ...)))
         h))

     (define var-definitions
       (map (lambda (v)
              (define vid (datum->syntax stx v))
              (define vstack (datum->syntax stx (string->symbol (string-append (symbol->string v) "-stack"))))
              (define str (symbol->string v))
              (if (or (string-prefix? str "*") (string-prefix? str ","))
                  #`(begin (define #,vid #f) (define #,vstack '()))
                  #`(begin (define #,vid 0)  (define #,vstack '()))))
            all-vars))

     (define case-clauses
       (let loop ([lns (syntax->list #'(ln ...))]
                  [lbls (syntax->list #'(lbl ...))]
                  [pcts (syntax->list #'(pct ...))]
                  [is-onces (syntax->list #'(is-once ...))]
                  [is-agains (syntax->list #'(is-again ...))]
                  [operations ops])
         (cond
           [(null? lns) '()]
           [else
            (define current-ln (car lns))
            (define current-lbl (car lbls))
            (define current-pct (car pcts))
            (define is-once-val (syntax-e (car is-onces)))
            (define is-again-val (syntax-e (car is-agains)))
            (define current-op (car operations))
            (define next-ln-val (if (null? (cdr lns)) #f (syntax-e (cadr lns))))

            (define compiled-op
              (syntax-parse current-op
                [((~datum assign) var ((~datum dimension) dim ...))
                 (let ([var-str (symbol->string (syntax-e #'var))])
                   (if (or (string-prefix? var-str "*") (string-prefix? var-str ","))
                       #'(unless (hash-ref ignore-tbl (quote var) #f)
                           (set! var (make-intercal-array (list dim ...))))
                       #'(unless (hash-ref ignore-tbl (quote var) #f)
                           (set! var (list dim ...)))))]
                [((~datum assign) var val)
                 (let* ([target-datum (syntax->datum #'var)]
                        [var-str (and (symbol? target-datum) (symbol->string target-datum))])
                   (define-values (base idxs) (extract-sub-target target-datum))
                   (cond
                     [base
                      (define base-stx (datum->syntax stx base))
                      (define idx-stxs (map (lambda (idx) (datum->syntax stx idx)) idxs))
                      #`(unless (hash-ref ignore-tbl (quote #,base-stx) #f)
                          (intercal-array-set!* #,base-stx (list #,@idx-stxs) val))]
                     [(and var-str
                           (or (string-prefix? var-str "*") (string-prefix? var-str ",")))
                      #'(unless (hash-ref ignore-tbl (quote var) #f)
                          (set! var (make-intercal-array (list val))))]
                     [else
                      #`(unless (hash-ref ignore-tbl (quote var) #f)
                          (set! var val))]))]
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
                [((~datum ignore) var ...)
                 #`(begin
                     #,@(map (lambda (v) #`(hash-set! ignore-tbl (quote #,v) #t))
                             (syntax->list #'(var ...))))]

                [((~datum remember) var ...)
                 #`(begin
                     #,@(map (lambda (v) #`(hash-set! ignore-tbl (quote #,v) #f))
                             (syntax->list #'(var ...))))]
                [((~datum write-in) var)
                 #`(set! var (string->number
                              (string-join
                               (map number->string
                                    (map (lambda (str) (arabic->number str))
                                         (string-split (read-line)))) "")))]
                [((~datum read-out) var)
                 #`(let ([v var])
                     (displayln
                      (cond ((and (number? v) (zero? v)) "_")
                            ((number? v) (string-upcase (number->roman v)))
                            (else "")))
                     (if (or (vector? v) (intercal-array? v))
                         (set! output-acc (append (reverse (array-output-list v)) output-acc))
                         (set! output-acc (cons v output-acc))))]

                [((~datum abstain) (~optional (~datum from)) target)
                 (let ([t (eval-label-target #'target)])
                   #`(hash-set! abstain-tbl (get-ln-for-lbl '#,t) #t))]
                [((~datum reinstate) target)
                 (let ([t (eval-label-target #'target)])
                   #`(hash-set! abstain-tbl (get-ln-for-lbl '#,t) #f))]

                [((~datum nothing)) #`(void)]
                [(~datum nothing)   #`(void)]

                ;; 80-depth NEXT stack limit implemented!
                [((~datum come-from) target) #`(void)]
                [((~datum next) target)
                 #`(if (>= (length next-stack) 80)
                       (ick-err "E123")
                       (set! next-stack (cons '#,(if next-ln-val next-ln-val #f) next-stack)))]
                [((~datum resume) var)       #`(void)]
                [((~datum forget) var)       #`(void)]
                [((~datum give-up))          #`(void)]
                [(~datum give-up)            #`(void)]
                [_ #`(void)]))

            (define branch
              (let ([lbl-val (syntax-e current-lbl)]
                    [pct-val (syntax-e current-pct)])
                #`[(#,current-ln)
                   (let ([is-abstained? (hash-ref abstain-tbl #,current-ln #f)])
                     (if is-abstained?
                         (begin
                           ;; Skipped! Update state based on modifiers, and ALWAYS BROADCAST LABEL
                           #, (if (or is-once-val is-again-val) #`(update-state! #,current-ln) #`(void))
                          (loop (get-actual-next '#,lbl-val '#,next-ln-val)))

                         (let ([roll (random 100)])
                           (if (< roll #,pct-val)
                               (begin
                                 ;; Executed!
                                 #,compiled-op
                                 #, (if (or is-once-val is-again-val) #`(update-state! #,current-ln) #`(void))

                                 #,(syntax-parse current-op
                                     [((~datum give-up)) #`(apply values (reverse output-acc))]
                                     [(~datum give-up)   #`(apply values (reverse output-acc))]
                                     [((~datum next) target)
                                      (let ([t (eval-label-target #'target)])
                                        ;; NEXT directly branches to its target. It does not complete sequentially,
                                        ;; therefore it cannot trigger COME FROM interception.
                                        #`(loop (get-ln-for-lbl '#,t)))]

                                     [((~datum resume) var)
                                      #`(let ([count var])
                                          (cond
                                            ;; Attempting to RESUME 0 or RESUME past the stack causes the stack to rupture.
                                            [(<= count 0) (ick-err "E632")]
                                            [(> count (length next-stack)) (ick-err "E632")]
                                            [else
                                             ;; Branch to the oldest entry popped (the one deepest in the removed segment)
                                             (let ([target-pc (list-ref next-stack (- count 1))])
                                               (set! next-stack (drop next-stack count))
                                               ;; RESUME transfers control explicitly, bypassing COME FROM interceptions.
                                               (loop target-pc))]))]

                                     [((~datum forget) var)
                                      #`(let ([count var])
                                          (cond
                                            ;; FORGET 0 is a valid no-op, let execution naturally fall through.
                                            [(<= count 0) (loop (get-actual-next '#,lbl-val '#,next-ln-val))]
                                            ;; Attempting to FORGET past the stack causes the program to disappear into the black lagoon.
                                            [(> count (length next-stack)) (ick-err "E123")]
                                            [else
                                             (set! next-stack (drop next-stack count))
                                             ;; FORGET does not transfer control, it completes sequentially.
                                             ;; Therefore, COME FROM checks (get-actual-next) are correctly applied here.
                                             (loop (get-actual-next '#,lbl-val '#,next-ln-val))]))]

                                     [_ #`(loop (get-actual-next '#,lbl-val '#,next-ln-val))]))

                               (begin
                                 ;; Failed execution chance. Acts as if it wasn't encountered (no update-state)
                                 (loop (get-actual-next '#,lbl-val '#,next-ln-val)))))))]))

            (cons branch (loop (cdr lns) (cdr lbls) (cdr pcts) (cdr is-onces) (cdr is-agains) (cdr operations)))])))

     ;; --- Final Code Assembly ---
     #`(let ()
         #,@var-definitions
         (define output-acc '())
         (define next-stack '())
         (define ignore-tbl (make-hash))

         (define (#,(datum->syntax stx 'sub) arr . idxs)
           (intercal-array-ref* arr idxs))

         ;; State tables for the Unified Theory
         (define source-is-not-tbl (make-hash))
         (define has-once-tbl (make-hash))
         (define has-again-tbl (make-hash))
         (define abstain-tbl (make-hash))

         #,@(filter-map (lambda (l-ln l-is-not)
                          #`(begin
                              (hash-set! source-is-not-tbl #,l-ln #,l-is-not)
                              (hash-set! abstain-tbl #,l-ln #,l-is-not)))
                        (syntax->list #'(ln ...))
                        (syntax->list #'(is-not ...)))

         #,@(filter-map (lambda (l-ln l-is-once)
                          (if (syntax-e l-is-once) #`(hash-set! has-once-tbl #,l-ln #t) #f))
                        (syntax->list #'(ln ...))
                        (syntax->list #'(is-once ...)))

         #,@(filter-map (lambda (l-ln l-is-again)
                          (if (syntax-e l-is-again) #`(hash-set! has-again-tbl #,l-ln #t) #f))
                        (syntax->list #'(ln ...))
                        (syntax->list #'(is-again ...)))

         ;; The magic state mutator
         (define (update-state! target-ln)
           (cond
             [(hash-ref has-once-tbl target-ln #f)
              (hash-set! abstain-tbl target-ln (not (hash-ref source-is-not-tbl target-ln)))]
             [(hash-ref has-again-tbl target-ln #f)
              (hash-set! abstain-tbl target-ln (hash-ref source-is-not-tbl target-ln))]))

         (define cf-map '#,grouped-come-froms)
         (define lbl->ln-map '#,(let ([h (make-hash)])
                                  (for-each (lambda (l-ln l-lbl)
                                              (let ([v (syntax-e l-lbl)])
                                                (unless (eq? v '_)
                                                  (hash-set! h v (syntax-e l-ln)))))
                                            (syntax->list #'(ln ...))
                                            (syntax->list #'(lbl ...)))
                                  h))
         (define rt-ln->lbl-map '#,ln->lbl-map)

         (define (get-ln-for-lbl target-lbl)
           (hash-ref lbl->ln-map target-lbl (lambda () (ick-err "E129"))))

         (define (get-actual-next executed-lbl natural-next-ln)
           (if (not (eq? executed-lbl '_))
               (let ([hijackers (dict-ref cf-map executed-lbl '())])
                 (let ([active-hijackers
                        (filter (lambda (h-ln) (not (hash-ref abstain-tbl h-ln #f))) hijackers)])
                   (if (null? active-hijackers)
                       natural-next-ln
                       (let ([chosen (list-ref active-hijackers (random (length active-hijackers)))])
                         ;; Hijackers count as executed, so they update state too!
                         (update-state! chosen)
                         chosen))))
               natural-next-ln))

         (define (run)
           (let loop ([pc #,(syntax-e (car (syntax->list #'(ln ...))))])
             (case pc
               #,@case-clauses
               [(#f) (ick-err "E633")]
               [else (error "Fell off graph! PC:" pc)])))
         (run))]))

(define-syntax (sick-program stx)
  (syntax-parse stx
    [(_ sick-line ...)
     (define raw-lines (syntax->datum #'(sick-line ...)))
     (define normalized-datums (normalize-sick-prog raw-lines))
     (datum->syntax stx `(,#'sick-program-core ,@normalized-datums) stx)]))


(require
 (for-syntax racket/file)
 (for-syntax "ick-lexer.rkt")
 (for-syntax "ick-bnf.rkt")
 (for-syntax "ick-normalize.rkt"))

(define-syntax (sick-program/syslib stx)
  (syntax-parse stx
    [(_ sick-line ...)

     ;; What the fuck racket.
     (define (clean-intercal-string str)
       (define lines (string-split str "\n"))

       ;; 1. Matches lines that start with a VALID operation or variable assignment.
       ;; It ensures DO/PLEASE is immediately followed by a real command (STASH, etc) or a variable [.:,;]
       (define valid-start-rx
         #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|MAYBE|%[0-9]+)[ \t]*)+(?:STASH|RETRIEVE|IGNORE|REMEMBER|ABSTAIN|REINSTATE|FORGET|RESUME|READ|WRITE|COME|GIVE|NOTHING|[.:,;]|\\()")

       ;; 2. Matches multi-line continuations.
       ;; These are indented lines containing ONLY valid INTERCAL math/logic symbols, quotes, and numbers.
       ;; This cleanly catches wrapped math while rejecting "DOUBLE OR SINGLE PRECISION OVERFLOW"
       (define continuation-rx
         #px"^[ \t]+[\"'?&V!#0-9.:,~$\\s+-]+$")

       (define cleaned-lines
         (filter (lambda (l)
                   (or (regexp-match? valid-start-rx l)
                       (regexp-match? continuation-rx l)))
                 lines))

       (string-join cleaned-lines "\n"))

     ;; 1. Get raw user AST
     (define raw-user-ast (syntax->datum #'(sick-line ...)))

     ;; 2. Parse syslib to raw AST
     (define full-syslib-ast
       (normalize-program
        (syntax->datum
         (parse
          (tokenize
           (open-input-string
            (clean-intercal-string (file->string "syslib.i"))))))))

     ;; 3. Strip the wrapper off syslib
     (define syslib-ast
       (if (and (list? full-syslib-ast) (symbol? (car full-syslib-ast)))
           (cdr full-syslib-ast)
           full-syslib-ast))

     ;; 4. COMBINE the ASTs first
     (define combined-ast (append raw-user-ast syslib-ast))

     ;; ;; 4.5. AST Rewriter: Fix unary operator precedence from the parser
     ;; ;; Turns `(mingle (unary-xor X) Y)` into `(unary-xor (mingle X Y))`
     ;; (define (fix-unary-ast ast)
     ;;   (match ast
     ;;     [`(mingle (,U ,X) ,Y)
     ;;      #:when (member U '(unary-and unary-or unary-xor))
     ;;      `(,U (mingle ,(fix-unary-ast X) ,(fix-unary-ast Y)))]
     ;;     [`(select (,U ,X) ,Y)
     ;;      #:when (member U '(unary-and unary-or unary-xor))
     ;;      `(,U (select ,(fix-unary-ast X) ,(fix-unary-ast Y)))]
     ;;     [(list elements ...)
     ;;      (map fix-unary-ast elements)]
     ;;     [other other]))

     ;; (define fixed-ast (fix-unary-ast combined-ast))

     ;; 5. Compile the ENTIRE combined AST into the low-level IR
     (define combined-ir (normalize-sick-prog combined-ast))

     ;; 6. Output to the evaluator
     (datum->syntax stx `(,#'sick-program-core ,@combined-ir) stx)]))
