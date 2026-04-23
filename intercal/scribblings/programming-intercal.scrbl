#lang scribble/manual

@(require scribble/racket
          racket/runtime-path)

@title{Designing INTERCAL Programs}
@author{Ethan Hawk and Eva Augur}

This guide is aimed at a Racket programmer who wants to write new programs for
this implementation instead of only reading existing ones.

@table-of-contents[]

@section{How to think about INTERCAL}

The most useful shift is to stop thinking in terms of recursive functions and
start thinking in terms of an explicit state machine.

An INTERCAL program in this repository is usually built from four pieces:

@itemlist[
 @item{mutable scalar variables such as @tt{.1} and @tt{:1},}
 @item{optional arrays such as @tt{,1} and @tt{;1},}
 @item{control-flow edges built from labels, @tt{NEXT}, and @tt{RESUME}, and}
 @item{calls into the standard library routines in @filepath{syslib.i}.}]

The compilation strategy in @filepath{sick.rkt} preserves this structure very
directly. The frontend normalizes the program into a compact S-expression IR,
and the macro backend expands that IR into a Racket state machine. That means
program structure matters: a clear label layout and disciplined use of
temporary variables make programs easier to debug and easier for the compiler
to optimize.

@section{A practical workflow}

When designing a new program, the following order works well.

@itemlist[#:style 'ordered
 @item{Choose the state you need.

       Decide which variables are long-lived and which are scratch registers.
       In practice, many programs use @tt{.1}, @tt{.2}, and @tt{.3} as call
       convention registers for syslib routines, and keep persistent state in
       higher-numbered variables such as @tt{.9}, @tt{.10}, and @tt{.11}.}
 @item{Choose the loop shape.

       Most non-trivial programs are arranged around a small label skeleton:
       a body label, a branch to a helper label, and a final @tt{RESUME} that
       decides whether to continue or exit. Existing working programs in
       @filepath{pit/} are useful templates for this.}
 @item{Use syslib for arithmetic.

       The implementation automatically loads @filepath{syslib.i}, so you do
       not need to inline arithmetic yourself. For example, many programs use
       label @tt{1009} as addition and @tt{1010} as subtraction with the
       convention that inputs are placed in @tt{.1} and @tt{.2}, and the result
       is returned in @tt{.3}.}
 @item{Add I/O last.

       Once the state transitions are correct, add @tt{READ OUT} or
       @tt{WRITE IN}. This keeps debugging focused on semantics instead of
       mixing in parsing and tape-format issues too early.}]

@section{Worked Example: Triangular Numbers}

The file @filepath{pit/triangular.i} is a small but non-trivial worked
example. It prints the first ten triangular numbers:

@verbatim|{
I
III
VI
X
XV
XXI
XXVIII
XXXVI
XLV
LV
}|

The point of this example is not merely to show a finished INTERCAL program.
The more useful lesson is how to translate a familiar Racket program into an
INTERCAL-shaped state machine.

@subsection{Start with an ordinary Racket function}

The direct Racket version is the sort of code most readers would naturally
write first:

