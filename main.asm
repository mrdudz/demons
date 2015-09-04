	;*****************************************************************
	; Demons of Dex
	; A roguelike for the unexpanded VIC-20
	; (C) 2015 Petri Hakkinen. All rights reserved.
	;*****************************************************************

	; constants
	SCREEN 		= $1e00
	SCREEN_WIDTH	= 22
	SCREEN_HEIGHT	= 23
	ENEMY_COUNT	= 3
	
	; kernal routines
	CHROUT		= $ffd2
	PLOT		= $fff0
	GETIN		= $ffe4
	LINE_PTR	= $D1		; pointer to current line is stored in $d1-$d2
	CUR_COLOR	= $0286

	; char codes
	CHR_WHITE	= 5
	CHR_RED		= 28
	CHR_GREEN	= 30
	CHR_BLUE	= 31
	CHR_BLACK	= 144
	CHR_PURPLE	= 156
	CHR_YELLOW	= 158
	CHR_CYAN	= 159
	CHR_DOWN	= 17
	CHR_UP		= 145
	CHR_LEFT 	= 157
	CHR_RIGHT	= 29
	CHR_HOME	= 19
	CHR_CLR_HOME	= 147
	CHR_FLOOR	= 166
	CHR_PLAYER	= 64
	CHR_ENEMY	= 113

	; screen codes
	SCR_FLOOR	= 102

	; zero page variables
	PX		= $10
	PY		= $11

	; VIC registers
	VIC_SCR_COLORS	= $900F

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

start:	;lda #8
	;sta VIC_SCR_COLORS
	;lda #1
	;sta CUR_COLOR

	jsr random_level
	jsr init_player
	jsr init_enemies

	; draw message bar
	ldx #0
	ldy #0
	jsr move
        ldx #<text
        ldy #>text
        jsr print

mainloop:
	jsr waitkey
	jsr update_player

	jmp mainloop

	;*****************************************************************
	; random level generator
	;*****************************************************************

random_level:
	jsr clearscreen

	; init walker
	; X,Y = x,y
	; $4,$5 = dx,dy
	; $6 = counter
	ldx #10		; x = 10
	ldy #11		; y = 11
	lda #1
	sta $4		; dx = 1
	lda #0
	sta $5		; dy = 0
	; size of level can be adjusted by changing counter's initial value
	sta $6		; counter = 0
	
	; random initial turn
	jsr rand8
	cmp #128
	bcc @turn

	; plot
@loop:	lda #CHR_FLOOR
	jsr plot

	;jsr delay

	; move walker
	txa
	clc
	adc $4		; x = x + dx
	tax
	tya
	clc
	adc $5		; y = y + dy
	tay
	inc $6		; counter++
	beq @done	; done when counter ovewflows

	; turn at edge
	cpx #2
	beq @turn
	cpy #1
	beq @turn
	cpx #20
	beq @turn
	cpy #20
	beq @turn

	; check random turn
	jsr rand8
	cmp #77
	bcs @loop

	; turn (dx,dy = dy,-dx)
@turn:	lda $5
	pha		; dy to stack
	lda #0
	sec
	sbc $4
	sta $5		; dy' = -dx
	pla
	sta $4		; dx' = dy

	jmp @loop

@done:	rts

	;*****************************************************************
	; initialize player
	;*****************************************************************

init_player:
	ldx #10
	ldy #11
	stx PY
	sty PX
	lda #CHR_PLAYER
	jsr plot
	rts

	;*****************************************************************
	; update player
	;*****************************************************************

update_player:
	; handle movement
	ldy PX
	ldx PY
	; store old pos
	stx $0
	sty $1
	cmp #CHR_UP
	bne @skip1
	dex
@skip1:	cmp #CHR_DOWN
	bne @skip2
	inx
@skip2: cmp #CHR_LEFT
	bne @skip3
	dey
@skip3: cmp #CHR_RIGHT
	bne @skip4
	iny
@skip4:	; X,Y = move target
	jsr move
	; check obstacle
	lda (LINE_PTR),y
	cmp #SCR_FLOOR
	bne @blocked

	; move player to X,Y
	sty PX			; store new pos
	stx PY
	lda #CHR_PLAYER
	jsr plot		; draw player at new pos
	ldx $0			; restore old pos
	ldy $1
	lda #CHR_FLOOR
	jsr plot		; erase old player

@blocked:
	rts

	;*****************************************************************
	; initialize enemies
	;*****************************************************************

init_enemies:
	lda #ENEMY_COUNT
	sta $0
@loop:	jsr randomloc
	lda #CHR_ENEMY
	jsr plot
	dec $0
	bne @loop
	rts

	;*****************************************************************
	; moves cursor to row X, column Y
	;*****************************************************************

move:	pha		; store A,X,Y
	txa
	pha
	tya
	pha
	clc
	jsr PLOT	; trashes A,X,Y
	pla		; restore A,X,Y
	tay
	pla
	tax
	pla
	rts

	;*****************************************************************
	; plots a character in A at row X, column Y
	;*****************************************************************

plot:	jsr move
	jsr CHROUT
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

;clearscreen:
;	; screen is 22*23 = 506 bytes long
;	; to save bytes we clear two full pages (512 bytes)
;	lda #32   		; space
;	ldx #0
;@loop:	sta SCREEN,x
;	sta SCREEN+$100,x
;	inx
;	bne @loop
;	rts

clearscreen:
	lda #CHR_CLR_HOME
        jsr CHROUT
        rts

	;*****************************************************************
	; short delay in busy loop
	;*****************************************************************

delay:	;txa
	;pha
	;tya
	;pha
	ldy #$80
@delay1:ldx #$ff
@delay2:dex
	bne @delay2
	dey
	bne @delay1
	;pla
	;tay
	;pla
	;tax
	rts

	;*****************************************************************
	; simple 8-bit random number generator by White Flame (aka David Holz)
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
	; picks a random unoccupied location, returns: X=row, Y=column
	;*****************************************************************

randomloc:
	; pick random row
	jsr rand8
	and #31
	tax
	inx
	inx
	cmp #20
	bpl randomloc
	; pick random column
@rndcol:jsr rand8
	and #31
	tay
	iny
	cmp #20
	bpl @rndcol
	; check that it is free
	jsr move
	lda (LINE_PTR),y
	cmp #SCR_FLOOR
	bne randomloc
	rts

	;*****************************************************************
	; waits for a key press
	;*****************************************************************

waitkey:jsr GETIN
	cmp #0
	beq waitkey
	rts

	;*****************************************************************
	; data
	;*****************************************************************

text:	.byte	CHR_BLUE,"DESCENDING...",0
