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

There are two intended ways to use this implementation:

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
racket pit/hello.i
}|

The repository also includes a number of sample and regression-tested programs,
including @filepath{pit/fib.i}, @filepath{pit/hanoi.i}, @filepath{pit/hello.i},
@filepath{pit/beer.i}, @filepath{pit/life.i}, @filepath{pit/rot13.i},
@filepath{pit/triangular.i}, and @filepath{pit/unlambda.i}.

For a worked example aimed at writing new programs, see
@filepath{scribblings/programming-intercal.scrbl}.

@section{The INTERCAL Model}

This implementation is easiest to understand if you treat an INTERCAL program
as a labeled state machine over mutable variables.

Each source line has:

@itemlist[
 @item{an optional numeric label such as @tt{(100)}.}
 @item{a core operation such as assignment, @tt{NEXT}, or @tt{READ OUT}.}
 @item{optional modifiers such as @tt{PLEASE}, @tt{NOT}, @tt{ONCE}, or
       a chance prefix like @tt{%50}.}]

Execution starts at the first runtime line and normally falls through to the
next runtime line. Labels are entry points for control flow, not separate
blocks in the Racket sense.

@subsection{Data model}

The frontend accepts the standard INTERCAL variable classes:

@itemlist[
 @item{@tt{.name}: onespot scalar values.}
 @item{@tt{:name}: twospot scalar values.}
 @item{@tt{,name}: onespot arrays.}
 @item{@tt{;name}: twospot arrays.}
 @item{@tt{*name}: frontend-supported array identifiers that are treated as
       onespot-valued by the runtime.}]

Unlike Racket's arbitrary-precision integers, INTERCAL values are fixed-width machine integers. 
The runtime enforces the following bounds:

@itemlist[
 @item{Onespot (@tt{.}) targets: unsigned 16-bit (@tt{0..65535}).}
 @item{Twospot (@tt{:}) targets: unsigned 32-bit (@tt{0..4294967295}).}
 @item{Overflow Protection: Storing a twospot-sized value into a onespot target will not truncate or "wrap around"; 
      it triggers a runtime INTERCAL error.}]

Arrays are dimensioned with @tt{BY} and indexed with @tt{SUB}. A declaration
such as

@verbatim|{
DO ,1 <- #10 BY #20
}|

creates a two-dimensional array, and a use such as

@verbatim|{
DO ,1 SUB #3 SUB #4 <- #99
}|

stores into a particular cell.

@subsection{Expressions}

The supported expression language is intentionally small:

