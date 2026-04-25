#lang racket

(require racket/file
         racket/format
         racket/list
         racket/path
         racket/pretty
         racket/runtime-path
         racket/string
         brag/support
         (rename-in "../intercal.rkt"
                    [read-syntax intercal-read-syntax])
         "../ick-lexer.rkt"
         "../ick-bnf.rkt"
         "../ick-normalize.rkt")

(define-runtime-path script-dir-runtime ".")

(define script-dir
  (simplify-path script-dir-runtime))

(define repo-dir
  (simplify-path (build-path script-dir "..")))

(define snippets-dir
  (build-path script-dir "snippets"))

(define sample-source-path
  (simplify-path (build-path script-dir "sample-source.i")))

(define sample-source
  (string-append
   "(10) DO .1 <- #1\n"
   "(20) PLEASE DO (40) NEXT\n"
   "(30) DO GIVE UP\n"
   "(40) DO RESUME #1\n"))

(define sample-raw-source
  (string-append
   "THIS PROSE IS IGNORED BY THE READER\n"
   "(10) DO .1 <-\n"
   "     #1\n"
   "(20) PLEASE DO (40) NEXT\n"
   "MORE NON-PROGRAM TEXT\n"
   "(30) DO GIVE UP\n"
   "(40) DO RESUME #1\n"))

(define asset-language-module-path
  `(file ,(path->string (build-path repo-dir "intercal.rkt"))))

(define presentation-language-module-path
  "intercal.rkt")

(define normalizer-slide-snippet
  (string-append
   "(define prefix-strs (map cadr prefixes))\n"
   "(define postfix-strs (map cadr postfixes))\n"
   "\n"
   ";; Normalize the core semantic operation\n"
   "(define base-op (normalize-op op-node))\n"
   "\n"
   ";; Apply modifiers in semantic order\n"
   "(define is-not\n"
   "  (or (member \"NOT\" prefix-strs)\n"
   "      (member \"DON'T\" prefix-strs)))\n"
   "(define with-not\n"
   "  (if is-not `(not ,base-op) base-op))\n"
   "\n"
   "(define is-once (member \"ONCE\" postfix-strs))\n"
   "(define with-once\n"
   "  (if is-once `(once ,with-not) with-not))\n"
   "\n"
   "(define is-again (member \"AGAIN\" postfix-strs))\n"
   "(define with-again\n"
   "  (if is-again `(again ,with-once) with-once))\n"
   "\n"
   "(define prob-prefix\n"
   "  (findf (lambda (p)\n"
   "           (equal? (cadr p) \"%\"))\n"
   "         prefixes))\n"
   "(define with-prob\n"
   "  (if prob-prefix\n"
   "      `(% ,(caddr prob-prefix) ,with-again)\n"
   "      with-again))\n"
   "\n"
   ";; Wrap in the outermost politeness level\n"
   "(if (member \"PLEASE\" prefix-strs)\n"
   "    `(please ,with-prob)\n"
   "    `(do ,with-prob))"))

(define macro-slide-snippet
  (string-append
   "(define-syntax (sick-program-core stx)\n"
   "  (syntax-parse stx\n"
   "    [(_ (ln:integer lbl mod pct:integer\n"
   "         is-not:boolean is-once:boolean is-again:boolean op) ...)\n"
   "     (define ops (syntax->list #'(op ...)))\n"
   "\n"
   "     (define all-vars\n"
   "       (remove-duplicates\n"
   "        (filter intercal-var?\n"
   "                (flatten (map syntax->datum ops)))))\n"
   "\n"
   "     (define grouped-come-froms\n"
   "       (let ([h (make-hash)])\n"
   "         (for-each\n"
   "          (lambda (l-ln l-op)\n"
   "            (syntax-parse l-op\n"
   "              [((~datum come-from) target)\n"
   "               (define t (eval-label-target #'target))\n"
   "               (hash-set! h t (cons (syntax-e l-ln)\n"
   "                                    (hash-ref h t '())))]\n"
   "              [_ (void)]))\n"
   "          (syntax->list #'(ln ...)) ops)\n"
   "         (hash-map h cons)))\n"
   "\n"
   "     (define gerund->lns-map\n"
   "       (build-gerund-map #'(ln ...) ops))\n"
   "     ...]))"))

(define state-machine-shape
  (string-append
   "(let ()\n"
   "  (define |.1| 0)\n"
   "  (define output-acc '())\n"
   "  (define next-stack '())\n"
   "\n"
   "  (define (run)\n"
   "    (let loop ([pc 1])\n"
   "      (case pc\n"
   "        [(1) (set! |.1| (mesh 1)) (loop 2)]\n"
   "        [(2) (set! next-stack (cons 3 next-stack))\n"
   "             (loop 4)]\n"
   "        [(3) (void)]\n"
   "        [(4) (resume! (mesh 1) next-stack)]))))"))

