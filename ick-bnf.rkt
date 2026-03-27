#lang brag

program : line+

line : label? stmt

label : LPAREN NUMBER RPAREN

do-prefix : PLEASE
          | DO
          | NOT
          | MAYBE

do-postfix : ONCE
           | AGAIN

stmt : do-prefix* op do-postfix*

op : assign
   | next
   | comefrom
   | readout
   | giveup
   | writein
   | stash
   | retrieve
   | forget
   | resume
   | abstain
   | reinstate
   | nothing

assign : var GETS expr

target : NUMBER
       | LPAREN NUMBER RPAREN
       | MESH NUMBER 

next : target NEXT
comefrom : COME FROM target

readout : READ OUT expr
giveup : GIVE UP

abstain-target : target

writein : WRITE IN var
stash : STASH expr
retrieve : RETRIEVE expr
forget : FORGET expr
resume : RESUME expr

abstain : ABSTAIN FROM abstain-target
reinstate : REINSTATE abstain-target
nothing : NOTHING

ident : NUMBER | ID

var : DOT ident
    | COLON ident
    | COMMA ident
    | var SUB expr

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
  | postfix SUB expr

primary
  : var
  | NUMBER
  | MESH NUMBER
