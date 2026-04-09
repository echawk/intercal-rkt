#lang racket

(require
 roman-numeral
 racket/list
 racket/string
 "ick-lexer.rkt"
 "ick-bnf.rkt"
  (for-syntax roman-numeral)
 (for-syntax racket/list)
 (for-syntax racket/string)
 (for-syntax "ick-lexer.rkt")
 (for-syntax "ick-bnf.rkt")
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
    ["OH" 0]
    ["ONE" 1]
    ["TWO" 2]
    ["THREE" 3]
    ["FOUR" 4]
    ["FIVE" 5]
    ["SIX" 6]
    ["SEVEN" 7]
    ["EIGHT" 8]
    ["NINE" 9]
    [_ (error (ick-err "E579" as))]))

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

(define onespot-limit #xffff)

(define (infer-width . vals)
  (if (ormap (lambda (v) (and (exact-integer? v) (> v onespot-limit))) vals)
      32
      16))

(define (mingle-16 a b) (intercal-mingle a b 16))
(define (select-16 a b) (intercal-select a b 16))
(define (select-32 a b) (intercal-select a b 32))
(define (unary-and-16 val) (intercal-unary bitwise-and val 16))
(define (unary-and-32 val) (intercal-unary bitwise-and val 32))
(define (unary-or-16 val)  (intercal-unary bitwise-ior val 16))
(define (unary-or-32 val)  (intercal-unary bitwise-ior val 32))
(define (unary-xor-16 val) (intercal-unary bitwise-xor val 16))
(define (unary-xor-32 val) (intercal-unary bitwise-xor val 32))

(define (mingle a b) (intercal-mingle a b (infer-width a b)))
(define (select a b) (intercal-select a b (infer-width a b)))
(define (unary-and val) (intercal-unary bitwise-and val (infer-width val)))
(define (unary-or val)  (intercal-unary bitwise-ior val (infer-width val)))
(define (unary-xor val) (intercal-unary bitwise-xor val (infer-width val)))



(define (sick-dec val) (max 0 (sub1 val)))

(define sick-debug
  (make-parameter
   (let ([v (getenv "SICK_DEBUG")])
     (and v (not (member (string-downcase v) '("0" "false" "no" "")))))))

(define (parse-debug-symbols env-name)
  (define raw (getenv env-name))
  (and raw
       (not (string=? (string-trim raw) ""))
       (for/list ([piece (in-list (string-split raw ","))])
         (string->symbol (string-trim piece)))))

(define (parse-debug-numbers env-name)
  (define raw (getenv env-name))
  (and raw
       (not (string=? (string-trim raw) ""))
       (for/list ([piece (in-list (string-split raw ","))]
                  #:when (string->number (string-trim piece)))
         (string->number (string-trim piece)))))

(define sick-debug-vars
  (make-parameter (parse-debug-symbols "SICK_DEBUG_VARS")))

(define sick-debug-lines
  (make-parameter (parse-debug-numbers "SICK_DEBUG_LINES")))

(define sick-break-lines
  (make-parameter (parse-debug-numbers "SICK_BREAK_LINES")))

(define (parse-debug-subspecs env-name)
  (define raw (getenv env-name))
  (and raw
       (not (string=? (string-trim raw) ""))
       (for/list ([piece (in-list (string-split raw ";"))]
                  #:when (not (string=? (string-trim piece) "")))
         (let* ([parts (map string-trim (string-split piece ":"))]
                [parsed (map (lambda (part)
                               (or (and (regexp-match? #px"^-?[0-9]+$" part)
                                        (string->number part))
                                   (string->symbol part)))
                             parts)])
           (unless (and (pair? parsed) (symbol? (car parsed)))
             (error "Invalid SICK_DEBUG_SUBS entry"))
           parsed))))

(define sick-debug-subs
  (make-parameter (parse-debug-subspecs "SICK_DEBUG_SUBS")))

(define (parse-debug-node-roots env-name)
  (define raw (getenv env-name))
  (and raw
       (not (string=? (string-trim raw) ""))
       (for/list ([piece (in-list (string-split raw ";"))]
                  #:when (not (string=? (string-trim piece) "")))
         (let ([parts (map string-trim (string-split piece ":"))])
           (unless (= (length parts) 2)
             (error "Invalid SICK_DEBUG_NODES entry"))
           (map (lambda (part)
                  (or (and (regexp-match? #px"^-?[0-9]+$" part)
                           (string->number part))
                      (string->symbol part)))
                parts)))))

(define sick-debug-node-roots
  (make-parameter (parse-debug-node-roots "SICK_DEBUG_NODES")))

(define sick-debug-node-depth
  (make-parameter
   (let ([raw (getenv "SICK_DEBUG_NODE_DEPTH")])
     (or (and raw
              (regexp-match? #px"^[0-9]+$" (string-trim raw))
              (string->number (string-trim raw)))
         3))))

(define sick-break-hit
  (make-parameter
   (let ([raw (getenv "SICK_BREAK_HIT")])
     (or (and raw
              (regexp-match? #px"^[0-9]+$" (string-trim raw))
              (string->number (string-trim raw)))
         1))))

(define sick-max-steps
  (make-parameter
   (let ([raw (getenv "SICK_MAX_STEPS")])
     (and raw
          (regexp-match? #px"^[0-9]+$" (string-trim raw))
          (string->number (string-trim raw))))))

(define sick-debug-history-limit
  (make-parameter
   (let ([raw (getenv "SICK_DEBUG_HISTORY")])
     (or (and raw (string->number (string-trim raw)))
         400))))

(define intercal-clean-token-rx
  #px"\\(|\\)|<-|~|\\$|#|\\+|\\.|:|\\*|,|;|&|\\?|!|%|'|\"|[0-9]+|[A-Za-z][A-Za-z0-9]*")

(define intercal-prefix-tokens '("PLEASE" "DO" "NOT" "MAYBE" "%" "DON'T"))

(define intercal-valid-start-rx
  #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|DON'T|MAYBE|%[0-9]+)[ \t]*)+(?:STASH|RETRIEVE|IGNORE|REMEMBER|ABSTAIN|REINSTATE|FORGET|RESUME|READ|WRITE|COME|GIVE|TRY|NOTHING|[.:,;]|\\()")

(define intercal-prefix-start-rx
  #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|DON'T|MAYBE|%[0-9]+)[ \t]*)+")

(define intercal-continuation-rx
  #px"^[ \t]+[\"'?&V!#0-9.:,;~$A-Za-z+-]+$")

(define intercal-incomplete-start-rx
  #px"^(?:.*(?:<-|RESUME|FORGET|STASH|RETRIEVE|READ OUT|WRITE IN|ABSTAIN(?: [^ ]+)? FROM|REINSTATE|SUB|BY|\\$|~|&|V|\\?|['\"]))[ \t]*$")

(define (intercal-cleanable-line? line)
  (or (regexp-match? intercal-valid-start-rx line)
      (regexp-match? intercal-prefix-start-rx line)
      (regexp-match? intercal-continuation-rx line)))

(define (merge-intercal-continuations str)
  (define lines (string-split str "\n"))
  (define logical-lines '())
  (define current #f)
  (define (flush-current!)
    (when current
      (set! logical-lines (cons current logical-lines))
      (set! current #f)))
  (for ([line (in-list lines)])
    (cond
      [(or (regexp-match? intercal-valid-start-rx line)
           (regexp-match? intercal-prefix-start-rx line))
       (flush-current!)
       (set! current line)]
      [(regexp-match? intercal-continuation-rx line)
       (when current
         (set! current
               (string-append current " " (string-trim line))))]
      [else
       (flush-current!)]))
  (flush-current!)
  (reverse logical-lines))

(define (parseable-line-prefix line)
  (define tokens
    (regexp-match*
     intercal-clean-token-rx
     (string-replace
      (string-replace line "!" "'.")
      "DON'T" "DO NOT")))
  (for/or ([n (in-range (length tokens) 0 -1)])
    (define candidate (string-join (take tokens n) " "))
    (with-handlers ([exn:fail? (lambda (_) #f)])
      (parse (tokenize (open-input-string candidate)))
      candidate)))

(define (fallback-nothing-line line)
  (define tokens
    (regexp-match*
     intercal-clean-token-rx
     (string-replace
      (string-replace line "!" "'.")
      "DON'T" "DO NOT")))
  (define-values (label-prefix rest)
    (if (and (>= (length tokens) 3)
             (equal? (list-ref tokens 0) "(")
             (regexp-match? #px"^[0-9]+$" (list-ref tokens 1))
             (equal? (list-ref tokens 2) ")"))
        (values (take tokens 3) (drop tokens 3))
        (values '() tokens)))
  (define prefix-only
    (let loop ([ts rest] [acc '()])
      (cond
        [(null? ts) (reverse acc)]
        [(equal? (car ts) "%")
         (if (and (pair? (cdr ts))
                  (regexp-match? #px"^[0-9]+$" (cadr ts)))
             (loop (cddr ts) (cons (cadr ts) (cons "%" acc)))
             (reverse acc))]
        [(member (car ts) intercal-prefix-tokens)
         (loop (cdr ts) (cons (car ts) acc))]
        [else (reverse acc)])))
  (and (pair? prefix-only)
       (string-join (append label-prefix prefix-only '("NOTHING")) " ")))

(define (clean-intercal-source str)
  (define merged-lines (merge-intercal-continuations str))
  (define cleaned-lines
    (filter values
            (map (lambda (line)
                   (cond
                     [(regexp-match? intercal-valid-start-rx line)
                      (if (regexp-match? intercal-incomplete-start-rx line)
                          line
                          (parseable-line-prefix line))]
                     [(regexp-match? intercal-prefix-start-rx line)
                      (or (parseable-line-prefix line)
                          (fallback-nothing-line line))]
                     [else #f]))
                 merged-lines)))
  (string-join cleaned-lines "\n"))

(begin-for-syntax
  (define intercal-clean-token-rx
    #px"\\(|\\)|<-|~|\\$|#|\\+|\\.|:|\\*|,|;|&|\\?|!|%|'|\"|[0-9]+|[A-Za-z][A-Za-z0-9]*")

  (define intercal-prefix-tokens '("PLEASE" "DO" "NOT" "MAYBE" "%" "DON'T"))

  (define intercal-valid-start-rx
    #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|DON'T|MAYBE|%[0-9]+)[ \t]*)+(?:STASH|RETRIEVE|IGNORE|REMEMBER|ABSTAIN|REINSTATE|FORGET|RESUME|READ|WRITE|COME|GIVE|TRY|NOTHING|[.:,;]|\\()")

  (define intercal-prefix-start-rx
    #px"^[ \t]*(?:\\([0-9]+\\)[ \t]*)?(?:(?:PLEASE|DO|NOT|DON'T|MAYBE|%[0-9]+)[ \t]*)+")

  (define intercal-continuation-rx
    #px"^[ \t]+[\"'?&V!#0-9.:,;~$A-Za-z+-]+$")

  (define intercal-incomplete-start-rx
    #px"^(?:.*(?:<-|RESUME|FORGET|STASH|RETRIEVE|READ OUT|WRITE IN|ABSTAIN(?: [^ ]+)? FROM|REINSTATE|SUB|BY|\\$|~|&|V|\\?|['\"]))[ \t]*$")

  (define (merge-intercal-continuations str)
    (define lines (string-split str "\n"))
    (define logical-lines '())
    (define current #f)
    (define (flush-current!)
      (when current
        (set! logical-lines (cons current logical-lines))
        (set! current #f)))
    (for ([line (in-list lines)])
      (cond
        [(or (regexp-match? intercal-valid-start-rx line)
             (regexp-match? intercal-prefix-start-rx line))
         (flush-current!)
         (set! current line)]
        [(regexp-match? intercal-continuation-rx line)
         (when current
           (set! current
                 (string-append current " " (string-trim line))))]
        [else
         (flush-current!)]))
    (flush-current!)
    (reverse logical-lines))

  (define (parseable-line-prefix line)
    (define tokens
      (regexp-match*
       intercal-clean-token-rx
       (string-replace
        (string-replace line "!" "'.")
        "DON'T" "DO NOT")))
    (for/or ([n (in-range (length tokens) 0 -1)])
      (define candidate (string-join (take tokens n) " "))
      (with-handlers ([exn:fail? (lambda (_) #f)])
        (parse (tokenize (open-input-string candidate)))
        candidate)))

  (define (fallback-nothing-line line)
    (define tokens
      (regexp-match*
       intercal-clean-token-rx
       (string-replace
        (string-replace line "!" "'.")
        "DON'T" "DO NOT")))
    (define-values (label-prefix rest)
      (if (and (>= (length tokens) 3)
               (equal? (list-ref tokens 0) "(")
               (regexp-match? #px"^[0-9]+$" (list-ref tokens 1))
               (equal? (list-ref tokens 2) ")"))
          (values (take tokens 3) (drop tokens 3))
          (values '() tokens)))
    (define prefix-only
      (let loop ([ts rest] [acc '()])
        (cond
          [(null? ts) (reverse acc)]
          [(equal? (car ts) "%")
           (if (and (pair? (cdr ts))
                    (regexp-match? #px"^[0-9]+$" (cadr ts)))
               (loop (cddr ts) (cons (cadr ts) (cons "%" acc)))
               (reverse acc))]
          [(member (car ts) intercal-prefix-tokens)
           (loop (cdr ts) (cons (car ts) acc))]
          [else (reverse acc)])))
    (and (pair? prefix-only)
         (string-join (append label-prefix prefix-only '("NOTHING")) " ")))

  (define (clean-intercal-source str)
    (define merged-lines (merge-intercal-continuations str))
    (define cleaned-lines
      (filter values
              (map (lambda (line)
                     (cond
                       [(regexp-match? intercal-valid-start-rx line)
                        (if (regexp-match? intercal-incomplete-start-rx line)
                            line
                            (parseable-line-prefix line))]
                       [(regexp-match? intercal-prefix-start-rx line)
                        (or (parseable-line-prefix line)
                            (fallback-nothing-line line))]
                       [else #f]))
                   merged-lines)))
    (string-join cleaned-lines "\n")))

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

(define (reverse-byte c)
  (define x (bitwise-and c #xff))
  (define x1 (bitwise-ior (arithmetic-shift (bitwise-and x #x0f) 4)
                          (arithmetic-shift (bitwise-and x #xf0) -4)))
  (define x2 (bitwise-ior (arithmetic-shift (bitwise-and x1 #x33) 2)
                          (arithmetic-shift (bitwise-and x1 #xcc) -2)))
  (bitwise-ior (arithmetic-shift (bitwise-and x2 #x55) 1)
               (arithmetic-shift (bitwise-and x2 #xaa) -1)))

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

(define-for-syntax (flatten-sub-datum datum)
  (match datum
    [`(sub ,base ,idxs ...)
     (define flat-base (flatten-sub-datum base))
     (define flat-idxs (map flatten-sub-datum idxs))
     (match flat-base
       [`(sub ,inner-base ,inner-idxs ...)
        `(sub ,inner-base ,@inner-idxs ,@flat-idxs)]
       [_ `(sub ,flat-base ,@flat-idxs)])]
    [(list elems ...)
     (map flatten-sub-datum elems)]
    [_ datum]))

(define-for-syntax (symbol-width sym)
  (define str (and (symbol? sym) (symbol->string sym)))
  (cond
    [(not str) 16]
    [(or (string-prefix? str ":")
         (string-prefix? str ";"))
     32]
    [else 16]))

(define-for-syntax (expr-width datum)
  (match datum
    [`(mesh ,_) 16]
    [`(mingle ,_ ,_) 32]
    [`(mingle-16 ,_ ,_) 32]
    [`(select ,_ ,rhs) (expr-width rhs)]
    [`(select-16 ,_ ,_) 16]
    [`(select-32 ,_ ,_) 32]
    [`(unary-and ,rhs) (expr-width rhs)]
    [`(unary-or ,rhs) (expr-width rhs)]
    [`(unary-xor ,rhs) (expr-width rhs)]
    [`(unary-and-16 ,_) 16]
    [`(unary-and-32 ,_) 32]
    [`(unary-or-16 ,_) 16]
    [`(unary-or-32 ,_) 32]
    [`(unary-xor-16 ,_) 16]
    [`(unary-xor-32 ,_) 32]
    [`(sub ,base ,_ ...) (expr-width base)]
    [(? symbol? sym) (symbol-width sym)]
    [_ 16]))

(define-for-syntax (rewrite-width-aware-ops datum)
  (match datum
    [`(mingle ,lhs ,rhs)
     `(mingle-16
       ,(rewrite-width-aware-ops lhs)
       ,(rewrite-width-aware-ops rhs))]
    [`(select ,lhs ,rhs)
     (define rewritten-rhs (rewrite-width-aware-ops rhs))
     (define width (expr-width rewritten-rhs))
     `(,(if (= width 32) 'select-32 'select-16)
       ,(rewrite-width-aware-ops lhs)
       ,rewritten-rhs)]
    [`(unary-and ,rhs)
     (define rewritten-rhs (rewrite-width-aware-ops rhs))
     `(,(if (= (expr-width rewritten-rhs) 32) 'unary-and-32 'unary-and-16)
       ,rewritten-rhs)]
    [`(unary-or ,rhs)
     (define rewritten-rhs (rewrite-width-aware-ops rhs))
     `(,(if (= (expr-width rewritten-rhs) 32) 'unary-or-32 'unary-or-16)
       ,rewritten-rhs)]
    [`(unary-xor ,rhs)
     (define rewritten-rhs (rewrite-width-aware-ops rhs))
     `(,(if (= (expr-width rewritten-rhs) 32) 'unary-xor-32 'unary-xor-16)
       ,rewritten-rhs)]
    [`(sub ,base ,idxs ...)
     `(sub ,(rewrite-width-aware-ops base)
           ,@(map rewrite-width-aware-ops idxs))]
    [(list elems ...)
     (map rewrite-width-aware-ops elems)]
    [_ datum]))

(define-for-syntax (flatten-sub-stx stx)
  (datum->syntax stx
                 (rewrite-width-aware-ops
                  (flatten-sub-datum (syntax->datum stx)))
                 stx
                 stx))

(define-for-syntax (op->gerunds datum)
  (match datum
    [`(assign . ,_) '(calculating)]
    [`(next . ,_) '(nexting)]
    [`(read-out . ,_) '(reading-out)]
    [`(write-in . ,_) '(writing-in)]
    [`(stash . ,_) '(stashing)]
    [`(retrieve . ,_) '(retrieving)]
    [`(ignore . ,_) '(ignoring)]
    [`(remember . ,_) '(remembering)]
    [`(forget . ,_) '(forgetting)]
    [`(resume . ,_) '(resuming)]
    [`(abstain . ,_) '(abstaining)]
    [`(abstain-count . ,_) '(abstaining)]
    [`(abstain-gerunds-once . ,_) '(abstaining)]
    [`(abstain-gerunds . ,_) '(abstaining)]
    [`(reinstate . ,_) '(reinstating)]
    [`(reinstate-gerunds . ,_) '(reinstating)]
    [`(try-again) '(trying-again)]
    [_ '()]))


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
                         (member (substring str 0 1) '("." ":" "*" "," ";")))))
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

     (define gerund->lns-map
       (let ([h (make-hash)])
         (for-each
          (lambda (l-ln l-op)
            (define ln (syntax-e l-ln))
            (for ([gerund (in-list (op->gerunds (syntax->datum l-op)))])
              (hash-set! h gerund (cons ln (hash-ref h gerund '())))))
          (syntax->list #'(ln ...))
          ops)
         (for/hash ([(k v) (in-hash h)])
           (values k (reverse v)))))

     (define give-up-lines
       (for/list ([l-ln (in-list (syntax->list #'(ln ...)))]
                  [l-op (in-list ops)]
                  #:when (match (syntax->datum l-op)
                           [`(give-up) #t]
                           [_ #f]))
         (syntax-e l-ln)))

     (define first-ln (syntax-e (car (syntax->list #'(ln ...)))))

     (define ln->lbl-map
       (let ([h (make-hash)])
         (for-each (lambda (l-ln l-lbl)
                     (let ([lbl-val (syntax-e l-lbl)])
                       (unless (eq? lbl-val '_)
                         (hash-set! h (syntax-e l-ln) lbl-val))))
                   (syntax->list #'(ln ...))
                   (syntax->list #'(lbl ...)))
         h))

     (define ln->op-map
       (let ([h (make-hash)])
         (for-each (lambda (l-ln l-op)
                     (hash-set! h (syntax-e l-ln)
                                (syntax->datum (flatten-sub-stx l-op))))
                   (syntax->list #'(ln ...))
                   ops)
         h))

     (define var-definitions
       (map (lambda (v)
              (define vid (datum->syntax stx v))
              (define vstack (datum->syntax stx (string->symbol (string-append (symbol->string v) "-stack"))))
              (define str (symbol->string v))
              (if (or (string-prefix? str "*")
                      (string-prefix? str ",")
                      (string-prefix? str ";"))
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
            (define current-op (flatten-sub-stx (car operations)))
            (define next-ln-val (if (null? (cdr lns)) #f (syntax-e (cadr lns))))

            (define compiled-op
              (syntax-parse current-op
                [((~datum assign) var ((~datum dimension) dim ...))
                 (let ([var-str (symbol->string (syntax-e #'var))])
                   (if (or (string-prefix? var-str "*")
                           (string-prefix? var-str ",")
                           (string-prefix? var-str ";"))
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
                          (trace! 'assign
                                  (format "pc=~a target=~a idxs=~a value=~a" #,current-ln '#,base (list #,@idx-stxs) val)
                                  #:line #,current-ln
                                  #:var '#,base)
                          (intercal-array-set!* #,base-stx
                                                (list #,@idx-stxs)
                                                (checked-element-store-value '#,base val)))]
                     [(and var-str
                           (or (string-prefix? var-str "*")
                               (string-prefix? var-str ",")
                               (string-prefix? var-str ";")))
                      #`(unless (hash-ref ignore-tbl (quote var) #f)
                          (trace! 'assign
                                  (format "pc=~a target=~a value=~a" #,current-ln 'var val)
                                  #:line #,current-ln
                                  #:var 'var)
                          (set! var (make-intercal-array (list val))))]
                     [else
                      #`(unless (hash-ref ignore-tbl (quote var) #f)
                          (trace! 'assign
                                  (format "pc=~a target=~a value=~a" #,current-ln '#,target-datum val)
                                  #:line #,current-ln
                                  #:var '#,target-datum)
                          (set! var (checked-store-value '#,target-datum val)))]))]
                [((~datum stash) var ...)
                 #`(begin
                     #,@(map (lambda (v)
                               (let ([vstack (datum->syntax stx (string->symbol (string-append (symbol->string (syntax-e v)) "-stack")))])
                                 #`(begin
                                     (trace! 'stash
                                             (format "pc=~a var=~a value=~a depth-before=~a" #,current-ln '#,(syntax-e v) #,v (length #,vstack))
                                             #:line #,current-ln
                                             #:var '#,(syntax-e v))
                                     (set! #,vstack (cons #,v #,vstack)))))
                             (syntax->list #'(var ...))))]
                [((~datum retrieve) var ...)
                 #`(begin
                     #,@(map (lambda (v)
                               (let ([vstack (datum->syntax stx (string->symbol (string-append (symbol->string (syntax-e v)) "-stack")))])
                                 #`(begin
                                     (when (null? #,vstack)
                                       (trace! 'retrieve-error
                                               (format "pc=~a var=~a depth-before=0" #,current-ln '#,(syntax-e v))
                                               #:line #,current-ln
                                               #:var '#,(syntax-e v))
                                       (runtime-fail (ick-err "E436")))
                                     (let ([retrieved-val (car #,vstack)])
                                       (trace! 'retrieve
                                               (format "pc=~a var=~a value=~a depth-before=~a" #,current-ln '#,(syntax-e v) retrieved-val (length #,vstack))
                                               #:line #,current-ln
                                               #:var '#,(syntax-e v))
                                       (set! #,vstack (cdr #,vstack))
                                       (unless (hash-ref ignore-tbl (quote #,v) #f)
                                         (set! #,v (checked-store-value '#,(syntax-e v) retrieved-val)))))))
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
                 (let* ([target-datum (syntax->datum #'var)]
                        [var-str (and (symbol? target-datum) (symbol->string target-datum))]
                        [ignored-expr (if var-str
                                          #`(hash-ref ignore-tbl (quote var) #f)
                                          #`#f)])
                   (define-values (base idxs) (extract-sub-target target-datum))
                   (cond
                     [base
                      (define base-stx (datum->syntax stx base))
                      (define idx-stxs (map (lambda (idx) (datum->syntax stx idx)) idxs))
                      #`(let ([input-val (read-number-input!)])
                          (unless (hash-ref ignore-tbl (quote #,base-stx) #f)
                            (intercal-array-set!* #,base-stx
                                                  (list #,@idx-stxs)
                                                  (checked-element-store-value '#,base input-val))))]
                     [(and var-str
                           (or (string-prefix? var-str "*")
                               (string-prefix? var-str ",")
                               (string-prefix? var-str ";")))
                     #'(read-array-input! var (hash-ref ignore-tbl (quote var) #f))]
                     [else
                      #`(let ([input-val (read-number-input!)])
                          (unless #,ignored-expr
                            (set! var (checked-store-value '#,target-datum input-val))))]))]
                [((~datum read-out) var)
                 #`(let ([v var])
                     (trace! 'read-out
                             (format "pc=~a value=~a" #,current-ln v)
                             #:line #,current-ln)
                     (cond
                       [(or (vector? v) (intercal-array? v))
                        (write-array-output! v)
                        (set! output-acc (append (reverse (array-output-list v)) output-acc))]
                       [else
                        (displayln
                         (cond ((and (number? v) (zero? v)) "_")
                               ((number? v) (string-upcase (number->roman v)))
                               (else "")))
                        (set! output-acc (cons v output-acc))]))]

                [((~datum abstain) (~optional (~datum from)) target)
                 (let ([t (eval-label-target #'target)])
                   #`(abstain-line-once! (get-abstain-ln-for-lbl '#,t)))]
                [((~datum abstain-count) count target)
                 (let ([t (eval-label-target #'target)])
                   #`(abstain-line-count! (get-abstain-ln-for-lbl '#,t) count))]
                [((~datum abstain-gerunds-once) gerund ...)
                 #`(abstain-gerunds-once! '(gerund ...))]
                [((~datum abstain-gerunds) count gerund ...)
                 #`(abstain-gerunds! count '(gerund ...))]
                [((~datum reinstate) target)
                 (let ([t (eval-label-target #'target)])
                   #`(reinstate-line-once! (get-abstain-ln-for-lbl '#,t)))]
                [((~datum reinstate-gerunds) gerund ...)
                 #`(reinstate-gerunds! '(gerund ...))]

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
                [((~datum try-again))        #`(void)]
                [(~datum try-again)          #`(void)]
                [((~datum give-up))          #`(void)]
                [(~datum give-up)            #`(void)]
                [_ #`(void)]))

            (define branch
              (let ([lbl-val (syntax-e current-lbl)]
                    [pct-val (syntax-e current-pct)])
                (define natural-next-stx
                  (syntax-parse current-op
                    [((~datum try-again)) #`(apply values (reverse output-acc))]
                    [(~datum try-again)   #`(apply values (reverse output-acc))]
                    [_ #`(loop (get-actual-next '#,lbl-val '#,next-ln-val))]))
                (define continue-stx
                  (syntax-parse current-op
                    [((~datum give-up)) #`(apply values (reverse output-acc))]
                    [(~datum give-up)   #`(apply values (reverse output-acc))]
                    [((~datum try-again))
                     #`(begin
                         (trace! 'try-again (format "pc=~a -> ~a" #,current-ln #,first-ln) #:line #,current-ln)
                         (loop #,first-ln))]
                    [(~datum try-again)
                     #`(begin
                         (trace! 'try-again (format "pc=~a -> ~a" #,current-ln #,first-ln) #:line #,current-ln)
                         (loop #,first-ln))]
                    [((~datum next) target)
                     (let ([t (eval-label-target #'target)])
                       #`(begin
                           (trace! 'next (format "pc=~a target=~a stack=~a" #,current-ln '#,t next-stack) #:line #,current-ln)
                           (loop (get-ln-for-lbl '#,t))))]
                    [((~datum resume) var)
                     #`(let ([count var])
                         (cond
                           [(<= count 0) (runtime-fail (ick-err "E632"))]
                           [(> count (length next-stack))
                            (trace! 'resume-error (format "pc=~a count=~a stack=~a" #,current-ln count next-stack) #:line #,current-ln)
                            (runtime-fail (ick-err "E632"))]
                           [else
                            (let ([target-pc (list-ref next-stack (- count 1))])
                              (trace! 'resume (format "pc=~a count=~a target=~a stack-before=~a" #,current-ln count target-pc next-stack) #:line #,current-ln)
                              (set! next-stack (drop next-stack count))
                              (loop target-pc))]))]
                    [((~datum forget) var)
                     #`(let* ([count var]
                              [drop-count (max 0 (min count (length next-stack)))])
                         (trace! 'forget (format "pc=~a count=~a effective=~a stack-before=~a" #,current-ln count drop-count next-stack) #:line #,current-ln)
                         (set! next-stack (drop next-stack drop-count))
                         (loop (get-actual-next '#,lbl-val '#,next-ln-val)))]
                    [_ #`(loop (get-actual-next '#,lbl-val '#,next-ln-val))]))
                (define execute-stx
                  (cond
                    [(>= pct-val 100)
                     #`(begin
                         #,compiled-op
                         #,(if (or is-once-val is-again-val) #`(update-state! #,current-ln) #`(void))
                         #,continue-stx)]
                    [(<= pct-val 0)
                     #`(begin
                         (trace! 'chance-skip (format "pc=~a pct=~a" #,current-ln #,pct-val) #:line #,current-ln)
                         #,natural-next-stx)]
                    [else
                     #`(let ([roll (random 100)])
                         (if (< roll #,pct-val)
                             (begin
                               #,compiled-op
                               #,(if (or is-once-val is-again-val) #`(update-state! #,current-ln) #`(void))
                               #,continue-stx)
                             (begin
                               (trace! 'chance-skip (format "pc=~a pct=~a roll=~a" #,current-ln #,pct-val roll) #:line #,current-ln)
                               #,natural-next-stx)))])
                  )
                #`((#,current-ln)
                   (let ([abstain-count (hash-ref abstain-tbl #,current-ln 0)])
                     (define is-abstained? (positive? abstain-count))
                     (if is-abstained?
                         (begin
                           ;; Skipped! Update state based on modifiers, and ALWAYS BROADCAST LABEL
                           (trace! 'skip (format "pc=~a label=~a abstain-count=~a" #,current-ln '#,lbl-val abstain-count) #:line #,current-ln)
                           #,(if (or is-once-val is-again-val) #`(update-state! #,current-ln) #`(void))
                           #,natural-next-stx)
                         #,execute-stx))))
                )

            (cons branch (loop (cdr lns) (cdr lbls) (cdr pcts) (cdr is-onces) (cdr is-agains) (cdr operations)))])))

     ;; --- Final Code Assembly ---
     #`(let ()
         #,@var-definitions
         (define output-acc '())
         (define next-stack '())
         (define ignore-tbl (make-hash))
         (define debug? (sick-debug))
         (define debug-vars (sick-debug-vars))
         (define debug-lines (sick-debug-lines))
         (define break-lines (sick-break-lines))
         (define debug-subs (sick-debug-subs))
         (define debug-node-roots (sick-debug-node-roots))
         (define debug-node-depth (sick-debug-node-depth))
         (define break-hit-target (max 1 (sick-break-hit)))
         (define max-steps (sick-max-steps))
         (define debug-history-limit (sick-debug-history-limit))
         (define tape-last-in 0)
         (define tape-last-out 0)
         (define recent-trace-events '())
         (define breakpoint-hit-counts (make-hash))
         (define step-count 0)

         (define (remember-trace! line)
           (set! recent-trace-events
                 (let ([events (cons line recent-trace-events)]
                       [limit (max 0 debug-history-limit)])
                   (if (<= (length events) limit)
                       events
                       (take events limit)))))

         (define (dump-recent-trace!)
           (when debug?
             (parameterize ([current-output-port (current-error-port)])
               (fprintf (current-output-port) "[sick backtrace] recent-events=~a\n"
                        (length recent-trace-events))
               (for ([line (in-list (reverse recent-trace-events))])
                 (fprintf (current-output-port) "~a\n" line)))))

         (define (tracked-line? maybe-line)
           (or (not debug-lines)
               (and maybe-line (member maybe-line debug-lines))))

         (define (tracked-var? maybe-var)
           (or (not debug-vars)
               (not maybe-var)
               (member maybe-var debug-vars)))

         (define (trace! tag msg #:line [line #f] #:var [var #f])
           (when debug?
             (when (and (tracked-line? line)
                        (tracked-var? var))
               (define rendered (format "[sick ~a] ~a" tag msg))
               (remember-trace! rendered)
               (parameterize ([current-output-port (current-error-port)])
                 (fprintf (current-output-port) "~a\n" rendered)))))

         (define (runtime-fail msg)
           (dump-recent-trace!)
           (error msg))

         (define (check-step-limit! pc)
           (when max-steps
             (set! step-count (add1 step-count))
             (when (> step-count max-steps)
               (parameterize ([current-output-port (current-error-port)])
                 (fprintf (current-output-port)
                          "[sick limit] max-steps=~a reached at pc=~a label=~a op=~s stack=~a\n"
                          max-steps
                          pc
                          (hash-ref rt-ln->lbl-map pc '_)
                          (hash-ref ln->op-map pc #f)
                          next-stack))
               (dump-recent-trace!)
               (error (format "SICK max steps reached at line ~a" pc)))))

         (define (breakpoint-line? maybe-line)
           (and maybe-line
                break-lines
                (member maybe-line break-lines)
                (let ([hit-count (add1 (hash-ref breakpoint-hit-counts maybe-line 0))])
                  (hash-set! breakpoint-hit-counts maybe-line hit-count)
                  (= hit-count break-hit-target))))

         (define onespot-max #xffff)
         (define twospot-max #xffffffff)

         (define (array-var-name? sym)
           (define str (and (symbol? sym) (symbol->string sym)))
           (and str
                (member (substring str 0 1) '("*" "," ";"))))

         (define (onespot-value-target? sym)
           (define str (and (symbol? sym) (symbol->string sym)))
           (and str
                (member (substring str 0 1) '("." "*" ","))))

         (define (twospot-value-target? sym)
           (define str (and (symbol? sym) (symbol->string sym)))
           (and str
                (member (substring str 0 1) '(":" ";"))))

         (define (checked-scalar-store-value sym val)
           (cond
             [(onespot-value-target? sym)
              (cond
                [(and (exact-integer? val) (<= 0 val onespot-max)) val]
                [(and (exact-integer? val) (<= 0 val twospot-max))
                 (runtime-fail (ick-err "E275"))]
                [else
                 (runtime-fail (ick-err "E533"))])]
             [(twospot-value-target? sym)
              (if (and (exact-integer? val) (<= 0 val twospot-max))
                  val
                  (runtime-fail (ick-err "E533")))]
             [else val]))

         (define (checked-store-value sym val)
           (if (array-var-name? sym)
               val
               (checked-scalar-store-value sym val)))

         (define (checked-element-store-value sym val)
           (checked-scalar-store-value sym val))

         (define (#,(datum->syntax stx 'sub) arr . idxs)
           (intercal-array-ref* arr idxs))

         (define (read-number-input!)
           (define line (read-line))
           (when (eof-object? line)
             (runtime-fail (ick-err "E562")))
           (string->number
            (string-join
             (map number->string
                  (map arabic->number
                       (string-split line)))
             "")))

         (define (read-array-input! arr ignored?)
           (define actual-arr (ensure-intercal-array arr))
           (unless (= (length (intercal-array-dimensions actual-arr)) 1)
             (ick-err "E241"))
           (for ([i (in-range (vector-length (intercal-array-data actual-arr)))])
             (define c (read-byte))
             (define v (if (eof-object? c)
                           256
                           (modulo (- c tape-last-in) 256)))
             (set! tape-last-in (if (eof-object? c) -1 c))
             (unless ignored?
               (vector-set! (intercal-array-data actual-arr) i v))))

         (define (write-array-output! arr)
           (define actual-arr (ensure-intercal-array arr))
           (unless (= (length (intercal-array-dimensions actual-arr)) 1)
             (ick-err "E241"))
           (for ([v (in-vector (intercal-array-data actual-arr))])
             (define c (reverse-byte (modulo (- tape-last-out v) 256)))
             (set! tape-last-out (modulo (- tape-last-out v) 256))
             (write-byte c)
             (when (or (= c 10) #f)
               (flush-output)))
           (flush-output))

         ;; State tables for the Unified Theory
         (define source-is-not-tbl (make-hash))
         (define has-once-tbl (make-hash))
         (define has-again-tbl (make-hash))
         (define abstain-tbl (make-hash))
         (define gerund->lns-map '#,gerund->lns-map)
         (define give-up-line-set '#,give-up-lines)
         (define ln->op-map '#,ln->op-map)

         #,@(filter-map (lambda (l-ln l-is-not)
                          #`(begin
                              (hash-set! source-is-not-tbl #,l-ln #,l-is-not)
                              (hash-set! abstain-tbl #,l-ln (if #,l-is-not 1 0))))
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
              (hash-set! abstain-tbl target-ln (if (hash-ref source-is-not-tbl target-ln) 0 1))]
             [(hash-ref has-again-tbl target-ln #f)
              (hash-set! abstain-tbl target-ln (if (hash-ref source-is-not-tbl target-ln) 1 0))]))

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

         (define (resolve-debug-sub-part part)
           (cond
             [(number? part) part]
             #,@(map (lambda (v)
                       (let ([vid (datum->syntax stx v)])
                         #`[(eq? part '#,v) #,vid]))
                     all-vars)
             [else part]))

         (define (debug-var-snapshots)
           (filter values
                   (list
                    #,@(map (lambda (v)
                              (let ([vid (datum->syntax stx v)]
                                    [vstack (datum->syntax stx (string->symbol (string-append (symbol->string v) "-stack")))])
                                #`(let ([sym '#,v])
                                    (and (tracked-var? sym)
                                         (list sym
                                               #,vid
                                               (length #,vstack))))))
                            all-vars))))

         (define (debug-sub-snapshots)
           (filter values
                   (for/list ([spec (in-list (or debug-subs '()))])
                     (define base (car spec))
                     (define raw-idxs (cdr spec))
                     (define idxs (map resolve-debug-sub-part raw-idxs))
                     (define arr
                       (cond
                         #,@(filter-map
                             (lambda (v)
                               (define str (symbol->string v))
                               (and (member (substring str 0 1) '("*" "," ";"))
                                    (let ([vid (datum->syntax stx v)])
                                      #`[(eq? base '#,v) #,vid])))
                             all-vars)
                         [else #f]))
                     (and arr
                          (list base
                                idxs
                                (with-handlers ([exn:fail? (lambda (_) '<invalid>)])
                                  (intercal-array-ref* arr idxs)))))))

         (define maybe-node-store
           (cond
             #,@(filter-map
                 (lambda (v)
                   (and (string=? (symbol->string v) ",201")
                        (let ([vid (datum->syntax stx v)])
                          #`[#t #,vid])))
                 all-vars)
             [else #f]))

         (define (debug-node-dump-lines)
           (cond
             [(or (not maybe-node-store) (not debug-node-roots)) '()]
             [else
              (define seen (make-hash))
              (define lines '())
              (define (emit! fmt . args)
                (set! lines (cons (apply format fmt args) lines)))
              (define (fetch-field i j k)
                (with-handlers ([exn:fail? (lambda (_) '<invalid>)])
                  (intercal-array-ref* maybe-node-store (list i j k))))
               (define (walk root-name i j depth)
                 (define key (list i j))
                 (cond
                   [(hash-ref seen key #f)
                    (emit! "[sick node] root=~a depth=~a node=~s cycle"
                          root-name depth key)]
                  [else
                   (hash-set! seen key #t)
                   (define fields
                     (for/list ([k (in-range 1 8)])
                       (fetch-field i j k)))
                   (emit! "[sick node] root=~a depth=~a node=~s fields=~s"
                          root-name depth key fields)
                   (when (< depth debug-node-depth)
                     (match fields
                       [(list _ _ car-i car-j cdr-i cdr-j _)
                        (when (and (integer? car-i) (integer? car-j))
                          (walk root-name car-i car-j (add1 depth)))
                        (when (and (integer? cdr-i) (integer? cdr-j))
                          (walk root-name cdr-i cdr-j (add1 depth)))]
                       [_ (void)]))]))
               (for ([spec (in-list debug-node-roots)])
                 (define idxs (map resolve-debug-sub-part spec))
                 (when (and (= (length idxs) 2)
                            (andmap integer? idxs))
                   (walk idxs (car idxs) (cadr idxs) 0)))
               (reverse lines)]))

         (define (get-ln-for-lbl target-lbl)
           (hash-ref lbl->ln-map
                     target-lbl
                     (lambda () (runtime-fail (ick-err "E129")))))

         (define (get-abstain-ln-for-lbl target-lbl)
           (hash-ref lbl->ln-map
                     target-lbl
                     (lambda () (runtime-fail (ick-err "E139")))))

         (define (abstain-count target-ln)
           (hash-ref abstain-tbl target-ln 0))

         (define (set-abstain-count! target-ln n)
           (hash-set! abstain-tbl target-ln (max 0 n)))

         (define (abstain-line-once! target-ln)
           (unless (member target-ln give-up-line-set)
             (set-abstain-count! target-ln (max 1 (abstain-count target-ln))))
           (trace! 'abstain (format "line=~a count=~a mode=once" target-ln (abstain-count target-ln)) #:line target-ln))

         (define (abstain-line-count! target-ln count)
           (set-abstain-count! target-ln (+ (abstain-count target-ln) (max 0 count)))
           (trace! 'abstain (format "line=~a count=~a mode=count add=~a" target-ln (abstain-count target-ln) count) #:line target-ln))

         (define (reinstate-line-once! target-ln)
           (unless (member target-ln give-up-line-set)
             (set-abstain-count! target-ln (sub1 (abstain-count target-ln))))
           (trace! 'reinstate (format "line=~a count=~a" target-ln (abstain-count target-ln)) #:line target-ln))

         (define (abstain-gerunds! count gerunds)
           (for ([gerund (in-list gerunds)])
             (for ([target-ln (in-list (hash-ref gerund->lns-map gerund '()))])
               (abstain-line-count! target-ln count))))

         (define (abstain-gerunds-once! gerunds)
           (for ([gerund (in-list gerunds)])
             (for ([target-ln (in-list (hash-ref gerund->lns-map gerund '()))])
               (abstain-line-once! target-ln))))

         (define (reinstate-gerunds! gerunds)
           (for ([gerund (in-list gerunds)])
             (for ([target-ln (in-list (hash-ref gerund->lns-map gerund '()))])
               (reinstate-line-once! target-ln))))

         (define (get-actual-next executed-lbl natural-next-ln)
           (if (not (eq? executed-lbl '_))
               (let ([hijackers (dict-ref cf-map executed-lbl '())])
                 (let ([active-hijackers
                        (filter (lambda (h-ln) (zero? (hash-ref abstain-tbl h-ln 0))) hijackers)])
                   (if (null? active-hijackers)
                       natural-next-ln
                       (let ([chosen (list-ref active-hijackers (random (length active-hijackers)))])
                         ;; Hijackers count as executed, so they update state too!
                         (trace! 'come-from (format "label=~a chosen=~a stack=~a" executed-lbl chosen next-stack) #:line chosen)
                         (update-state! chosen)
                         chosen))))
               natural-next-ln))

         (define (run)
           (let loop ([pc #,first-ln])
             (check-step-limit! pc)
             (when (breakpoint-line? pc)
               (parameterize ([current-output-port (current-error-port)])
                 (fprintf (current-output-port)
                          "[sick breakpoint] pc=~a label=~a op=~s stack=~a\n"
                          pc
                          (hash-ref rt-ln->lbl-map pc '_)
                          (hash-ref ln->op-map pc #f)
                          next-stack)
                 (for ([entry (in-list (debug-var-snapshots))])
                   (match-let ([(list sym val depth) entry])
                     (fprintf (current-output-port)
                              "[sick breakpoint] var=~a value=~s stash-depth=~a\n"
                              sym val depth))))
                 (for ([entry (in-list (debug-sub-snapshots))])
                   (match-let ([(list base idxs val) entry])
                     (fprintf (current-output-port)
                              "[sick breakpoint] sub=~a idxs=~s value=~s\n"
                              base idxs val)))
                 (for ([line (in-list (debug-node-dump-lines))])
                   (fprintf (current-output-port) "~a\n" line))
               (dump-recent-trace!)
               (error (format "SICK breakpoint at line ~a" pc)))
             (trace! 'pc
                     (format "pc=~a label=~a op=~s stack=~a"
                             pc
                             (hash-ref rt-ln->lbl-map pc '_)
                             (hash-ref ln->op-map pc #f)
                             next-stack)
                     #:line pc)
             (case pc
               #,@case-clauses
               [(#f) (runtime-fail (ick-err "E633"))]
               [else (runtime-fail (format "Fell off graph! PC: ~a" pc))])))
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

     ;; 1. Get raw user AST
     (define raw-user-ast (syntax->datum #'(sick-line ...)))

     (define user-defined-labels
       (for/list ([line (in-list raw-user-ast)]
                  #:when (and (pair? line) (integer? (car line))))
         (car line)))

     (define user-library-labels
       (filter (lambda (n) (<= 5000 n 5999)) user-defined-labels))

     (define (target->label target)
       (match target
         [(? integer? n) n]
         [`(mesh ,(? integer? n)) n]
         [_ #f]))

     (define (statement-label-targets stmt)
       (match stmt
         [`(% ,_ ,inner) (statement-label-targets inner)]
         [`(please ,inner) (statement-label-targets inner)]
         [`(do ,inner) (statement-label-targets inner)]
         [`(not ,inner) (statement-label-targets inner)]
         [`(once ,inner) (statement-label-targets inner)]
         [`(again ,inner) (statement-label-targets inner)]
         [`(next ,target) (filter values (list (target->label target)))]
         [`(come-from ,target) (filter values (list (target->label target)))]
         [`(abstain ,target) (filter values (list (target->label target)))]
         [`(abstain-count ,_ ,target) (filter values (list (target->label target)))]
         [`(reinstate ,target) (filter values (list (target->label target)))]
         [_ '()]))

     (define referenced-label-targets
       (remove-duplicates
        (append*
         (for/list ([line (in-list raw-user-ast)])
           (match line
             [`(,(? integer? _) ,stmt) (statement-label-targets stmt)]
             [stmt (statement-label-targets stmt)])))))

     (define (library-needed? lo hi)
       (for/or ([n (in-list referenced-label-targets)])
         (and (<= lo n hi)
              (not (member n user-defined-labels)))))

     (define (load-library-ast path)
       (define cleaned-source
         (clean-intercal-source (file->string path)))
       (define parsed-ast
         (with-handlers ([exn:fail?
                          (lambda (e)
                            (error (format "Failed to parse library ~a: ~a"
                                           path
                                           (exn-message e))))])
           (parse (tokenize (open-input-string cleaned-source)))))
       (define full-ast
         (normalize-program (syntax->datum parsed-ast)))
       (if (and (list? full-ast) (symbol? (car full-ast)))
           (cdr full-ast)
           full-ast))

     ;; 2. Parse syslib to raw AST
     (define syslib-ast (load-library-ast "syslib.i"))
     (define floatlib-ast
       (if (and (null? user-library-labels)
                (file-exists? "floatlib.i")
                (library-needed? 5000 5999))
           (load-library-ast "floatlib.i")
           '()))

     ;; 4. COMBINE the ASTs first
     (define combined-ast (append raw-user-ast syslib-ast floatlib-ast))

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
