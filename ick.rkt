#lang brag

program : line+

line : label stmt

label : NUMBER

stmt : polite? op

polite : "DO"
       | "PLEASE"
       | "PLEASE" "DO"

op : assign
   | next
   | comefrom
   | readout
   | giveup

assign : "ASSIGN" var expr
next : "NEXT" NUMBER
comefrom : "COME" "FROM" NUMBER
readout : "READ" "OUT" var
giveup : "GIVE" "UP"

var : VAR

expr : var
     | NUMBER
