#lang racket

(require rackunit
         racket/file
         racket/system)

(define hello-world-unlambda
  "`r```````````.H.e.l.l.o. .w.o.r.l.di")

(define (run-unlambda-run source [stdin ""])
  (define temp-dir (make-temporary-file "unlambda-run-test~a" 'directory))
  (define source-path (build-path temp-dir "program.unl"))
  (dynamic-wind
    void
    (lambda ()
      (call-with-output-file source-path
        (lambda (out)
          (display source out))
        #:exists 'truncate)
      (define racket-exe
        (or (find-executable-path "racket")
            (error "Could not locate racket executable")))
      (define-values (proc child-out child-in child-err)
        (subprocess #f #f #f racket-exe "unlambda-run.rkt" (path->string source-path)))
      (display stdin child-in)
      (close-output-port child-in)
      (define stdout (port->string child-out))
      (define stderr (port->string child-err))
      (close-input-port child-out)
      (close-input-port child-err)
      (subprocess-wait proc)
      (values (subprocess-status proc) stdout stderr))
    (lambda ()
      (delete-directory/files temp-dir))))

(test-case "unlambda-run executes a file-backed hello world program"
  (define-values (status stdout stderr)
    (run-unlambda-run hello-world-unlambda))
  (check-equal? status 0)
  (check-equal? stdout "Hello world\n")
  (check-equal? stderr ""))

(test-case "INTERCAL modules export intercal-main without running at require time"
  (define intercal-main
    (parameterize ([current-output-port (open-output-string)])
      (dynamic-require "hello.i" 'intercal-main)))
  (check-pred procedure? intercal-main)
  (check-equal? (with-output-to-string intercal-main)
                "hello, world\n"))
