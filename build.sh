#!/bin/sh

ca65 --cpu 6502 -l main.lst main.asm
ld65 main.o -o main.prg -C main.cfg
