#lang racket

(require rackunit
         racket/runtime-path
         racket/system)
(require "../subprocess-utils.rkt")

(define-runtime-path profiler-path "../tools/profile-intercal.rkt")
(define-runtime-path triangular-i-path "../pit/triangular.i")

(test-case "profile-intercal module loads without running its CLI"
  (check-not-exn
   (lambda ()
     (dynamic-require profiler-path #f))))

(define (run-profiler . args)
  (define racket-exe
    (current-racket-executable))
  (define-values (proc out in err)
    (apply subprocess
           #f #f #f
           racket-exe
           (path->string profiler-path)
           (map path->string
                (for/list ([arg (in-list args)])
                  (if (path? arg) arg (string->path arg))))))
  (close-output-port in)
  (define stdout (port->string out))
  (define stderr (port->string err))
  (close-input-port out)
  (close-input-port err)
  (subprocess-wait proc)
  (values (subprocess-status proc) stdout stderr))

(test-case "profile-intercal reports elapsed time for a terminating program"
  (define-values (status stdout stderr)
    (run-profiler "--repeat" "1" triangular-i-path))
  (check-equal? status 0)
  (check-equal? stderr "")
  (check-true (regexp-match? #rx"run=1 status=0 elapsed-ms=" stdout))
  (check-true (regexp-match? #rx"summary runs=1 statuses=\\(0\\)" stdout)))
