	;*****************************************************************
	; random loot drop at cursor
	;*****************************************************************

random_loot:
	jsr rand8		; pick random item
	and #7
	tay
	lda rnditem,y
	ldy cursor_x
	jmp plot2		; jsr + rts

tremor:	txa
	pha
	tya
	pha
	jsr pause_music
	lda vic_scr_center	
	sta $0			; $0 = old screen center value
	ldx #0
@loop:	jsr rand8
	sta vic_noise
	and #7
	adc $0
	sbc #3
	sta vic_scr_center
	ldy #0
@loop2:	nop
	nop
	nop
	dey			; delay
	bne @loop2
	dex
	bne @loop
	lda $0
	sta vic_scr_center	; restore old screen center
	jsr delay
	pla
	tay
	pla
	tax
	rts

	;*****************************************************************
	; use item
	;*****************************************************************

use_item:
	tax
	clc
	adc #SCR_POTION
	sta cur_name
	lda mul3,x
	tax
	lda potions,x
	cmp #'0'+$80
	beq @outof
	dec potions,x
	ldy #useitem-textbase
	jmp print_msg2			; clc + jsr + rts
	;rts
@outof:	ldy #outof-textbase
@done:	jsr print_msg2
	sec
	rts