(define runtime-slide-snippet
  (string-append
   "(define output-acc '())\n"
   "(define next-stack '())\n"
   "\n"
   "(define (checked-store-value sym val)\n"
   "  (if (array-var-name? sym)\n"
   "      val\n"
   "      (checked-scalar-store-value sym val)))\n"
   "\n"
   "(define (read-number-input!)\n"
   "  (define line (read-line))\n"
   "  (when (eof-object? line)\n"
   "    (runtime-fail (ick-err \"E562\")))\n"
   "  (string->number\n"
   "   (string-join\n"
   "    (map number->string\n"
   "         (map arabic->number\n"
   "              (string-split line)))\n"
   "    \"\")))\n"
   "\n"
   "(define (get-actual-next executed-lbl natural-next-ln)\n"
   "  (define hijackers\n"
   "    (if (eq? executed-lbl '_)\n"
   "        '()\n"
   "        (case executed-lbl ...)))\n"
   "  (define active\n"
   "    (filter (lambda (h-ln)\n"
   "              (zero? (abstain-count h-ln)))\n"
   "            hijackers))\n"
   "  (if (null? active)\n"
   "      natural-next-ln\n"
   "      (list-ref active (random (length active)))))"))

(define runtime-example-source
  (string-append
   "DO .1 <- #1\n"
   "DO READ OUT .1\n"
   "PLEASE GIVE UP\n"))

(define (pretty->string v)
  (with-output-to-string
    (lambda ()
      (pretty-write v))))

(define (presentation-module-path v)
  (match v
    [`(module ,name ,_ ,body ...)
     `(module ,name ,presentation-language-module-path ,@body)]
    [_ v]))

