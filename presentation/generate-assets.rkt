#lang racket

(require racket/file
         racket/format
         racket/list
         racket/path
         racket/pretty
         racket/string
         (rename-in "../intercal.rkt"
                    [read-syntax intercal-read-syntax])
         "../ick-lexer.rkt"
         "../ick-bnf.rkt"
         "../ick-normalize.rkt")

(define script-file
  (or (find-system-path 'run-file)
      (build-path (current-directory) "presentation" "generate-assets.rkt")))

(define script-dir
  (simplify-path (path-only script-file)))

(define repo-dir
  (simplify-path (build-path script-dir "..")))

(define generated-dir
  (build-path script-dir "generated"))

(define sample-source
  (string-append
   "(10) DO .1 <- #1\n"
   "(20) PLEASE DO (40) NEXT\n"
   "(30) DO GIVE UP\n"
   "(40) DO RESUME #1\n"))

(define (pretty->string v)
  (with-output-to-string
    (lambda ()
      (pretty-write v))))

(define (line-numbered str)
  (string-join
   (for/list ([line (in-list (string-split (string-trim str "\n" #:repeat? #t) "\n" #:trim? #f))]
              [n (in-naturals 1)])
     (format "~a  ~a" (~a n #:min-width 2 #:align 'right) line))
   "\n"))

(define (file-excerpt path start end)
  (define lines
    (file->lines path))
  (string-join
   (for/list ([line (in-list (take (drop lines (sub1 start))
                                   (add1 (- end start))))]
              [n (in-range start (add1 end))])
     (format "~a  ~a" (~a n #:min-width 4 #:align 'right) line))
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
   (for/list ([line (in-list (take (drop lines start) (- stop start)))]
              [n (in-range (add1 start) (add1 stop))])
     (format "~a  ~a" (~a n #:min-width 4 #:align 'right) line))
   "\n"))

(define (write-code-block! path content)
  (call-with-output-file path
    (lambda (out)
      (fprintf out "\\begin{CodeBlock}\n~a\n\\end{CodeBlock}\n" content))
    #:exists 'truncate/replace))

(define (generate!)
  (make-directory* generated-dir)

  (define parsed
    (parse (tokenize (open-input-string sample-source))))
  (define normalized
    (normalize-program (syntax->datum parsed)))
  (define read-module
    (syntax->datum
     (intercal-read-syntax #f (open-input-string sample-source))))
  (define expanded-module
    (syntax->datum
     (expand
      (intercal-read-syntax #f (open-input-string sample-source)))))

  (write-code-block!
   (build-path generated-dir "sample-source.tex")
   (line-numbered sample-source))

  (write-code-block!
   (build-path generated-dir "sample-parse.tex")
   (pretty->string (syntax->datum parsed)))

  (write-code-block!
   (build-path generated-dir "sample-normalized.tex")
   (pretty->string normalized))

  (write-code-block!
   (build-path generated-dir "sample-module.tex")
   (pretty->string read-module))

  (write-code-block!
   (build-path generated-dir "sample-expanded.tex")
   (first-matching-window
    (pretty->string expanded-module)
    #rx"next-stack"
    2
    10))

  (write-code-block!
   (build-path generated-dir "reader-snippet.tex")
   (file-excerpt (build-path repo-dir "intercal.rkt") 15 35))

  (write-code-block!
   (build-path generated-dir "lexer-snippet.tex")
   (file-excerpt (build-path repo-dir "ick-lexer.rkt") 5 28))

  (write-code-block!
   (build-path generated-dir "normalizer-snippet.tex")
   (file-excerpt (build-path repo-dir "ick-normalize.rkt") 136 164))

  (write-code-block!
   (build-path generated-dir "macro-snippet.tex")
   (file-excerpt (build-path repo-dir "sick.rkt") 1282 1316))

  (write-code-block!
   (build-path generated-dir "optimizer-snippet.tex")
   (file-excerpt (build-path repo-dir "sick.rkt") 1141 1172))

  (write-code-block!
   (build-path generated-dir "hello-snippet.tex")
   (file-excerpt (build-path repo-dir "hello.i") 1 15)))

(module+ main
  (generate!))
