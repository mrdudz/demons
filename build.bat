@echo off
c:\cc65\bin\ca65.exe --cpu 6502 -l main.lst main.asm
c:\cc65\bin\ld65.exe main.o -o demons.prg -C main.cfg
