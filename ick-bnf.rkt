#lang brag

program : line+

line : label? stmt
     | label

label : LPAREN NUMBER RPAREN

do-prefix : PLEASE
          | DO
          | NOT
          | MAYBE
          | PERCENT NUMBER

do-postfix : ONCE
           | AGAIN

stmt : do-prefix* op do-postfix*

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

gerund : CALCULATING
       | FORGETTING
       | RESUMING
       | STASHING
       | RETRIEVING
       | IGNORING
       | REMEMBERING
       | ABSTAINING
       | REINSTATING
       | NEXTING
       | READING OUT
       | WRITING IN
       | TRYING AGAIN

gerund-list : gerund
            | gerund-list PLUS gerund

assign : var GETS expr
       | var GETS dim-list

dim-list : expr BY expr
         | dim-list BY expr

ignore : IGNORE var

remember : REMEMBER var

target : NUMBER
       | LPAREN NUMBER RPAREN
       | MESH NUMBER 

next : target NEXT
comefrom : COME FROM target

readout : READ OUT expr
giveup : GIVE UP
tryagain : TRY AGAIN

abstain-target : target
               | gerund-list

writein : WRITE IN var
stash : STASH expr-list
retrieve : RETRIEVE expr-list
forget : FORGET expr
resume : RESUME expr

abstain : ABSTAIN FROM abstain-target
        | ABSTAIN expr FROM abstain-target
reinstate : REINSTATE abstain-target
nothing : NOTHING

ident : NUMBER | ID

var : DOT ident
    | STAR ident
    | COLON ident
    | SEMICOLON ident
    | COMMA ident
    | var SUB sublist

sublist : expr
        | sublist expr

expr-list : expr
          | expr-list PLUS expr

expr : mingle

mingle
  : select
  | mingle MINGLE select

select
  : unary
  | select SELECT unary

unary
  : UNARY_AND unary
  | UNARY_OR unary
  | UNARY_XOR unary
  | postfix

postfix
  : primary
  | postfix SUB sublist

primary
  : var
  | NUMBER
  | MESH NUMBER
  | SQUOTE expr SQUOTE
  | DQUOTE expr DQUOTE
