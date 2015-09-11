	;*****************************************************************
	; initialize items
	;*****************************************************************

init_items:
	jsr rand8
	and #7
	sec
	sbc #4
	bmi @done
	beq @done
	sta $0			; $0 = count
@loop:	jsr randomloc
	jsr random_loot
@skip:	dec $0
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
	jmp CHROUT		; jsr CHROUT + rts

@items: .byte CHR_POTION,CHR_POTION,CHR_POTION,CHR_GOLD,CHR_GEM,CHR_SCROLL,CHR_SKULL,CHR_GOLD

	;*****************************************************************
	; use potion
	;*****************************************************************

use_potion:
	lda #0
	jsr use_item
	bcs @done
	lda #14
	sta $900f
	jsr delay
	jsr delay
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
	jsr delay
	jsr delay
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
	jsr delay
	jsr delay
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
@done:	rts

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
