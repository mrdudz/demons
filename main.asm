	;*****************************************************************
	; Demons of Dex
	; A roguelike for the unexpanded VIC-20
	; (C) 2015 Petri Hakkinen. All rights reserved.
	;*****************************************************************

	SCREEN 		= $1e00
	SCREEN_WIDTH	= 22
	SCREEN_HEIGHT	= 23

	.byt $01,$10			; PRG file header (starting address of the program)

	.org    $1001			; start of basic program

	;*****************************************************************
	; basic stub
	;*****************************************************************

	; stub basic program
	.word bend 			; next Line link
	.word 2015        		; line number
	.byt  $9e,32,52,49,49,48	; sys 4110
	.byt  0           		; end of line
bend:	.word 0           		; end of program

	;*****************************************************************
	; main program
	;*****************************************************************

start:	inc $900f
	jsr clearscreen
	jsr dumpchars
	jsr delay
	jmp start

	;*****************************************************************
	; clears the screen
	;*****************************************************************

clearscreen:
	; screen is 22*23 = 506 bytes long
	lda #32   		; space
	ldx #0
@loop:	sta SCREEN,x
	inx
	bne @loop
	; clear remaining 506-256 = 250 bytes
	ldx #250
@loop2:	dex
	sta SCREEN+$100,x
	bne @loop2
	rts

	;*****************************************************************
	; prints all chars to the screen
	;*****************************************************************

dumpchars:
	ldx #0
@loop:	sta SCREEN,x
	inx
	txa
	bne @loop
	rts

	;*****************************************************************
	; short delay in busy loop
	;*****************************************************************

delay:	ldy #$80
@delay1:ldx #$ff
@delay2:dex
	bne @delay2
	dey
	bne @delay1
	rts
