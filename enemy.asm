	;*****************************************************************
	; initialize enemies
	;*****************************************************************

init_enemies:
	lda dungeon_level
	lsr
	clc
	adc #4
	sta $0			; $0 = spawn count = level/2 + 4
@loop:	jsr randomloc
	jsr move
	jsr rand8
	and #7
	clc
	adc dungeon_level
	tay
	dey			; Y = rand8 & 7 + level - 1
	lda spawns,y
	jsr CHROUT
@skip:	dec $0
	bne @loop
	; place special level creatures
	lda dungeon_level
	cmp #FINAL_LEVEL
	bne @done
	jsr randomloc
	jsr move
	lda #CHR_DEMON
	jsr CHROUT
@done:	rts

	;*****************************************************************
	; update enemies
	;*****************************************************************

update_enemies:
	lda plcolor
	cmp #COLOR_BLUE
	beq @done		; player is invisible
	ldx #2			; X = row
@yloop:	ldy #1			; Y = column
@xloop: jsr move
	lda (line_ptr),y
	cmp #SCR_BAT
	bmi @skip		; skip non-enemy cells
	sta cur_name		; store monster
	stx mon_y
	sty mon_x
	lda (color_ptr),y
	and #7
	sta mon_color
	cmp #COLOR_UNSEEN	; skip unseen cells
	beq @skip
	lda blocked_cells,y
	beq @skipb		; skip monsters in 'blocked' cells
	; monster is in a blocked cell (downward movement) -> unblock cell and skip update
	lda #0
	sta blocked_cells,y
	beq @skip		; always branches
@skipb:	jsr move_towards
@skip:	iny
	cpy #21
	bne @xloop
	inx			; next row
	cpx #21
	bne @yloop
@done:	rts

	;*****************************************************************
	; moves enemy towards player, in: X,Y = current position
	;*****************************************************************

move_towards:
	; move up
	cpx py			
	bmi @skip1
	beq @skip1
	ldx #0			
	jsr move_enemy
	bcc @done		; done if moved
@skip1: ; move right
	cpy px			
	bpl @skip2
	beq @skip2
	ldx #1			
	jsr move_enemy
	bcs @skip2
	; moving right is tricky: skip next cell to prevent monster getting updated twice
	iny
	rts
@skip2:	; move down
	cpx py			
	bpl @skip3
	beq @skip3
	ldx #2			
	jsr move_enemy
	bcs @skip3		; done if moved
	; moving down is tricky: we have to mark the cell to prevent monster getting updated again in same turn
	lda #$ff
	sta blocked_cells,y
	rts
@skip3:	; move left
	cpy px			
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
	ldy cursor_x
	lda (line_ptr),y
	cmp #SCR_PLAYER
	beq enemy_attack
	cmp #SCR_FLOOR
	bne @block		; blocked
	lda (color_ptr),y
	and #7
	cmp #COLOR_UNSEEN
	beq @block		; can't move to unseen cells
	; draw monster to new cell
	lda mon_color
	sta cur_color
	lda cur_name
	ora #64			; scr code -> char code
	jsr CHROUT
	; clear monster from old cell
	ldx mon_y
	ldy mon_x
	jsr move
	lda #SCR_FLOOR
	sta (line_ptr),y
	lda #COLOR_EXPLORED
	sta (color_ptr),y
	clc			; success => clear carry
	rts

@block: ldy mon_x		; move cursor back
	ldx mon_y
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
	ldx py
	ldy px
	jsr move
	jsr miss_flash
	jmp @end
@hit:	; hit
	ldx #<monhit
	ldy #>monhit
	jsr print_msg
	ldx py
	ldy px
	jsr move
	jsr damage_flash
	jsr player_damage
@end:	ldx mon_y		; restore X,Y
	ldy mon_x
	clc			; success => clear carry
	rts

	;*****************************************************************
	; data
	;*****************************************************************

	; random spawns, indexed with rand8() & 7 + level - 1
spawns:	.byte CHR_BAT,CHR_RAT,CHR_RAT,CHR_RAT,CHR_BAT,CHR_WORM,CHR_SNAKE
	.byte CHR_RAT,CHR_SNAKE,CHR_SNAKE,CHR_BAT,CHR_RAT,CHR_UNDEAD,CHR_UNDEAD
	.byte CHR_ORC,CHR_ORC,CHR_UNDEAD,CHR_STALKER,CHR_UNDEAD,CHR_STALKER,CHR_SNAKE
	.byte CHR_ORC,CHR_SLIME,CHR_WIZARD,CHR_WIZARD
