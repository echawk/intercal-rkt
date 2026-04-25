#lang racket

(require racket/cmdline
         racket/file
         racket/list
         racket/runtime-path
         racket/system
         "../subprocess-utils.rkt")

(define (run-profiler-program repeat-count stdin-path max-steps progress-every emit-program-output? program-path)
  (unless (and (exact-integer? repeat-count) (positive? repeat-count))
    (error "--repeat must be a positive integer"))

  (define racket-exe
    (current-racket-executable))

  (define stdin-bytes
    (and stdin-path
         (file->bytes stdin-path)))

  (define (make-run-env)
    (define env
      (environment-variables-copy
       (current-environment-variables)))
    (when max-steps
      (environment-variables-set! env #"SICK_MAX_STEPS" (string->bytes/utf-8 max-steps)))
    (when progress-every
      (environment-variables-set! env #"SICK_PROGRESS_EVERY" (string->bytes/utf-8 progress-every)))
    env)

  (define (profile-once)
    (define env (make-run-env))
    (define start-ms (current-inexact-monotonic-milliseconds))
    (define-values (proc out in err)
      (parameterize ([current-environment-variables env])
        (subprocess #f #f #f racket-exe program-path)))
    (when stdin-bytes
      (write-bytes stdin-bytes in))
    (close-output-port in)
    (define stdout (port->bytes out))
    (define stderr (port->bytes err))
    (close-input-port out)
    (close-input-port err)
    (subprocess-wait proc)
    (define elapsed-ms (- (current-inexact-monotonic-milliseconds) start-ms))
    (values (subprocess-status proc) elapsed-ms stdout stderr))

  (define runs
    (for/list ([i (in-range repeat-count)])
      (define-values (status elapsed-ms stdout stderr)
        (profile-once))
      (when emit-program-output?
        (printf "stdout(run ~a):\n~a" (add1 i) (bytes->string/utf-8 stdout #\?))
        (printf "stderr(run ~a):\n~a" (add1 i) (bytes->string/utf-8 stderr #\?)))
      (printf "run=~a status=~a elapsed-ms=~a stdout-bytes=~a stderr-bytes=~a\n"
              (add1 i)
              status
              (real->decimal-string elapsed-ms 3)
              (bytes-length stdout)
              (bytes-length stderr))
      (list status elapsed-ms stdout stderr)))

  (define elapsed-values
    (map second runs))

  (define mean-elapsed
    (/ (apply + elapsed-values) (length elapsed-values)))

  (define sorted-elapsed
    (sort elapsed-values <))

  (define median-elapsed
    (list-ref sorted-elapsed (quotient (length sorted-elapsed) 2)))

  (define statuses
    (remove-duplicates (map first runs)))

  (printf "summary runs=~a statuses=~s mean-elapsed-ms=~a median-elapsed-ms=~a min-elapsed-ms=~a max-elapsed-ms=~a\n"
          repeat-count
          statuses
          (real->decimal-string mean-elapsed 3)
          (real->decimal-string median-elapsed 3)
          (real->decimal-string (apply min elapsed-values) 3)
          (real->decimal-string (apply max elapsed-values) 3))

  (unless (andmap zero? (map first runs))
    (exit 1)))

(module+ main
  (define repeat-count 1)
  (define stdin-path #f)
  (define max-steps #f)
  (define progress-every #f)
  (define emit-program-output? #f)

  (define program-path
    (command-line
     #:program "profile-intercal.rkt"
     #:once-each
     [("--repeat") n "Run the program N times"
                    (set! repeat-count (string->number n))]
     [("--stdin") path "Read stdin for the program from PATH"
                       (set! stdin-path path)]
     [("--max-steps") n "Set SICK_MAX_STEPS for the profiled run"
                        (set! max-steps n)]
     [("--progress-every") n "Set SICK_PROGRESS_EVERY for the profiled run"
                            (set! progress-every n)]
     [("--emit-program-output") "Print the program's stdout/stderr after each run"
                                 (set! emit-program-output? #t)]
     #:args (program)
     program))

  (run-profiler-program repeat-count
                        stdin-path
                        max-steps
                        progress-every
                        emit-program-output?
                        program-path))
