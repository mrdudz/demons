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

@items: .byte CHR_POTION,CHR_POTION,CHR_POTION,CHR_POTION,CHR_GEM,CHR_SCROLL,CHR_SKULL,CHR_GOLD