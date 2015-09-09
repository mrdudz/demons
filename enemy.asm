	;*****************************************************************
	; initialize enemies
	;*****************************************************************

init_enemies:
	lda DUNGEON_LEVEL
	lsr
	clc
	adc #4
	sta $0			; $0 = spawn count = level/2 + 4
@loop:	jsr randomloc
	jsr move
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
	ldx #2			; X = row
@yloop:	ldy #1			; Y = column
@xloop: jsr move
	lda (LINE_PTR),y
	cmp #SCR_BAT
	bmi @skip		; skip non-enemy cells
	sta CUR_NAME		; store monster
	stx MON_Y
	sty MON_X
	lda (COLOR_PTR),y
	and #7
	sta MON_COLOR
	cmp #COLOR_UNSEEN	; skip unseen cells
	beq @skip
	lda BLOCKED_CELLS,y
	beq @skipb		; skip monsters in 'blocked' cells
	; monster is in a blocked cell (downward movement) -> unblock cell and skip update
	lda #0
	sta BLOCKED_CELLS,y
	beq @skip		; always branches
@skipb:	jsr move_towards
@skip:	iny
	cpy #21
	bne @xloop
	inx			; next row
	cpx #21
	bne @yloop
	rts

	;*****************************************************************
	; moves enemy towards player, in: X,Y = current position
	;*****************************************************************

move_towards:
	; move up
	cpx PY			
	bmi @skip1
	beq @skip1
	ldx #0			
	jsr move_enemy
	bcc @done		; done if moved
@skip1: ; move right
	cpy PX			
	bpl @skip2
	beq @skip2
	ldx #1			
	jsr move_enemy
	bcs @skip2
	; moving right is tricky: skip next cell to prevent monster getting updated twice
	iny
	rts
@skip2:	; move down
	cpx PY			
	bpl @skip3
	beq @skip3
	ldx #2			
	jsr move_enemy
	bcs @skip3		; done if moved
	; moving down is tricky: we have to mark the cell to prevent monster getting updated again in same turn
	lda #$ff
	sta BLOCKED_CELLS,y
	rts
@skip3:	; move left
	cpy PX			
	bmi @done
	beq @done
	ldx #3			
	jsr move_enemy
@done:	rts

	;*****************************************************************
	; moves enemy at cursor towards a direction, in:
	; X = direction (0=up, 1=right, 2=down, 3=left)
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
	; draw monster to new cell
	lda MON_COLOR
	sta CUR_COLOR
	lda CUR_NAME
	ora #64			; scr code -> char code
	jsr CHROUT
	; clear monster from old cell
	ldx MON_Y
	ldy MON_X
	jsr move
	lda #SCR_FLOOR
	sta (LINE_PTR),y
	lda #COLOR_EXPLORED
	sta (COLOR_PTR),y
	clc			; success => clear carry
	rts

@block: ldy MON_X		; move cursor back
	ldx MON_Y
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
	jmp @end
@hit:	; hit
	ldx #<monhit
	ldy #>monhit
	jsr print_msg
	ldx PY
	ldy PX
	jsr move
	jsr damage_flash
	jsr player_damage
@end:	ldx MON_Y		; restore X,Y
	ldy MON_X
	clc			; success => clear carry
	rts

	;*****************************************************************
	; data
	;*****************************************************************

	; random spawns, indexed with rand8() & 7 + level - 1
spawns:	.byte CHR_BAT,CHR_RAT,CHR_RAT,CHR_RAT,CHR_BAT,CHR_BAT,CHR_SNAKE
	.byte CHR_RAT,CHR_SNAKE,CHR_SNAKE,CHR_BAT,CHR_RAT,CHR_UNDEAD,CHR_UNDEAD
	.byte CHR_ORC,CHR_ORC,CHR_UNDEAD,CHR_STALKER,CHR_UNDEAD,CHR_STALKER,CHR_SNAKE
	.byte CHR_ORC,CHR_SLIME,CHR_WIZARD,CHR_WIZARD
