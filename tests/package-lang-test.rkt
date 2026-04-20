#lang racket

(require rackunit
         racket/file
         racket/runtime-path
         racket/string
         racket/system)

(define-runtime-path repo-dir "..")

(define collects-env
  (string-join
   (map path->string
        (cons repo-dir (current-library-collection-paths)))
   ":"))

(define (run-intercal-module source)
  (define temp-path
    (make-temporary-file "intercal-lang-test~a.rkt"))
  (dynamic-wind
    void
    (lambda ()
      (call-with-output-file temp-path
        (lambda (out)
          (display source out))
        #:exists 'truncate/replace)
      (define racket-exe
        (or (find-executable-path "racket")
            (error "Could not locate racket executable")))
      (define env
        (environment-variables-copy
         (current-environment-variables)))
      (environment-variables-set! env #"PLTCOLLECTS" (string->bytes/utf-8 collects-env))
      (define-values (proc out in err)
        (parameterize ([current-environment-variables env])
          (subprocess #f #f #f racket-exe (path->string temp-path))))
      (close-output-port in)
      (define stdout (port->string out))
      (define stderr (port->string err))
      (close-input-port out)
      (close-input-port err)
      (subprocess-wait proc)
      (values (subprocess-status proc) stdout stderr))
    (lambda ()
      (delete-file temp-path))))

(test-case "#lang intercal loads through the collection reader"
  (define-values (status stdout stderr)
    (run-intercal-module
     (string-append
      "#lang intercal\n"
      "DO .1 <- #1\n"
      "DO READ OUT .1\n"
      "PLEASE GIVE UP\n")))
  (check-equal? status 0
                (format "stdout: ~s stderr: ~s" stdout stderr))
  (check-equal? stdout "I\n")
  (check-equal? stderr ""))
