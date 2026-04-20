#lang reader "../intercal.rkt"
PLEASE NOTE THIS TESTS 1D ARRAY ALLOCATION AND ACCESS
        DO ,1 <- #2
        DO ,1 SUB #1 <- #10
        PLEASE DO ,1 SUB #2 <- #20
        DO READ OUT ,1 SUB #1
        PLEASE DO READ OUT ,1 SUB #2
        PLEASE GIVE UP
