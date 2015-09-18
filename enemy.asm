	;*****************************************************************
	; update enemy, in: X,Y = current position
	;*****************************************************************

update_enemy:
	lda cur_name
	cmp #SCR_SLIME
	beq @slime_update
	; move up
@update:cpx py			
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

@slime_update:			; slimes move randomly
	jsr rand8
	and #7
	cmp #6
	bpl @update
	cmp #4
	bpl @done
	tax
	;
	;

	;*****************************************************************
	; moves enemy at cursor towards a direction, in:
	; X = direction (0=up, 1=right, 2=down, 3=left)
	;*****************************************************************

move_enemy:
	; check obstacles
	lda @dirs,x		; move cursor to target cell
	jsr CHROUT
	ldx cursor_y
	ldy cursor_x
	jsr move
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
	sta (color_ptr),y
	lda cur_name
	sta (line_ptr),y
	cmp #SCR_SLIME
	beq @skip
	; clear monster from old cell
	ldx mon_y
	ldy mon_x
	jsr move
	lda #SCR_FLOOR
	sta (line_ptr),y
	lda flcolor
	sta (color_ptr),y
@skip:	clc			; success => clear carry
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
	ldy #monmiss-textbase
	jsr print_msg
	ldx py
	ldy px
	jsr move
	jsr miss_flash
	beq @end		; always branches (assumes that miss_flash sets Z=1)
@hit:	; hit
	ldy #monhit-textbase
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
