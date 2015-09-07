#!/bin/sh

ca65 --cpu 6502 -l main.lst main.asm
ca65 --cpu 6502 -l music.lst music.asm
ld65 main.o music.o -o demons.prg -C main.cfg
