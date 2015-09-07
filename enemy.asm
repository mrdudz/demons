	;*****************************************************************
	; initialize enemies
	;*****************************************************************

init_enemies:
	; clear monsters
	ldx #MAX_ENEMIES*2
	lda #0
@clear:	sta ENEMY_X-1,x
	dex
	bne @clear

	lda DUNGEON_LEVEL
	lsr
	clc
	adc #4
	sta $0			; $0 = spawn count = level/2 + 4
@loop:	jsr randomloc
	jsr move
	; store x,y to enemy table
	ldx $0			; X = monster index (1-based)
	tya
	sta ENEMY_X-1,x
	lda CURSOR_Y
	sta ENEMY_Y-1,x
	tax
	;
	jsr rand8
	and #7
	clc
	adc DUNGEON_LEVEL
	tay
	dey			; Y = rand8 & 7 + level - 1
	lda spawns,y
	jsr CHROUT

@skip:	dec $0
	bne @loop
	rts

	;*****************************************************************
	; update enemies
	;*****************************************************************

update_enemies:
	lda #MAX_ENEMIES-1
	sta $0			; $0 = counter
@loop:	ldy $0
	ldx ENEMY_Y,y		; X = row
	beq @skip		; skip if enemy slot unused
	lda ENEMY_X,y
	tay			; Y = column
	; move enemy
	jsr move
	lda (COLOR_PTR),y
	and #7
	cmp #COLOR_UNSEEN
	beq @skip		; skip unseen enemies
	; store monster type
	lda (LINE_PTR),y
	sta CUR_NAME
	; try to move right
	iny
	lda (LINE_PTR),y
	dey
	cmp #SCR_FLOOR
	bne @skip
	; clear enemy from old pos
	lda #COLOR_EXPLORED
	sta CUR_COLOR
	lda #CHR_FLOOR
	jsr CHROUT
	; draw enemy at new pos
	iny
	lda #COLOR_YELLOW	; TODO: preserve old monster color!
	sta CUR_COLOR
	lda CUR_NAME
	ora #64			; screen code to char code
	jsr CHROUT
	; update monster coords
	tya
	ldx $0
	inc ENEMY_X,x
@skip:	dec $0
	bpl @loop
	rts

	;*****************************************************************
	; remove enemy at row X, column Y
	;*****************************************************************

remove_enemy:
	lda #COLOR_EXPLORED
	sta CUR_COLOR
	lda #CHR_FLOOR
	jsr plot
	jsr enemy_at
	lda #0
	sta ENEMY_X,x
	sta ENEMY_Y,x
	rts

	;*****************************************************************
	; returns enemy at row X, column Y, out: X = enemy index
	;*****************************************************************

enemy_at:
	stx $0
	sty $1
	ldx #MAX_ENEMIES-1
@loop:	lda ENEMY_Y,x
	cmp $0
	bne @next
	lda ENEMY_X,x
	cmp $1
	bne @next
	rts			; enemy found
@next:	dex
	bpl @loop
	; monster not found -> error
	.if 1
@err:	inc $900f
	jmp @err
	.endif

	;*****************************************************************
	; data
	;*****************************************************************

	; random spawns, indexed with rand8() & 7 + level - 1
spawns:	.byte CHR_BAT,CHR_RAT,CHR_RAT,CHR_RAT,CHR_BAT,CHR_BAT,CHR_SNAKE
	.byte CHR_RAT,CHR_SNAKE,CHR_SNAKE,CHR_BAT,CHR_RAT,CHR_UNDEAD,CHR_UNDEAD
	.byte CHR_ORC,CHR_ORC,CHR_UNDEAD,CHR_STALKER,CHR_UNDEAD,CHR_STALKER,CHR_SNAKE
	.byte CHR_ORC,CHR_SLIME,CHR_WIZARD,CHR_WIZARD
