#lang scribble/manual

@(require scribble/example
          scribble/racket
          racket/runtime-path)

@(define-runtime-path repo-root "..")

@title{INTERCAL in Racket}
@author{Ethan Hawk and Eva Augur}

This documentation describes the @tt{intercal} language entrypoint exported by
the package.

This package implements a substantial subset of C-INTERCAL in Racket. The
frontend accepts INTERCAL source text, normalizes it to a strict S-expression
intermediate representation, and macro-expands that IR into explicit Racket
code that simulates INTERCAL state and control flow.

@table-of-contents[]

@section{Using the language}

There are two intended ways to use the implementation:

@itemlist[
 @item{Inside the repository, source files can use
       @tt{#lang reader "intercal.rkt"}.}
 @item{After the package is installed, source files can use
       @tt{#lang intercal}.}]

Typical usage is to run an INTERCAL file directly:

@verbatim|{
#lang intercal
DO .1 <- #1
DO READ OUT .1
PLEASE GIVE UP
}|

and then:

@verbatim|{
racket hello.i
}|

The repository also includes a number of sample and regression-tested programs,
including @filepath{fib.i}, @filepath{hanoi.i}, @filepath{hello.i},
@filepath{beer.i}, @filepath{life.i}, @filepath{rot13.i}, and
@filepath{unlambda.i}.

@section{What is implemented}

The current implementation covers the main language pipeline and a large amount
of INTERCAL semantics.

@subsection{Reader and frontend}

The frontend is split across four files:

@itemlist[
 @item{@filepath{intercal.rkt}: reader entrypoint that produces a Racket
       module and exports @racket[intercal-main].}
 @item{@filepath{ick-lexer.rkt}: tokenization and packed-@tt{SUB}
       preprocessing.}
 @item{@filepath{ick-bnf.rkt}: brag grammar for INTERCAL statements and
       expressions.}
 @item{@filepath{ick-normalize.rkt}: conversion from brag parse trees to the
       normalized S-expression representation used by the macro backend.}]

The reader also shares the cleaning logic in @filepath{sick.rkt} to:

@itemlist[
 @item{merge continuation lines,}
 @item{discard prose/commentary lines that are not parseable statements, and}
 @item{preserve upstream-style prefixes like @tt{DON'T} and wrapped
       expressions.}]

@subsection{Statements and modifiers}

The implementation supports:

@itemlist[
 @item{assignment, including @tt{BY}-dimensioned arrays,}
 @item{@tt{NEXT}, @tt{RESUME}, @tt{FORGET}, and @tt{COME FROM},}
 @item{@tt{READ OUT} and @tt{WRITE IN},}
 @item{@tt{STASH}, @tt{RETRIEVE}, @tt{IGNORE}, and @tt{REMEMBER},}
 @item{@tt{ABSTAIN} and @tt{REINSTATE}, including gerund lists,}
 @item{@tt{TRY AGAIN}, @tt{GIVE UP}, and @tt{NOTHING},}
 @item{prefix modifiers such as @tt{PLEASE}, @tt{DO}, @tt{NOT}, and
       chance execution, and}
 @item{postfix state modifiers @tt{ONCE} and @tt{AGAIN}.}]

Gerund-based abstention is implemented with counted abstention state, so
multiple layers of abstention compose properly and a later reinstate removes one
layer at a time.

@subsection{Expressions and data}

The expression language includes:

@itemlist[
 @item{onespot and twospot constants,}
 @item{onespot, twospot, tail, and hybrid variables,}
 @item{@tt{MINGLE}, @tt{SELECT}, and unary binary operators,}
 @item{quote-based grouping,}
 @item{packed and nested @tt{SUB} expressions, and}
 @item{multidimensional arrays with runtime bounds checking.}]

The runtime enforces onespot/twospot width limits and raises the appropriate
INTERCAL errors when a value does not fit.

@subsection{I/O}

Scalar I/O uses the standard numeric INTERCAL spelling and Roman numeral output.
Array I/O uses the C-INTERCAL tape encoding, which is necessary for real
programs such as @filepath{hello.i} and @filepath{unlambda.i}.

@subsection{Libraries}

The macro frontend loads @filepath{syslib.i} automatically and pulls in
additional libraries such as @filepath{floatlib.i} when label references require
them. Library inclusion is based on referenced labels, not on raw numeric
constants, to avoid spurious loads.

@section{What is missing or incomplete}

The implementation is substantial, but it is not feature-complete. Notable
gaps are:

@itemlist[
 @item{@tt{CREATE} is not implemented.}
 @item{Multithreading and backtracking extensions are not implemented.}
 @item{PIC-INTERCAL-specific features are not implemented.}
 @item{TriINTERCAL and operand-overloading extensions are not implemented.}
 @item{OIL optimizer idiom ingestion is not implemented.}
 @item{Not every upstream pit program runs correctly yet, so compatibility is
       broad rather than total.}]

The repository contains debug hooks in @filepath{sick.rkt} to help investigate
remaining semantic differences. These hooks include line breakpoints, watched
variables, recent-event backtraces, repeated-state breaks, and watched
subscripts/node dumps.

@section{Compilation pipeline}

The implementation strategy is to compile INTERCAL into ordinary Racket by macro
expansion. The pipeline has five stages.

@subsection{1. Cleaning and reading}

@filepath{intercal.rkt} reads the source file, applies the shared
@racket[clean-intercal-source] routine from @filepath{sick.rkt}, tokenizes the
cleaned source, parses it with brag, normalizes the parse tree, and emits a
Racket module whose body invokes the macro backend centered on
@racket[sick-program].

At this point the INTERCAL program is no longer opaque text. It is already a
structured Racket datum.

@subsection{2. Parse tree normalization}

@filepath{ick-normalize.rkt} converts the dense brag tree into a compact,
explicit IR. For example, a line such as:

@verbatim|{
(20) PLEASE DO (40) NEXT
}|

normalizes to a form shaped like:

@verbatim|{
(20 (please (next 40)))
}|

Normalization performs several important tasks:

@itemlist[
 @item{collapse redundant parse layers,}
 @item{map keywords to symbolic operation names,}
 @item{rewrite packed @tt{SUB} chains into explicit subscript lists,}
 @item{normalize modifiers like @tt{NOT}, @tt{ONCE}, and @tt{AGAIN}, and}
 @item{fix unary precedence so the macro backend sees a stable IR.}]

@subsection{3. Macro compilation}

The macros in @filepath{sick.rkt} consume the normalized program. The key
expansion step is @racket[sick-program-core], which:

@itemlist[
 @item{collects all program variables,}
 @item{builds maps from labels to runtime line numbers,}
 @item{derives which lines can be abstained, which variables can be ignored,
       and which labels can be hijacked by @tt{COME FROM},}
 @item{builds gerund-to-line maps for abstention and reinstatement, and}
 @item{generates one runtime dispatch clause per INTERCAL line.}]

The resulting Racket code is a state machine with explicit tables for abstain
state, ignore state, line labels, and the NEXT stack.

@subsection{4. Runtime support}

The runtime portion of @filepath{sick.rkt} implements:

@itemlist[
 @item{INTERCAL error reporting,}
 @item{array storage and bounds checking,}
 @item{bitwise operators and width-sensitive helpers,}
 @item{numeric and tape-style I/O,}
 @item{control-flow support for @tt{NEXT}, @tt{RESUME}, and @tt{COME FROM}, and}
 @item{debugging and tracing hooks.}]

Semantics that are awkward in a direct compiler, such as delayed
@tt{COME FROM} after a resumed @tt{NEXT} target, are encoded directly in these
runtime tables and helpers.

@subsection{5. Conservative optimization}

The implementation does some compile-time optimization before handing the result
to the normal Racket compiler. In particular, it removes:

@itemlist[
 @item{abstain checks for lines that provably cannot be abstained,}
 @item{ignore-table lookups for variables that are never ignored, and}
 @item{@tt{COME FROM} dispatch checks for labels that can never be hijacked.}]

It also uses optimized implementations of hot arithmetic operators instead of
list-based bit manipulation.

These optimizations are intentionally conservative: they only remove code when
the frontend can prove that a check is unnecessary.

@section{Testing}

The repository has two main Racket test files:

@itemlist[
 @item{@filepath{ick-tests.rkt} checks the lexer, grammar, and normalizer.}
 @item{@filepath{sick-test.rkt} checks runtime semantics and macro-generated
       behavior.}]

The CI workflow also compares the output of several complete programs against
C-INTERCAL's @tt{ick}.

@section{Packaging for @tt{#lang intercal}}

Supporting @tt{#lang intercal} requires a collection-based language entrypoint.
This repository now includes @filepath{intercal/lang/reader.rkt}, which allows
the installed package to expose the reader under the standard
@tt{intercal/lang/reader} module path.

For publication on the Racket package catalog, the practical checklist is:

@itemlist[
 @item{keep the package metadata in @filepath{info.rkt} up to date,}
 @item{publish the repository at a stable Git URL,}
 @item{list the package on the catalog at
       @hyperlink["https://pkgs.racket-lang.org/"]{pkgs.racket-lang.org},}
 @item{ensure the Scribble docs build cleanly, and}
 @item{test both local-repository use and installed @tt{#lang intercal} use.}]

Once installed, users should be able to write INTERCAL modules with:

@verbatim|{
#lang intercal
...INTERCAL program...
}|