@racketblock[
(define (triangular-list n)
  (let loop ([k n] [sum 0] [inc 1] [acc '()])
    (if (zero? k)
        (reverse acc)
        (define next-sum (+ sum inc))
        (loop (sub1 k)
              next-sum
              (add1 inc)
              (cons next-sum acc)))))
]

This is clear, but it hides the control flow inside function calls and local
bindings. INTERCAL does not encourage that style. It wants:

@itemlist[
 @item{named storage locations,}
 @item{explicit updates to those locations, and}
 @item{control flow that moves between labels.}]

So the first translation step is not “write INTERCAL syntax.” The first step is
“rewrite the Racket into an explicit state machine.”

@subsection{Rewrite the Racket into effectful stateful code}

The same computation can be written in a style that is much closer to
INTERCAL:

@racketblock[
(define (emit-triangular! n)
  (define count n)
  (define sum 0)
  (define inc 1)

  (let loop ()
    (unless (zero? count)
      (set! sum (+ sum inc))
      (displayln sum)
      (set! inc (+ inc 1))
      (set! count (- count 1))
      (loop))))
]

This version already exposes most of the structure that will appear in the
INTERCAL program:

@itemlist[
 @item{@racket[count], @racket[sum], and @racket[inc] are long-lived pieces of
       state.}
 @item{Each iteration performs a fixed sequence of updates.}
 @item{The loop condition is an explicit check that decides whether to jump
       back to the body.}]

Once you can write this version cleanly, the move to INTERCAL is mostly a
question of replacing Racket primitives with INTERCAL mechanisms.

@subsection{Separate helpers from the loop body}

There is one more Racket rewrite that makes the INTERCAL correspondence even
clearer: factor arithmetic into helper procedures. That mirrors the way
INTERCAL programs call into @filepath{syslib.i}.

@racketblock[
(define (add2 a b)
  (+ a b))

(define (sub1* a)
  (- a 1))

(define (emit-triangular!/helpers n)
  (define count n)
  (define sum 0)
  (define inc 1)

  (let loop ()
    (unless (zero? count)
      (set! sum (add2 sum inc))
      (displayln sum)
      (set! inc (add2 inc 1))
      (set! count (sub1* count))
      (loop))))
]

This matters because the INTERCAL translation will not inline addition or
subtraction directly. Instead, it will call standard library routines through
@tt{NEXT} and receive results through @tt{RESUME}.

@subsection{Map Racket variables to INTERCAL variables}

For @filepath{pit/triangular.i}, the long-lived state is mapped like this:

@itemlist[
 @item{@racket[count] becomes @tt{.9}.}
 @item{@racket[sum] becomes @tt{.10}.}
 @item{@racket[inc] becomes @tt{.11}.}
 @item{@tt{.1}, @tt{.2}, and @tt{.3} are scratch registers used by syslib
       helper calls.}]

That gives the initialization block:

@verbatim|{
DO .9 <- #10
DO .10 <- #0
DO .11 <- #1
}|

This is exactly the stateful Racket setup

@racketblock[
(define count 10)
(define sum 0)
(define inc 1)
]

just written in INTERCAL storage syntax.

@subsection{Translate helper calls to NEXT and RESUME}

This is the conceptual leap that matters most.

In Racket, a helper call such as

@racketblock[
(set! sum (add2 sum inc))
]

looks like a direct expression. In this INTERCAL implementation, the analogous
pattern is:

@verbatim|{
DO .1 <- .10
DO .2 <- .11
PLEASE (1009) NEXT
DO .10 <- .3
}|

The correspondence is:

@itemlist[
 @item{move the arguments into the helper calling convention registers
       @tt{.1} and @tt{.2},}
 @item{@tt{NEXT} to the helper label, here @tt{1009} for addition,}
 @item{let the helper compute and eventually @tt{RESUME}, and}
 @item{read the returned value from @tt{.3}.}]

For a Racket programmer, the clean mental model is:

@racketblock[
(define saved-k continuation-after-call)
(jump-to add-routine)
;; later, the add routine returns here with result in .3
]

That is what @tt{NEXT} and @tt{RESUME} are doing operationally. @tt{NEXT}
saves “where to come back to” on the NEXT stack and transfers control to the
target label. @tt{RESUME} pops one or more saved continuations and jumps back.

@subsection{Translate one loop iteration}

Now the body of one stateful Racket iteration:

@racketblock[
(set! sum (add2 sum inc))
(displayln sum)
(set! inc (add2 inc 1))
]

becomes the INTERCAL block at label @tt{(1)}:

@verbatim|{
(1) DO .1 <- .10
    DO .2 <- .11
    PLEASE (1009) NEXT
    DO .10 <- .3
    PLEASE READ OUT .10
    DO .1 <- .11
    DO .2 <- #1
    PLEASE (1009) NEXT
    DO .11 <- .3
}|

The structure is the same as the stateful Racket:

@itemlist[
 @item{compute the next sum,}
 @item{emit it,}
 @item{increment the step size.}]

The only added complexity is the helper-call protocol through @tt{.1},
@tt{.2}, @tt{.3}, @tt{NEXT}, and @tt{RESUME}.

@subsection{Translate the loop back-edge}

The stateful Racket loop ends with:

@racketblock[
(set! count (sub1* count))
(unless (zero? count)
  (loop))
]

In INTERCAL, that becomes a separate control block:

@verbatim|{
(4) DO .1 <- .9
    DO .2 <- #1
    PLEASE (1010) NEXT
    DO .9 <- .3
    DO .1 <- '.9~.9'~#1
    PLEASE (1020) NEXT
    DO RESUME .1
}|

There are two ideas here:

@itemlist[
 @item{Use syslib @tt{1010} to perform the decrement.}
 @item{Use syslib @tt{1020} to transform the resulting counter into a
       @tt{RESUME} count that either continues the loop or exits it.}]

This is the part that looks least like idiomatic Racket and most like real
INTERCAL. The important thing for a translator is not the exact bit trickery,
but the control-flow role:

@itemlist[
 @item{state update first,}
 @item{branch decision second,}
 @item{and the final choice expressed as a stack-sensitive @tt{RESUME}.}]

@subsection{Assemble the final program}

The complete source is:

@verbatim|{
#lang reader "../intercal.rkt"
    DO .9 <- #10
    DO .10 <- #0
    DO .11 <- #1

(1) DO .1 <- .10
    DO .2 <- .11
    PLEASE (1009) NEXT
    DO .10 <- .3
    PLEASE READ OUT .10
    DO .1 <- .11
    DO .2 <- #1
    PLEASE (1009) NEXT
    DO .11 <- .3

    DO (3) NEXT
    DO (1) NEXT

(3) DO (4) NEXT
    PLEASE GIVE UP

(4) DO .1 <- .9
    DO .2 <- #1
    PLEASE (1010) NEXT
    DO .9 <- .3
    DO .1 <- '.9~.9'~#1
    PLEASE (1020) NEXT
    DO RESUME .1
}|

@subsection{How the labels correspond to the Racket structure}

This program uses a small set of registers and labels:

@itemlist[
 @item{@tt{.9} is the loop counter.}
 @item{@tt{.10} is the running triangular sum.}
 @item{@tt{.11} is the increment that gets added each iteration.}
 @item{@tt{.1}, @tt{.2}, and @tt{.3} are the syslib call registers.}
 @item{Label @tt{(1)} is the loop body.}
 @item{Label @tt{(3)} is the exit trampoline.}
 @item{Label @tt{(4)} is the loop controller.}]

This is a common pattern. Keep your long-lived state in higher-numbered
variables and reserve @tt{.1}/@tt{.2}/@tt{.3} for helper calls.

@subsection{A translation recipe}

For a Racket programmer, the practical recipe is:

@itemlist[#:style 'ordered
 @item{Write the computation first in direct Racket.}
 @item{Rewrite it into explicit stateful Racket with mutable variables and a
       visible loop.}
 @item{Identify helper operations that should become syslib calls.}
 @item{Assign stable INTERCAL variables to the long-lived state.}
 @item{Translate each helper call into:

       argument moves, then @tt{NEXT}, then a read from the return register.}
 @item{Move loop-control decisions into their own labeled controller block.}
 @item{Add I/O only after the control flow is already correct.}]

That process is much more reliable than trying to translate directly from
high-level functional Racket to INTERCAL syntax in one pass.

@section{Debugging Advice}

When a new program does not behave correctly, use the runtime hooks in
@filepath{sick.rkt} instead of guessing.

Useful starting points are:

@itemlist[
 @item{@tt{SICK_DEBUG=1} to enable tracing,}
 @item{@tt{SICK_DEBUG_LINES=...} to restrict the trace to a few labels,}
 @item{@tt{SICK_BREAK_LINES=...} to stop before a line executes, and}
 @item{@tt{SICK_BREAK_REPEAT=N} to stop when the same control-flow state repeats.}]

For example, to focus on the loop controller in @filepath{pit/triangular.i}:

@verbatim|{
SICK_DEBUG=1 \
SICK_DEBUG_LINES=1,3,4 \
racket pit/triangular.i
}|

The same workflow scales to larger programs such as
@filepath{pit/sort.i} or @filepath{pit/unlambda.i}.

@section{How to grow from here}

Once you are comfortable with the worked example, the next useful programs to
study are:

@itemlist[
 @item{@filepath{pit/fib.i} for another arithmetic loop,}
 @item{@filepath{pit/rot13.i} for character-oriented transformation, and}
 @item{@filepath{pit/unlambda.i} for a large, real interpreter built on the
       same control-flow substrate.}]

The implementation is still conservative about optimization, so clean program
structure helps twice: it is easier to understand, and it gives the macro
compiler more opportunities to remove unnecessary runtime checks.
