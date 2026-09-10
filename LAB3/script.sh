#!/bin/bash

yacc -d -y --debug --verbose 22201563_22299135.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 22201563_22299135.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -o a.exe
echo All ready, running
./a.exe input1.c
echo 'logfile'
type 22201563_22299135_log.txt
echo 'errorfile'
type 22201563_22299135_error.txt
