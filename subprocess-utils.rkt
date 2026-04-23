#lang racket/base

(provide current-racket-executable
         current-shell-executable)

(require racket/system)

(define (normalize-executable candidate)
  (cond
    [(not candidate) #f]
    [(complete-path? candidate) candidate]
    [else (find-executable-path (path->string candidate))]))

(define (current-racket-executable)
  (or (normalize-executable (find-system-path 'exec-file))
      (normalize-executable (find-system-path 'run-file))
      (find-executable-path "racket")
      (error "Could not locate racket executable")))

(define (current-shell-executable)
  (or (find-executable-path "sh")
      (and (file-exists? "/bin/sh")
           (string->path "/bin/sh"))
      (error "Could not locate sh executable")))
