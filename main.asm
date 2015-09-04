	;*****************************************************************
	; Demons of Dex
	; A roguelike for the unexpanded VIC-20
	; (C) 2015 Petri Hakkinen. All rights reserved.
	;*****************************************************************

	SCREEN 		= $1e00
	SCREEN_WIDTH	= 22
	SCREEN_HEIGHT	= 23

	CHROUT		= $ffd2
	PLOT		= $fff0

	WHITE		= 5
	RED		= 28
	GREEN		= 30
	BLUE		= 31
	BLACK		= 144
	PURPLE		= 156
	YELLOW		= 158
	CYAN		= 159
	CURSOR_DOWN	= 17
	CURSOR_UP	= 145
	CURSOR_LEFT 	= 157
	CURSOR_RIGHT	= 29
	HOME		= 19
	CLEAR_SCREEN	= 147

	.byt $01,$10			; PRG file header (starting address of the program)

	.org    $1001			; start of basic program

	;*****************************************************************
	; basic stub
	;*****************************************************************

	; stub basic program
	.word bend 			; next Line link
	.word 2015        		; line number
	.byte $9e,52,49,48,57		; sys 4109
	.byte 0           		; end of line
bend:	.word 0           		; end of program

	;*****************************************************************
	; main program
	;*****************************************************************

start:	lda #CLEAR_SCREEN
        jsr CHROUT

        jsr rand8
        jsr CHROUT

	ldx #5
	ldy #2
	jsr move

        ldx #<text
        ldy #>text
        jsr print

	jsr delay

        jmp start
        ;rts

	;*****************************************************************
	; moves cursor to X,Y
	;*****************************************************************

move:	stx $0		; swap X and Y
	tya
	tax
	ldy $0
	clc
	jsr PLOT
	rts

	;*****************************************************************
	; prints text at cursor using kernal
	; X,Y = address of text
	;*****************************************************************

print:	stx $0
	sty $1
	ldy #0
@loop:	lda ($0),y
	beq @done
	jsr CHROUT
	iny
	jmp @loop
@done:	rts

	;*****************************************************************
	; clears the screen
	;*****************************************************************

clearscreen:
	; screen is 22*23 = 506 bytes long
	; to save bytes we clear two full pages (512 bytes)
	lda #32   		; space
	ldx #0
@loop:	sta SCREEN,x
	sta SCREEN+$100,x
	inx
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

	;*****************************************************************
	; simple 8-bit random number generator
	; source: http://codebase64.org/doku.php?id=base:small_fast_8-bit_prng
	;*****************************************************************

rand8:	lda seed
	beq do_eor
	asl
	beq no_eor 	; if the input was $80, skip the EOR
	bcc no_eor
do_eor:	eor #$1d	; TODO: randomize eor value (see codebase64.org for suitable values)
no_eor:	sta seed
	rts

seed:	.byte 0		; TODO: initialize seed from raster pos or timer value!

	;*****************************************************************
	; data
	;*****************************************************************

text:	.byte	RED,"RED",BLUE,"BLUE",GREEN,"GREEN",0
