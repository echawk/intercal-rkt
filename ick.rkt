#lang brag

program : line+

line : label stmt

label : NUMBER

stmt : polite? op

polite : DO
       | PLEASE DO
       | PLEASE

op : assign
   | next
   | comefrom
   | readout
   | giveup

assign : var GETS expr
next : NEXT NUMBER
comefrom : COME FROM NUMBER
readout : READ OUT expr
giveup : GIVE UP

ident : NUMBER
      | ID

var : DOT ident
    | COLON ident
    | STAR ident
    | var SUB expr

expr : UNARY_AND expr
     | UNARY_OR expr
     | UNARY_XOR expr
     | expr MINGLE expr
     | expr SELECT expr
     | var
     | NUMBER
     | MESH NUMBER
