	;*****************************************************************
	; random loot drop at X,Y
	;*****************************************************************

random_loot:
	jsr move
	jsr rand8		; pick random item
	and #7
	tay
	lda rnditem,y
	ldy cursor_x
	jmp plot2		; jsr + rts

	;*****************************************************************
	; use potion
	;*****************************************************************

use_potion:
	lda #0
	jsr use_item
	bcs rts1
	lda #14
	sta $900f
	; play sound
	jsr pause_music
	ldx #128
@sfx:	stx vic_bass
	lda #1
	jsr delay2
	inx
	inx
	inx
	inx
	bne @sfx
	jsr resume_music
	;
	lda #8
	sta $900f
	lda max_hp
	sta hp
	jsr update_hp
	ldy #usepot-textbase
	jmp print_msg		; jsr + rts

	;*****************************************************************
	; use gem
	;*****************************************************************

use_gem:
	lda #1
	jsr use_item
	bcs rts1
	lda #93
	sta $900f
	; play sound
	jsr pause_music
	ldx #50
@sfx:	jsr rand8
	ora #$80
	sta vic_soprano
	lda #1
	jsr delay2
	dex
	bne @sfx
	;
	jsr resume_music	
	ldx #1
	jsr @gemreveal
	ldx #11
	jsr @gemreveal
	lda #8
	sta $900f
	ldy #usegem-textbase
	jmp print_msg		; jsr + rts

@gemreveal: ; reveal 256 bytes
	ldy #0
	jsr move
@loop:	lda (color_ptr),y
	and #7
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
	bne @skip
	lda (line_ptr),y
	tax
	lda colors,x
	sta (color_ptr),y
@skip:	iny
	bne @loop
rts1:	rts

	;*****************************************************************
	; use scroll
	;*****************************************************************

use_scroll:
	lda #2
	jsr use_item
	bcs rts1
	lda #14
	sta $900f
	; play sound
	jsr pause_music
	ldx #192
@sfx:	stx vic_soprano
	lda #1
	jsr delay2
	inx
	inx
	inx
	inx
	bne @sfx
	jsr resume_music
	;
	lda #8
	sta $900f
	lda #INVISIBLE_TIME
	sta invisibility
	lda #COLOR_BLUE
	sta plcolor
	ldy px
	ldx py
	jsr move
	sta (color_ptr),y
	ldy #usescr-textbase
	jmp print_msg		; jsr + rts

	;*****************************************************************
	; use skull
	;*****************************************************************

use_skull:
	lda #3
	jsr use_item
	bcs rts1
	ldy #useskul-textbase
	jsr print_msg
	jsr tremor
	; kill visible monsters
	ldx #1
	jsr @killall
	ldx #11
	jsr @killall
	jmp resume_music	; jsr + rts

@killall: ; reveal 256 bytes
	ldy #0
	jsr move
	ldx #0
@kloop:	jsr rand8
	tay
	lda (line_ptr),y
	sta cur_name
	cmp #SCR_BAT
	bmi @skip		; skip non-monster cells
	cmp #SCR_DEMON
	bpl @skip		; demons are immune to skulls
	lda (color_ptr),y
	and #7
	.if COLOR_UNSEEN
	cmp #COLOR_UNSEEN
	.endif
	beq @skip		; skip unseen cells
	; kill
	sty cursor_x
	txa
	pha
	jsr damage_flash
	ldy #mondies-textbase
	jsr print_msg
	pla
	tax
	ldy cursor_x
	lda #SCR_FLOOR
	sta (line_ptr),y
	lda flcolor
	sta (color_ptr),y
	lda #50
	jsr delay2
@skip:	dex
	bne @kloop
	rts

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
