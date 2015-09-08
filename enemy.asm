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
	jsr move
	lda (LINE_PTR),y	; store monster name for printing
	sta CUR_NAME
	lda (COLOR_PTR),y
	and #7
	cmp #COLOR_UNSEEN
	beq @skip		; skip unseen enemies
	stx TMP_MY		; store current pos of monster
	sty TMP_MX
	jsr move_towards
@skip:	dec $0
	bpl @loop
	rts

	;*****************************************************************
	; moves enemy towards player, in: X,Y = current position
	;*****************************************************************

move_towards:
	cpx PY
	bmi @skip1
	beq @skip1
	ldx #0			; move up
	jsr move_enemy
	bcc @done		; done if moved
@skip1: cpy PX
	bpl @skip2
	beq @skip2
	ldx #1			; move right
	jsr move_enemy
	bcc @done		; done if moved
@skip2:	cpx PY
	bpl @skip3
	beq @skip3
	ldx #2			; move down
	jsr move_enemy
	bcc @done		; done if moved
@skip3:	cpy PX
	bmi @done
	beq @done
	ldx #3			; move left
	jsr move_enemy
@done:	rts

	;*****************************************************************
	; moves enemy at cursor towards a direction, in:
	; cursor at enemy
	; $0 = enemy
	;  X = direction (0=up, 1=right, 2=down, 3=left)
	;*****************************************************************

move_enemy:
	; check obstacles
	lda @dirs,x		; move cursor to target cell
	jsr CHROUT
	ldy CURSOR_X
	lda (LINE_PTR),y
	cmp #SCR_PLAYER
	beq enemy_attack
	cmp #SCR_FLOOR
	bne @block		; blocked
	lda (COLOR_PTR),y
	and #7
	cmp #COLOR_UNSEEN
	beq @block		; can't move to unseen cells
	; update enemy coords
	tya
	ldy $0
	sta ENEMY_X,y
	lda CURSOR_Y
	sta ENEMY_Y,y
	; move cursor back
	txa
	ldy TMP_MX
	ldx TMP_MY
	jsr move
	tax
	; save old char and color
	lda (LINE_PTR),y	
	pha			; save char
	lda (COLOR_PTR),y
	pha			; save color
	; clear monster
	lda #SCR_FLOOR
	sta (LINE_PTR),y
	lda #COLOR_EXPLORED
	sta (COLOR_PTR),y
	; draw monster
	lda @dirs,x		; move cursor to target cell
	jsr CHROUT
	pla			; restore color
	sta CUR_COLOR
	pla			; restore char
	ora #64
	jsr CHROUT
@done:	clc			; success => clear carry
	rts

@block: ldy TMP_MX		; move cursor back
	ldx TMP_MY
	jsr move
	sec			; blocked => set carry
	rts

@dirs:	.byte CHR_UP,CHR_RIGHT,CHR_DOWN,CHR_LEFT

	;*****************************************************************
	; enemy attacks player
	;*****************************************************************

enemy_attack:
	jsr rand8
	cmp #ENEMY_ACCURACY
	bcc @hit
	; miss
	ldx #<monmiss
	ldy #>monmiss
	jsr print_msg
	jsr delay
	bne @end		; same as 'jmp @end' but saves 1 byte
@hit:	; hit
	ldx #<monhit
	ldy #>monhit
	jsr print_msg
	ldx PY
	ldy PX
	jsr move
	jsr damage_flash
	jsr player_damage
@end:	clc			; success => clear carry
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