(define (line-numbered str)
  (string-trim str "\n" #:repeat? #t))

(define (token->datum tok)
  (list (token-struct-type tok)
        (token-struct-val tok)))

(define (file-excerpt path start end)
  (define lines
    (file->lines path))
  (string-join
   (take (drop lines (sub1 start))
         (add1 (- end start)))
   "\n"))

(define (file-excerpt-plain path start end)
  (define lines
    (file->lines path))
  (string-join
   (take (drop lines (sub1 start))
         (add1 (- end start)))
   "\n"))

(define (first-matching-window text pattern before after)
  (define lines (string-split text "\n" #:trim? #f))
  (define idx
    (for/first ([line (in-list lines)]
                [n (in-naturals 0)]
                #:when (regexp-match? pattern line))
      n))
  (unless idx
    (error 'first-matching-window
           "could not find pattern ~a"
           pattern))
  (define start (max 0 (- idx before)))
  (define stop (min (length lines) (+ idx after 1)))
  (string-join
   (take (drop lines start) (- stop start))
   "\n"))

(define (write-code-block! path content)
  (call-with-output-file path
    (lambda (out)
      (fprintf out "\\begin{CodeBlock}\n~a\n\\end{CodeBlock}\n" content))
    #:exists 'truncate/replace))

(define (generate!)
  (make-directory* snippets-dir)

  (define parsed
    (parse (tokenize (open-input-string sample-source))))
  (define cleaned-source
    (clean-intercal-source sample-raw-source))
  (define sample-line
    (first (string-split cleaned-source "\n")))
  (define sample-line-source
    (string-append sample-line "\n"))
  (define sample-line-tokens
    (map token->datum
         (tokenize (open-input-string sample-line-source))))
  (define sample-line-parse
    (cadr
     (syntax->datum
      (parse (tokenize (open-input-string sample-line-source))))))
  (define normalized
    (normalize-program (syntax->datum parsed)))
  (define macro-core-input
    (syntax->datum
     (expand-once
      (datum->syntax #'sick-program
                     `(sick-program ,@(cdr normalized))))))
  (define read-module
    (parameterize ([current-intercal-language-module-path
                    asset-language-module-path])
      (syntax->datum
       (intercal-read-syntax sample-source-path
                             (open-input-string sample-source)))))
  (define expanded-module
    (parameterize ([current-intercal-language-module-path
                    asset-language-module-path])
      (syntax->datum
       (expand
        (intercal-read-syntax sample-source-path
                              (open-input-string sample-source))))))
  (define runtime-example-values #f)
  (define runtime-example-stdout
    (with-output-to-string
      (lambda ()
        (set! runtime-example-values
              (call-with-values
               (lambda ()
                 (sick-program
                  (do (assign |.1| (mesh 1)))
                  (do (read-out |.1|))
                  (please (give-up))))
               list)))))
  (define runtime-example-result
    (format "stdout:\n~a\n\nREAD OUT values:\n~s"
            (string-trim runtime-example-stdout "\n" #:repeat? #t)
            runtime-example-values))

  (write-code-block!
   (build-path snippets-dir "sample-source.tex")
   (line-numbered sample-source))

  (write-code-block!
   (build-path snippets-dir "sample-raw-source.tex")
   (line-numbered sample-raw-source))

  (write-code-block!
   (build-path snippets-dir "sample-cleaned-source.tex")
   (line-numbered cleaned-source))

  (write-code-block!
   (build-path snippets-dir "sample-line-source.tex")
   sample-line)

  (write-code-block!
   (build-path snippets-dir "sample-line-tokens.tex")
   (pretty->string sample-line-tokens))

  (write-code-block!
   (build-path snippets-dir "sample-line-parse.tex")
   (pretty->string sample-line-parse))

  (write-code-block!
   (build-path snippets-dir "sample-parse.tex")
   (pretty->string (syntax->datum parsed)))

  (write-code-block!
   (build-path snippets-dir "sample-normalized.tex")
   (pretty->string normalized))

  (write-code-block!
   (build-path snippets-dir "sample-module.tex")
   (pretty->string (presentation-module-path read-module)))

  (write-code-block!
   (build-path snippets-dir "sample-macro-input.tex")
   (pretty->string macro-core-input))

  (write-code-block!
   (build-path snippets-dir "sample-state-machine-shape.tex")
   state-machine-shape)

  (write-code-block!
   (build-path snippets-dir "runtime-snippet.tex")
   runtime-slide-snippet)

  (write-code-block!
   (build-path snippets-dir "sample-runtime-source.tex")
   (line-numbered runtime-example-source))

  (write-code-block!
   (build-path snippets-dir "sample-runtime-result.tex")
   runtime-example-result)

  (write-code-block!
   (build-path snippets-dir "reader-snippet.tex")
   (file-excerpt (build-path repo-dir "intercal.rkt") 15 35))

  (write-code-block!
   (build-path snippets-dir "cleaner-snippet.tex")
   (string-append
    "(define (intercal-cleanable-line? line)\n"
    "  (or (regexp-match? intercal-valid-start-rx line)\n"
    "      (regexp-match? intercal-prefix-start-rx line)\n"
    "      (regexp-match? intercal-continuation-rx line)))\n"
    "\n"
    "(define (merge-intercal-continuations str)\n"
    "  (define lines (string-split str \"\\n\"))\n"
    "  (define logical-lines '())\n"
    "  (define current #f)\n"
    "  (define (flush-current!)\n"
    "    (when current\n"
    "      (set! logical-lines (cons current logical-lines))\n"
    "      (set! current #f)))\n"
    "  (for ([line (in-list lines)])\n"
    "    (cond\n"
    "      [(or (regexp-match? intercal-valid-start-rx line)\n"
    "           (regexp-match? intercal-prefix-start-rx line))\n"
    "       (flush-current!)\n"
    "       (set! current line)]\n"
    "      [(regexp-match? intercal-continuation-rx line)\n"
    "       (when current\n"
    "         (define trimmed (string-trim line))\n"
    "         (set! current (string-append current \" \" trimmed)))]\n"
    "      [else\n"
    "       (flush-current!)]))\n"
    "  (flush-current!)\n"
    "  (reverse logical-lines))"))

  (write-code-block!
   (build-path snippets-dir "lexer-snippet.tex")
   (string-append
    "(define (tokenize in)\n"
    "  (define str (port->string in))\n"
    "  (define clean-str\n"
    "    (string-replace\n"
    "     (string-replace str \"!\" \"'.\")\n"
    "     \"DON'T\" \"DO NOT\"))\n"
    "  (define words\n"
    "    (expand-packed-subscripts\n"
    "     (regexp-match* TOKEN-RX clean-str)))\n"
    "  (for/list ([w words])\n"
    "    (cond\n"
    "      [(regexp-match #px\"^[0-9]+$\" w) (token 'NUMBER (string->number w))]\n"
    "      [(equal? w \"<-\") (token 'GETS w)]\n"
    "      [(equal? w \"SUB\") (token 'SUB w)]\n"
    "      [else (token (string->symbol w) w)])))"))

  (write-code-block!
   (build-path snippets-dir "grammar-snippet.tex")
   (string-append
    "program : line+\n"
    "\n"
    "line : label? stmt\n"
    "     | label\n"
    "\n"
    "label : LPAREN NUMBER RPAREN\n"
    "\n"
    "stmt : do-prefix* op do-postfix*\n"
    "\n"
    "op : assign\n"
    "   | next\n"
    "   | comefrom\n"
    "   | readout\n"
    "\n"
    "assign : var GETS expr\n"
    "next : target NEXT\n"
    "comefrom : COME FROM target"))

  (write-code-block!
   (build-path snippets-dir "normalizer-plain-snippet.tex")
   normalizer-slide-snippet)

  (write-code-block!
   (build-path snippets-dir "macro-snippet.tex")
   macro-slide-snippet)

  (write-code-block!
   (build-path snippets-dir "hello-snippet.tex")
   (file-excerpt (build-path repo-dir "pit" "hello.i") 1 15)))

(module+ main
  (generate!))
