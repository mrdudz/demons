	;*****************************************************************
	; initialize items
	;*****************************************************************

init_items:
	jsr rand8
	and #7
	sec
	sbc #5
	bmi @done
	beq @done
	sta $0			; $0 = count
@loop:	jsr randomloc
	jsr random_loot
	dec $0
	bne @loop
@done:	rts

	;*****************************************************************
	; random loot drop at X,Y
	;*****************************************************************

random_loot:
	jsr move
	jsr rand8		; pick random item
	and #7
	tay
	lda @items,y
	ldy cursor_x
	jmp plot2		; jsr + rts

@items: .byte SCR_POTION,SCR_POTION,SCR_GOLD,SCR_GOLD,SCR_GEM,SCR_SCROLL,SCR_ANKH,SCR_GOLD

	;*****************************************************************
	; use potion
	;*****************************************************************

use_potion:
	lda #0
	jsr use_item
	bcs @done
	lda #14
	sta $900f
	; play sound
	jsr pause_music
	lda #1
	sta delay_length
	ldx #128
@sfx:	stx vic_bass
	jsr delay
	inx
	inx
	inx
	inx
	bne @sfx
	jsr resume_music
	;
	lda #8
	sta $900f
	ldx #<usepot
	ldy #>usepot
	jsr print_msg
	lda max_hp
	sta hp
	jsr update_hp
@done:	rts

	;*****************************************************************
	; use gem
	;*****************************************************************

use_gem:
	lda #1
	jsr use_item
	bcs @done
	lda #93
	sta $900f
	; play sound
	jsr pause_music
	lda #1
	sta delay_length
	ldx #50
@sfx:	jsr rand8
	ora #$80
	sta vic_soprano
	jsr delay
	dex
	bne @sfx
	jsr resume_music
	;
	ldx #<usegem
	ldy #>usegem
	jsr print_msg
	ldx #1
	jsr @gemreveal
	ldx #11
	jsr @gemreveal
	lda #8
	sta $900f
@done:	rts

@gemreveal: ; reveal 256 bytes
	ldy #0
	jsr move
@loop:	lda (color_ptr),y
	and #7
	cmp #COLOR_UNSEEN
	bne @skip
	lda (line_ptr),y
	tax
	lda colors,x
	sta (color_ptr),y
@skip:	iny
	bne @loop
	rts

	;*****************************************************************
	; use scroll
	;*****************************************************************

use_scroll:
	lda #2
	jsr use_item
	bcs @done
	lda #14
	sta $900f
	; play sound
	jsr pause_music
	lda #1
	sta delay_length
	ldx #192
@sfx:	stx vic_soprano
	jsr delay
	inx
	inx
	inx
	inx
	bne @sfx
	jsr resume_music
	;
	lda #8
	sta $900f
	ldx #<usescr
	ldy #>usescr
	jsr print_msg
	lda #INVISIBLE_TIME
	sta invisibility
	lda #COLOR_BLUE
	sta plcolor
	ldy px
	ldx py
	jsr move
	sta (color_ptr),y
@done:	rts

	;*****************************************************************
	; use skull
	;*****************************************************************

use_skull:
	lda #3
	jsr use_item
	bcs @done
	ldx #<useskul
	ldy #>useskul
	jsr print_msg
	; shake effect
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
	; kill visible monsters
	ldx #1
	jsr @killall
	ldx #11
	jsr @killall
	jsr resume_music
@done:	rts

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
	cmp #COLOR_UNSEEN
	beq @skip		; skip unseen cells
	; kill
	sty cursor_x
	txa
	pha
	jsr damage_flash
	ldx #<mondies
	ldy #>mondies
	jsr print_msg
	pla
	tax
	ldy cursor_x
	lda #SCR_FLOOR
	sta (line_ptr),y
	lda #COLOR_EXPLORED
	sta (color_ptr),y
	jsr delay
	jsr delay
@skip:	dex
	bne @kloop
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
	ldx #<useitem
	ldy #>useitem
	jsr print_msg2
	clc
	rts
@outof:	ldx #<outof
	ldy #>outof
@done:	jsr print_msg2
	sec
	rts