@itemlist[
 @item{integer literals like @tt{5}.}
 @item{mesh literals like @tt{#5}.}
 @item{variables and subscripted array references.}
 @item{@tt{$} for @italic{MINGLE}.}
 @item{@tt{~} for @italic{SELECT}.}
 @item{unary @tt{&}, @tt{V}, and @tt{?}.}
 @item{single-quote and double-quote grouping.}]

The important semantic point is that these are bit-structured operations, not
ordinary arithmetic operators:

@itemlist[
 @item{@tt{a $ b} interleaves the bits of @tt{a} and @tt{b}.}
 @item{@tt{a ~ b} selects the bits of @tt{a} at positions where @tt{b} has
       ones, then packs them together.}
 @item{@tt{&}, @tt{V}, and @tt{?} combine a value with a one-bit rotation of
       itself.}]

That is why this implementation routes ordinary arithmetic through
@filepath{syslib.i} rather than trying to express everything directly.

@subsection{Control flow}

The control-flow model is the heart of INTERCAL. The core operations are
@tt{NEXT}, @tt{RESUME}, @tt{FORGET}, @tt{COME FROM}, @tt{TRY AGAIN}, and
@tt{GIVE UP}.

@subsubsection{NEXT and RESUME}

@tt{NEXT} acts like a subroutine call. Executing

@verbatim|{
DO (200) NEXT
}|

pushes the following runtime line onto the NEXT stack and transfers control to
label @tt{(200)}.

@tt{RESUME} unwinds that stack. A statement such as

@verbatim|{
DO RESUME #2
}|

removes two saved continuations and jumps to the last one removed.

The important edge cases are:

@itemlist[
 @item{@tt{RESUME #1} returns to the most recent @tt{NEXT} continuation.}
 @item{@tt{RESUME #2} skips one saved continuation and returns to the next one
       below it.}
 @item{@tt{RESUME #0} is an error.}
 @item{Resuming past the end of the NEXT stack raises the standard stack
       rupture error.}]

This implementation has explicit regression tests for these cases in
@filepath{tests/sick-test.rkt}.

@subsubsection{FORGET}

@tt{FORGET} discards continuations without transferring control. For example,

@verbatim|{
DO FORGET #1
}|

removes one saved NEXT entry. This implementation follows C-INTERCAL here:
forgetting more entries than are currently present saturates instead of raising
 an error.

@subsubsection{COME FROM}

@tt{COME FROM} is the inverse of a goto-like jump. A line such as

@verbatim|{
(500) DO COME FROM (100)
}|

registers line @tt{(500)} as a hijacker for transfers that reach label
@tt{(100)}. Operationally:

@itemlist[
 @item{the target line still executes.}
 @item{after the target line completes, control may be redirected to the matching
       @tt{COME FROM} line.}
 @item{the runtime keeps explicit label-to-hijacker tables to implement this.}]

In the presence of @tt{NEXT}, the timing matters. This implementation models
the delayed behavior needed by real programs: a @tt{COME FROM} attached to a
saved @tt{NEXT} entry does not fire until that entry is actually resumed.

@subsubsection{TRY AGAIN and GIVE UP}

@tt{GIVE UP} terminates the program. @tt{TRY AGAIN} restarts execution from the
first runtime line. In practice, @tt{TRY AGAIN} is usually used as an explicit
loop reset and @tt{GIVE UP} is the normal program exit.

@subsection{Statement state and self-modification}

Unlike Racket’s static execution, INTERCAL permits dynamic, line-level toggling of statement activity. 
This implementation supports that behavior by generating explicit runtime lookup tables—rather than 
straight-line Racket code—to verify a statement's status immediately before execution. This centralized 
state tracking is essential for handling modifiers that disable or enable logic (@tt{ABSTAIN}, @tt{NOT}, @tt{REINSTATE}, @tt{DON’T}), 
limit execution frequency (@tt{ONCE}, @tt{AGAIN}), or manipulate variable accessibility 
and history (@tt{IGNORE}, @tt{REMEMBER}, @tt{STASH}, @tt{RETRIEVE}).

@subsubsection{ABSTAIN and REINSTATE}

@tt{ABSTAIN} disables statements; @tt{REINSTATE} re-enables them.

This implementation supports both styles:

@itemlist[
 @item{Targeting a particular labeled line, as in
       @tt{DO ABSTAIN FROM (100)}}
 @item{Targeting gerunds, as in
       @tt{DO ABSTAIN FROM STASHING + RETRIEVING}.}]

The runtime represents abstention with counts, not booleans. That matters
because:

@itemlist[
 @item{multiple abstentions compose abstaining twice increments the count twice.}
 @item{the line stays inactive while the count is positive.}
 @item{each reinstatement removes one layer.}]

@subsubsection{NOT, DON'T, ONCE, and AGAIN}

The parser accepts both @tt{NOT} and upstream-style @tt{DON'T}. The lexer
normalizes @tt{DON'T} to @tt{DO NOT}, and the runtime interprets that prefix as
an initial abstention state for the line.

Postfix @tt{ONCE} and @tt{AGAIN} are local state modifiers on that line:

@itemlist[
 @item{@tt{ONCE} updates the line's abstention state after it is encountered
       once}
 @item{@tt{AGAIN} updates that local state on later encounters.}
 @item{This implementation tracks this with per-line state tables, not with
       source rewriting.}]

The short version is that these modifiers make a line stateful. A line can
change whether it will run the next time control reaches it.

@subsubsection{IGNORE and REMEMBER}

@tt{IGNORE} and @tt{REMEMBER} control whether assignments to a variable take
effect.

@itemlist[
 @item{If a variable is ignored, writes to it are suppressed.}
 @item{@tt{REMEMBER} restores normal write behavior.}
 @item{The compiler only emits ignore-table checks for variables that can
       actually be ignored, which is one of the conservative optimizations in
       @filepath{sick.rkt}.}]

@subsubsection{STASH and RETRIEVE}

@tt{STASH} saves variable values on per-variable stacks, and @tt{RETRIEVE}
restores them. For subscripted array expressions, this implementation stashes
the array object rather than a single indexed element, which matches the way
INTERCAL uses these commands operationally.

@subsection{Runtime I/O support}

This implementation supports both standard numeric INTERCAL I/O and the tape
style used by C-INTERCAL string-oriented programs.

@itemlist[
 @item{Scalar @tt{WRITE IN} reads spelled numbers such as @tt{ONE TWO THREE}
       and accepts @tt{OH} for zero.}
 @item{Scalar @tt{READ OUT} writes Roman numerals.}
 @item{Array @tt{WRITE IN} and @tt{READ OUT} use the C-INTERCAL tape encoding,
       which is required for programs such as @filepath{pit/hello.i} and
       @filepath{pit/unlambda.i}.}]

For a Racket programmer, the practical implication is simple: strings are not
primitive values in INTERCAL. Real text I/O is done through arrays and the tape
encoding.

@section{Concrete Grammar}

The parser in @filepath{ick-bnf.rkt} is a brag grammar. The exact file is the
most authoritative source, but the following excerpt captures the language
accepted by the frontend after line cleaning and packed-@tt{SUB}
preprocessing:

@verbatim|{
program : line+

line : label? stmt
     | label

label : LPAREN NUMBER RPAREN

stmt : do-prefix* op do-postfix*

do-prefix : PLEASE
          | DO
          | NOT
          | MAYBE
          | PERCENT NUMBER

do-postfix : ONCE
           | AGAIN

op : assign
   | next
   | comefrom
   | readout
   | giveup
   | tryagain
   | writein
   | stash
   | retrieve
   | ignore
   | remember
   | forget
   | resume
   | abstain
   | reinstate
   | nothing

assign : var GETS expr
       | var GETS dim-list

next : target NEXT
comefrom : COME FROM target
readout : READ OUT expr
writein : WRITE IN var
forget : FORGET expr
resume : RESUME expr
giveup : GIVE UP
tryagain : TRY AGAIN

abstain : ABSTAIN FROM abstain-target
        | ABSTAIN expr FROM abstain-target
reinstate : REINSTATE abstain-target

var : DOT ident
    | STAR ident
    | COLON ident
    | SEMICOLON ident
    | COMMA ident
    | var SUB sublist

expr : mingle
mingle : select
       | mingle MINGLE select
select : unary
       | select SELECT unary
unary : UNARY_AND unary
      | UNARY_OR unary
      | UNARY_XOR unary
      | postfix
postfix : primary
        | postfix SUB sublist
primary : var
        | NUMBER
        | MESH NUMBER
        | SQUOTE expr SQUOTE
        | DQUOTE expr DQUOTE
}|

Two practical notes:

@itemlist[
 @item{The cleaner merges continuation lines before this grammar runs.}
 @item{Packed subscript syntax from upstream programs is expanded before
       parsing, so the grammar sees explicit repeated @tt{SUB} structure.}]

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
 @item{merge continuation lines.}
 @item{discard prose/commentary lines that are not parseable statements.}
 @item{preserve upstream-style prefixes like @tt{DON'T} and wrapped
       expressions.}]

@subsection{Statements and modifiers}

This implementation supports:

@itemlist[
 @item{assignment, including @tt{BY}-dimensioned arrays.}
 @item{@tt{NEXT}, @tt{RESUME}, @tt{FORGET}, and @tt{COME FROM}.}
 @item{@tt{READ OUT} and @tt{WRITE IN}.}
 @item{@tt{STASH}, @tt{RETRIEVE}, @tt{IGNORE}, and @tt{REMEMBER}.}
 @item{@tt{ABSTAIN} and @tt{REINSTATE}, including gerund lists.}
 @item{@tt{TRY AGAIN}, @tt{GIVE UP}, and @tt{NOTHING}.}
 @item{prefix modifiers such as @tt{PLEASE}, @tt{DO}, @tt{NOT}, and
       chance execution.}
 @item{postfix state modifiers @tt{ONCE} and @tt{AGAIN}.}]

Gerund-based abstention is implemented with counted abstention state, so
multiple layers of abstention compose properly and a later reinstate removes one
layer at a time.

@subsection{Expressions and data}

The expression language includes:

@itemlist[
 @item{onespot and twospot constants.}
 @item{onespot, twospot, tail, and hybrid variables.}
 @item{@tt{MINGLE}, @tt{SELECT}, and unary binary operators.}
 @item{quote-based grouping.}
 @item{packed and nested @tt{SUB} expressions.}
 @item{multidimensional arrays with runtime bounds checking.}]

The runtime enforces onespot/twospot width limits and raises the appropriate
INTERCAL errors when a value does not fit.

@subsection{I/O}

Scalar I/O uses the standard numeric INTERCAL spelling and Roman numeral output.
Array I/O uses the C-INTERCAL tape encoding, which is necessary for real
programs such as @filepath{pit/hello.i} and @filepath{pit/unlambda.i}.

@subsection{Libraries}

The macro frontend loads @filepath{syslib.i} automatically and pulls in
additional libraries such as @filepath{pit/floatlib.i} when label references require
them. Library inclusion is based on referenced labels, not on raw numeric
constants, to avoid spurious loads.

@section{What is missing or incomplete}

This implementation is substantial, but it is not feature-complete. Notable
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

This implementation strategy is to compile INTERCAL into ordinary Racket by macro
expansion. The pipeline has five stages.

@subsection{Cleaning and reading}

@filepath{intercal.rkt} reads the source file, applies the shared
@racket[clean-intercal-source] routine from @filepath{sick.rkt}, tokenizes the
cleaned source, parses it with brag, normalizes the parse tree, and emits a
Racket module whose body invokes the macro backend centered on
@racket[sick-program].

At this point the INTERCAL program is no longer opaque text. It is already a
structured Racket datum.

@subsection{Parse tree normalization}

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
 @item{collapse redundant parse layers.}
 @item{map keywords to symbolic operation names.}
 @item{rewrite packed @tt{SUB} chains into explicit subscript lists.}
 @item{normalize modifiers like @tt{NOT}, @tt{ONCE}, and @tt{AGAIN}.}
 @item{fix unary precedence so the macro backend sees a stable IR.}]

@subsection{Macro compilation}

The macros in @filepath{sick.rkt} consume the normalized program. The key
expansion step is @racket[sick-program-core], which:

@itemlist[
 @item{collects all program variables.}
 @item{builds maps from labels to runtime line numbers.}
 @item{derives which lines can be abstained, which variables can be ignored,
       and which labels can be hijacked by @tt{COME FROM}.}
 @item{builds gerund-to-line maps for abstention and reinstatement.}
 @item{generates one runtime dispatch clause per INTERCAL line.}]

The resulting Racket code is a state machine with explicit tables for abstain
state, ignore state, line labels, and the NEXT stack.

@subsection{Runtime support}

The runtime portion of @filepath{sick.rkt} implements:

@itemlist[
 @item{INTERCAL error reporting.}
 @item{array storage and bounds checking.}
 @item{bitwise operators and width-sensitive helpers.}
 @item{numeric and tape-style I/O.}
 @item{control-flow support for @tt{NEXT}, @tt{RESUME}, and @tt{COME FROM}.}
 @item{debugging and tracing hooks.}]

Semantics that are awkward in a direct compiler, such as delayed
@tt{COME FROM} after a resumed @tt{NEXT} target, are encoded directly in these
runtime tables and helpers.

@subsection{Conservative optimization}

This implementation does some compile-time optimization before handing the result
to the normal Racket compiler. In particular, it removes:

@itemlist[
 @item{abstain checks for lines that provably cannot be abstained.}
 @item{ignore-table lookups for variables that are never ignored.}
 @item{@tt{COME FROM} dispatch checks for labels that can never be hijacked.}]

It also uses optimized implementations of hot arithmetic operators instead of
list-based bit manipulation.

These optimizations are intentionally conservative: they only remove code when
the frontend can prove that a check is unnecessary.

@section{Testing}

The repository has two main Racket test files:

@itemlist[
 @item{@filepath{tests/ick-tests.rkt} checks the lexer, grammar, and normalizer.}
 @item{@filepath{tests/sick-test.rkt} checks runtime semantics and macro-generated
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
 @item{keep the package metadata in @filepath{info.rkt} up to date.}
 @item{publish the repository at a stable Git URL.}
 @item{list the package on the catalog at
       @hyperlink["https://pkgs.racket-lang.org/"]{pkgs.racket-lang.org}.}
 @item{ensure the Scribble docs build cleanly.}
 @item{test both local-repository use and installed @tt{#lang intercal} use.}]

Once installed, users should be able to write INTERCAL modules with:

@verbatim|{
#lang intercal
...INTERCAL program...
}|
