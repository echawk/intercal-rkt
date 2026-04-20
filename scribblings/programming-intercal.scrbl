#lang scribble/manual

@(require racket/runtime-path)

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

Its source is:

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

@subsection{Step 1: Assign roles to variables}

This program uses a small set of registers:

@itemlist[
 @item{@tt{.9} is the loop counter.}
 @item{@tt{.10} is the running triangular sum.}
 @item{@tt{.11} is the increment that gets added each iteration.}
 @item{@tt{.1}, @tt{.2}, and @tt{.3} are the syslib call registers.}]

This is a common pattern. Keep your long-lived state in higher-numbered
variables and reserve @tt{.1}/@tt{.2}/@tt{.3} for helper calls.

@subsection{Step 2: Build the body first}

The body at label @tt{(1)} does the useful work:

@itemlist[
 @item{copy the current sum and increment into @tt{.1} and @tt{.2},}
 @item{@tt{NEXT} to @tt{1009} to compute the addition,}
 @item{store the returned sum back into @tt{.10},}
 @item{print the new sum,}
 @item{increment @tt{.11} by one using the same addition helper.}]

For a Racket programmer, the clean mental model is:

@verbatim|{
sum := sum + increment
print(sum)
increment := increment + 1
}|

The difference is only representational. In INTERCAL, the updates are explicit
and syslib calls happen through the @tt{NEXT}/@tt{RESUME} mechanism instead of
direct function calls.

@subsection{Step 3: Encode the loop control separately}

The end of the file is the loop controller.

Label @tt{(4)} decrements the loop counter via syslib @tt{1010}, then uses the
usual fib-style termination test:

@itemlist[
 @item{compute the updated counter in @tt{.9},}
 @item{derive a @tt{RESUME} count in @tt{.1} via @tt{1020}, and}
 @item{@tt{RESUME} using that count to either continue the loop or fall out to
       the @tt{GIVE UP}.}]

The important design point is that the program body does not try to encode the
exit condition inline. The state update and the control decision are kept in
separate blocks. That is easier to reason about, and it matches the way many
real INTERCAL programs are written.

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
